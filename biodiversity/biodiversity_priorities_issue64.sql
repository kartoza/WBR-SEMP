--biodiversity priorities https://github.com/kartoza/WBR-SEMP/issues/64

--AOI
select st_astext(st_envelope(geom)) from aoi_wbr;
select st_astext(st_envelope(st_transform(geom,32735))) from aoi_wbr;

POLYGON((440045.789357581 7198576.94400535,440045.789357581 7516700.78214497,743041.376842405 7516700.78214497,743041.376842405 7198576.94400535,440045.789357581 7198576.94400535))
((MINX, MINY), (MINX, MAXY), (MAXX, MAXY), (MAXX, MINY), (MINX, MINY))

alter table aoi_wbr alter column geom type geometry(MultiPolygon,32735) using ST_transform(geom,32735);
CREATE INDEX sidx_aoi_wbr_geom
    ON aoi_wbr USING gist(geom);
	
CREATE TABLE aoi_wbr_singlepoly AS 
    SELECT id, (ST_DUMP(geom)).geom::geometry(Polygon,32735) AS geom FROM aoi_wbr;
CREATE INDEX sidx_aoi_wbr_singlepoly_geom
    ON aoi_wbr_singlepoly USING gist(geom);

--clip lc_status to aoi (lc_status_block was exported from GRASS)
update lc_status_block set geom = st_makevalid(geom) where not st_isvalid(geom);

create table lc_status as
select lc.fid,lc.cat,st_multi(st_intersection(lc.geom,aoi.geom))::geometry(MultiPolygon,32735) geom
from lc_status_block lc,aoi_wbr aoi;

CREATE INDEX sidx_lc_status_geom
    ON lc_status USING gist(geom);

--CBAs
select distinct final_cat,cba from limpopo_cba_esa;
  --fix geometry errors
update limpopo_cba_esa set geom = st_makevalid(geom) where not st_isvalid(geom);

--run this again after resizing partitions!
drop table cba;
create table cba as
  --reclassify the CBA/ESA layer to get scores and clip to AOI
select lcba.id, st_intersection(lcba.geom,aoi.geom) geom, case when cba in ('PA','CBA1') then 10 
	when cba in ('CBA2') then 5 
	when cba in ('ESA1','ESA2') then 2 end as score
from limpopo_cba_esa lcba, aoi_wbr aoi
where cba in ('PA','CBA1','CBA2','ESA1','ESA2');

CREATE INDEX sidx_cba_geom
    ON cba USING gist(geom);

--remove degraded and transformed areas
create table cba_untransformed as
select cba.id,cba.score,st_difference(st_snaptogrid(cba.geom,0.01),st_snaptogrid(lc.geom,0.01)) geom 
from cba,lc_status lc
where lc.cat in (2,3);

CREATE INDEX sidx_cba_untransformed_geom
    ON cba_untransformed USING gist(geom);

--protected area expansion priorities
  --we should be using the Limpopo PAES (from LBIMS) but in the meantime use the national one

drop table paes;
create table paes as
  --reclassify the PAES layer to get scores and clip to AOI
select paes.id,st_intersection(st_transform(paes.geom,32735),aoi.geom) geom, 10 as score 
from npaes_focus_areas_completetable paes,aoi_wbr aoi;

CREATE INDEX sidx_paes_geom
    ON paes USING gist(geom);

--aquatic prioritisation
  --aquatic feature
    --rivers (lines). I buffer them slightly to force polygons so we can do vector overlays
select distinct fepatxt,fepacode from "rivers-nfepa";
    --wetlands (polys)
select distinct wetfepa from nfepa_wetlands;

drop table aquaticfeature;
create table aquaticfeature as
with unioned as
(select st_intersection(st_buffer(st_transform(te.geom,32735),5),aoi.geom) geom, case fepatxt 
    when 'FishCorrid' then 3 
	when 'Upstream' then 2 
	when 'FEPA' then 3 
	when 'FishFSA' then 8 
	when 'Phase2FEPA' then 4 end as score
from "rivers-nfepa" te, aoi_wbr aoi
where fepatxt in ('FishCorrid','Upstream','FEPA','FishFSA','Phase2FEPA')
UNION 
select st_intersection(st_transform(te.geom,32735),aoi.geom) geom, case wetfepa 
    when 0 then 1 
	when 1 then 10 
	end as score
from nfepa_wetlands te, aoi_wbr aoi)
select row_number() over () id,* from unioned;

CREATE INDEX sidx_aquaticfeature_geom
    ON aquaticfeature USING gist(geom);

  --immediate buffer
drop table aquaticbuffer;
create table aquaticbuffer as
select st_union(st_intersection(st_buffer(af.geom,1000),aoi.geom))) geom, 5 as score
from aquaticfeature af, aoi_wbr aoi;

CREATE INDEX sidx_aquaticbuffer_geom
    ON aquaticbuffer USING gist(geom);

  --catchments and wetland clusters
  
 select distinct fepatxt from rivers_nfepa;
 select distinct fepa from nfepa_wetland_cluster;
 
drop table aquaticcluster;
create table aquaticcluster as
with priorities as
(select st_intersection(st_transform(te.geom,32735),aoi.geom) geom, case fepatxt 
    when 'FishCorrid' then 3 
	when 'Upstream' then 2 
	when 'FEPA' then 3 
	when 'FishFSA' then 8 
	when 'Phase2FEPA' then 4 end as score
from rivers_nfepa te, aoi_wbr aoi
where fepatxt in ('FishCorrid','Upstream','FEPA','FishFSA','Phase2FEPA')
UNION
select st_intersection(st_transform(te.geom,32735),aoi.geom) geom, case fepa 
    when 0 then 1 
	when 1 then 10 
	end as score
from nfepa_wetland_cluster te, aoi_wbr aoi)
select row_number() over (), geom, score from priorities;

CREATE INDEX sidx_aquaticcluster_geom
    ON aquaticcluster USING gist(geom);

  --strategic water source areas
    --fix geometries first (they are crappy anyway - a few raster squares in the Waterberg????)
update strategic_water_source_areas set geom = st_makevalid(geom) where not st_isvalid(geom);

drop table swsa;
create table swsa as
select row_number() over () id ,st_intersection(st_transform(swsa.geom,32735),aoi.geom) geom, 10 as score 
from strategic_water_source_areas swsa,aoi_wbr aoi
where st_isvalid(swsa.geom);
  
CREATE INDEX sidx_swsa_geom
    ON swsa USING gist(geom);

   --composite1: maximum with transformed
drop table overlay_aquatic;

create table overlay_aquatic as
select geom, score from swsa
UNION
select geom, score from aquaticfeature
UNION
select geom, score from aquaticbuffer
UNION
select geom, score from aquaticcluster;

CREATE INDEX sidx_overlay_aquatic_geom
    ON overlay_aquatic USING gist(geom);

        --this uses the exteriorrings approach for multipolygons, try it too with DumpRings?

drop table boundaries_aquatic;
CREATE TABLE boundaries_aquatic AS
with foo as
(SELECT (ST_Dump(geom)).geom As geom
			FROM overlay_aquatic),
collectfoo as
(SELECT ST_Collect(ST_ExteriorRing(geom)) AS erings
	FROM foo)
select ST_union(st_snaptogrid(erings,0.01)) geom from collectfoo;
	
drop sequence polyseq;
drop table polys_aquatic;
CREATE SEQUENCE polyseq;
CREATE TABLE polys_aquatic AS
  SELECT nextval('polyseq') AS id, 
         (ST_Dump(ST_Polygonize(geom))).geom AS geom
  FROM boundaries_aquatic;
  
CREATE INDEX sidx_polys_aquatic_geom
    ON polys_aquatic USING gist(geom);

ALTER TABLE polys_aquatic ADD COLUMN max INTEGER DEFAULT 0;
UPDATE polys_aquatic polys set max = p.max
FROM (
  SELECT max(score) AS max, p.id AS id  
  FROM polys_aquatic p 
  JOIN overlay_aquatic c 
  ON ST_Contains(c.geom, ST_PointOnSurface(p.geom)) 
  GROUP BY p.id
) AS p
WHERE p.id = polys.id;

   --composite2: aggregated without transformed
   
drop table overlay_aquatic_untransformed;

***create table overlay_aquatic_untransformed as
with overlay as
(select geom, score from swsa
UNION
select geom, score from aquaticfeature
UNION
select geom, score from aquaticbuffer
UNION
select geom, score from aquaticcluster)
--clip with lc_status
select overlay.score,st_difference(overlay.geom,lc.geom) geom 
from overlay,lc_status lc
where lc.cat in (2,3);

CREATE INDEX sidx_overlay_aquatic_untransformed_geom
    ON overlay_aquatic_untransformed USING gist(geom);

      --this uses the exteriorrings approach for multipolygons, try it too with DumpRings?

drop table boundaries_aquatic_untransformed;
***CREATE TABLE boundaries_aquatic_untransformed AS
with foo as
(SELECT (ST_Dump(geom)).geom As geom
			FROM overlay_aquatic_untransformed),
collectfoo as
(SELECT ST_Collect(ST_ExteriorRing(geom)) AS erings
	FROM foo)
select ST_union(st_snaptogrid(erings,0.01)) geom from collectfoo;
	
drop sequence polyseq2;
drop table polys_aquatic2;
CREATE SEQUENCE polyseq2;
***CREATE TABLE polys_aquatic2 AS
  SELECT nextval('polyseq2') AS id, 
         (ST_Dump(ST_Polygonize(geom))).geom AS geom
  FROM boundaries_aquatic_untransformed;
  
CREATE INDEX sidx_polys_aquatic2_geom
    ON polys_aquatic2 USING gist(geom);

ALTER TABLE polys_aquatic2 ADD COLUMN aggregate INTEGER DEFAULT 0;
***UPDATE polys_aquatic2 polys set aggregate = p.sum
FROM (
  SELECT sum(score) as sum, p.id AS id  
  FROM polys_aquatic2 p 
  JOIN overlay_aquatic_untransformed c 
  ON ST_Contains(c.geom, ST_PointOnSurface(p.geom)) 
  GROUP BY p.id
) AS p
WHERE p.id = polys.id;
   
   --final combination to get aquatic biodiversity priority
 
drop table overlay_aquatic_combination;

***create table overlay_aquatic_combination as
select geom, max as score from polys_aquatic
UNION
select geom, aggregate as score from polys_aquatic2;
***clip with lc_status
select overlay.id,overlay.score,st_difference(overlay.geom,lc.geom) geom 
from overlay,lc_status lc
where lc.cat in (2,3);

***CREATE INDEX sidx_overlay_aquatic_combination_geom
    ON overlay_aquatic_combination USING gist(geom);

      --this uses the exteriorrings approach for multipolygons, try it too with DumpRings?

drop table boundaries_aquatic_combination;
***CREATE TABLE boundaries_aquatic_combination AS
with foo as
(SELECT (ST_Dump(geom)).geom As geom
			FROM overlay_aquatic_combination),
collectfoo as
(SELECT ST_Collect(ST_ExteriorRing(geom)) AS erings
	FROM foo)
select ST_union(st_snaptogrid(erings,0.01)) geom from collectfoo;
	
drop sequence polyseq2;
drop table polys_aquatic2;
CREATE SEQUENCE polyseq2;
***CREATE TABLE polys_aquatic2 AS
  SELECT nextval('polyseq2') AS id, 
         (ST_Dump(ST_Polygonize(geom))).geom AS geom
  FROM boundaries_aquatic_combination;
  
CREATE INDEX sidx_polys_aquatic2_geom
    ON polys_aquatic2 USING gist(geom);

ALTER TABLE polys_aquatic3 ADD COLUMN score INTEGER DEFAULT 0;
***UPDATE polys_aquatic3 polys set score = p.sum
FROM (
  SELECT sum(score) as sum, p.id AS id  
  FROM polys_aquatic3 p 
  JOIN overlay_aquatic_combination c 
  ON ST_Contains(c.geom, ST_PointOnSurface(p.geom)) 
  GROUP BY p.id
) AS p
WHERE p.id = polys.id;

--threatened habitats
select distinct RLEv5 from terrestrial_threatstatus_protectionlevel_nba2018;

drop table threatstatus;
create table threatstatus as
select te.id, st_intersection(st_transform(te.geom,32735),aoi.geom) geom, case rlev5 
    when 'CR' then 10 
	when 'EN' then 8 
	when 'VU' then 4 end as score
from terrestrial_threatstatus_protectionlevel_nba2018 te, aoi_wbr aoi
where rlev5 in ('CR','EN','VU');

CREATE INDEX sidx_threatstatus_geom
    ON threatstatus USING gist(geom);

--ecosystem protection levels
select distinct PL_2018 from terrestrial_threatstatus_protectionlevel_nba2018;

drop table protectionlevel;
create table protectionlevel as
select te.id, st_intersection(st_transform(te.geom,32735),aoi.geom) geom, case pl_2018 
    when 'NP' then 10 
	when 'PP' then 6 
	when 'MP' then 3 end as score
from terrestrial_threatstatus_protectionlevel_nba2018 te, aoi_wbr aoi
where pl_2018 in ('NP','PP','MP');

CREATE INDEX sidx_protectionlevel_geom
    ON protectionlevel USING gist(geom);

--combine into integrated_biodiversity_value
drop table overlay_total;

create table overlay_total as
select geom, score from threatstatus
UNION
select geom, score from protectionlevel
UNION
select geom, score from paes
UNION
select geom, score from cba
UNION
select geom, max+aggregate as score from polys_aquatic;

CREATE INDEX sidx_overlay_total_geom
    ON overlay_total USING gist(geom);

                 --this uses the exteriorrings approach for multipolygons, try it too with DumpRings?

drop table boundaries_total;
CREATE TABLE boundaries_total AS
with foo as
(SELECT (ST_Dump(geom)).geom As geom
			FROM overlay_total),
collectfoo as
(SELECT ST_Collect(ST_ExteriorRing(geom)) AS erings
	FROM foo)
select ST_union(st_snaptogrid(erings,0.01)) geom from collectfoo;
	
drop SEQUENCE polytotseq;
drop TABLE polys_total;
CREATE SEQUENCE polytotseq;
CREATE TABLE polys_total AS
  SELECT nextval('polytotseq') AS id, 
         (ST_Dump(ST_Polygonize(geom))).geom AS geom
  FROM boundaries_total;
  
 CREATE INDEX sidx_polys_total_geom
    ON polys_total USING gist(geom);

ALTER TABLE polys_total ADD COLUMN score INTEGER DEFAULT 0;
UPDATE polys_total polys set score = p.sum * 2
FROM (
  SELECT sum(c.score) as sum, p.id AS id  
  FROM polys_total p 
  JOIN overlay_total c 
  ON ST_Contains(c.geom, ST_PointOnSurface(p.geom)) 
  GROUP BY p.id
) AS p
WHERE p.id = polys.id;

  --remove degraded and transformed areas
select overlay.id,overlay.score,st_difference(overlay.geom,lc.geom) geom 
from overlay,lc_status lc
where lc.cat in (2,3);

