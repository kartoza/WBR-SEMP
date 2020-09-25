--biodiversity priorities https://github.com/kartoza/WBR-SEMP/issues/64

--AOI
select st_astext(st_envelope(geom)) from aoi_wbr;
select st_astext(st_envelope(st_transform(geom,32735))) from aoi_wbr;

"POLYGON((440045.789357581 7198576.94400535,440045.789357581 7545983.990207,743332.913426422 7545983.990207,743332.913426422 7198576.94400535,440045.789357581 7198576.94400535))"
((MINX, MINY), (MINX, MAXY), (MAXX, MAXY), (MAXX, MINY), (MINX, MINY))

--CBAs
select distinct final_cat,cba from limpopo_cba_esa;
  --fix geometry errors
update limpopo_cba_esa set geom = st_makevalid(geom) where not st_isvalid(geom);


--run this again after resizing partitions!
drop materialized view cba;
create materialized view cba as
  --reclassify the CBA/ESA layer to get scores and clip to AOI
with aoiclass as
(select lcba.id, st_intersection(lcba.geom,st_transform(aoi.geom,32735)) geom, case when cba in ('PA','CBA1') then 10 
	when cba in ('CBA2') then 5 
	when cba in ('ESA1','ESA2') then 2 end as score
from limpopo_cba_esa lcba, aoi_wbr aoi
where cba in ('PA','CBA1','CBA2','ESA1','ESA2'))
--remove degraded and transformed areas
select aoiclass.id,aoiclass.score,st_difference(aoiclass.geom,lc.geom) geom 
from aoiclass,lc_status lc
where lc.cat in (2,3);

refresh materialized view cba;

--protected area expansion priorities
  --we should be using the Limpopo PAES (from LBIMS) but in the meantime use the national one

create materialized view paes as
  --reclassify the PAES layer to get scores and clip to AOI
select paes.id,st_intersection(st_transform(paes.geom,32735),st_transform(aoi.geom,32735)) geom, 10 as score 
from npaes_focus_areas_completetable paes,aoi_wbr aoi;

refresh materialized view paes;

--aquatic prioritisation
  --aquatic feature
    --rivers (lines). I buffer them slightly to force polygons so we can do vector overlays
select distinct fepatxt,fepacode from "rivers-nfepa";
    --wetlands (polys)
select distinct wetfepa from nfepa_wetlands;

drop materialized view aquaticfeature;
create materialized view aquaticfeature as
with unioned as
(select st_intersection(st_buffer(st_transform(te.geom,32735),5),st_transform(aoi.geom,32735)) geom, case fepatxt 
    when 'FishCorrid' then 3 
	when 'Upstream' then 2 
	when 'FEPA' then 3 
	when 'FishFSA' then 8 
	when 'Phase2FEPA' then 4 end as score
from "rivers-nfepa" te, aoi_wbr aoi
where fepatxt in ('FishCorrid','Upstream','FEPA','FishFSA','Phase2FEPA')
UNION 
select st_intersection(st_transform(te.geom,32735),st_transform(aoi.geom,32735)) geom, case wetfepa 
    when 0 then 1 
	when 1 then 10 
	end as score
from nfepa_wetlands te, aoi_wbr aoi)
select row_number() over () id,* from unioned;

refresh materialized view aquaticfeature;

  --immediate buffer
drop materialized view aquaticbuffer;
create materialized view aquaticbuffer as
select af.id,st_intersection(st_buffer(af.geom,1000),st_transform(aoi.geom,32735)) geom, 5 as score
from aquaticfeature af, aoi_wbr aoi;
--a problem with the this buffer step is that there are lots of overlaps with might accumulate scores excessively. Might need some logic to dissolve and keep highest score
refresh materialized view aquaticbuffer;

  --catchments and wetland clusters
  
 select distinct fepatxt from rivers_nfepa;
 select distinct fepa from nfepa_wetland_cluster;
 
drop materialized view aquaticcluster;
create materialized view aquaticcluster as
with priorities as
(select st_intersection(st_transform(te.geom,32735),st_transform(aoi.geom,32735)) geom, case fepatxt 
    when 'FishCorrid' then 3 
	when 'Upstream' then 2 
	when 'FEPA' then 3 
	when 'FishFSA' then 8 
	when 'Phase2FEPA' then 4 end as score
from rivers_nfepa te, aoi_wbr aoi
where fepatxt in ('FishCorrid','Upstream','FEPA','FishFSA','Phase2FEPA')
UNION
select st_intersection(st_transform(te.geom,32735),st_transform(aoi.geom,32735)) geom, case fepa 
    when 0 then 1 
	when 1 then 10 
	end as score
from nfepa_wetland_cluster te, aoi_wbr aoi)
select row_number() over (), geom, score from priorities;

refresh materialized view aquaticcluster;
  
  --strategic water source areas
    --fix geometries first (they are crappy anyway - a few raster squares in the Waterberg????)
update strategic_water_source_areas set geom = st_makevalid(geom) where not st_isvalid(geom);

drop materialized view swsa;
create materialized view swsa as
select row_number() over () id ,st_intersection(st_transform(swsa.geom,32735),st_transform(aoi.geom,32735)) geom, 10 as score 
from strategic_water_source_areas swsa,aoi_wbr aoi
where st_isvalid(swsa.geom);
 
refresh materialized view swsa; 

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

CREATE TABLE boundaries_aquatic AS
with foo as
(SELECT (ST_Dump(geom)).geom As geom
			FROM overlay_aquatic),
collectfoo as
(SELECT ST_Collect(ST_ExteriorRing(geom)) AS erings
	FROM foo)
select ST_union(st_snaptogrid(erings,0.01)) geom from collectfoo;
	
CREATE SEQUENCE polyseq;
CREATE TABLE polys_aquatic AS
  SELECT nextval('polyseq') AS id, 
         (ST_Dump(ST_Polygonize(st_union))).geom AS geom
  FROM boundaries_aquatic;
  
 CREATE INDEX sidx_polys_aquatic_geom
    ON polys_aquatic USING gist
    (geom);

ALTER TABLE polys_aquatic ADD COLUMN max INTEGER DEFAULT 0;
ALTER TABLE polys_aquatic ADD COLUMN aggregate INTEGER DEFAULT 0;
UPDATE polys_aquatic polys set max = p.max,aggregate = p.sum
FROM (
  SELECT max(score) AS max, sum(score) as sum, p.id AS id  
  FROM polys_aquatic p 
  JOIN overlay_aquatic c 
  ON ST_Contains(c.geom, ST_PointOnSurface(p.geom)) 
  GROUP BY p.id
) AS p
WHERE p.id = polys.id;


   --composite2: aggregated without transformed
   
   --final combination to get aquatic biodiversity priority

--threatened habitats
select distinct RLEv5 from terrestrial_threatstatus_protectionlevel_nba2018;

drop materialized view threatstatus;
create materialized view threatstatus as
select te.id, st_intersection(st_transform(te.geom,32735),st_transform(aoi.geom,32735)) geom, case rlev5 
    when 'CR' then 10 
	when 'EN' then 8 
	when 'VU' then 4 end as score
from terrestrial_threatstatus_protectionlevel_nba2018 te, aoi_wbr aoi
where rlev5 in ('CR','EN','VU');

refresh materialized view threatstatus;

--ecosystem protection levels
select distinct PL_2018 from terrestrial_threatstatus_protectionlevel_nba2018;

drop materialized view protectionlevel;
create materialized view protectionlevel as
select te.id, st_intersection(st_transform(te.geom,32735),st_transform(aoi.geom,32735)) geom, case pl_2018 
    when 'NP' then 10 
	when 'PP' then 6 
	when 'MP' then 3 end as score
from terrestrial_threatstatus_protectionlevel_nba2018 te, aoi_wbr aoi
where pl_2018 in ('NP','PP','MP');

refresh materialized view protectionlevel;

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

CREATE TABLE boundaries_total AS
with foo as
(SELECT (ST_Dump(geom)).geom As geom
			FROM overlay_total),
collectfoo as
(SELECT ST_Collect(ST_ExteriorRing(geom)) AS erings
	FROM foo)
select ST_union(st_snaptogrid(erings,0.01)) geom from collectfoo;
	
CREATE SEQUENCE polytotseq;
CREATE TABLE polys_total AS
  SELECT nextval('polytotseq') AS id, 
         (ST_Dump(ST_Polygonize(geom))).geom AS geom
  FROM boundaries_total;
  
 CREATE INDEX sidx_polys_total_geom
    ON polys_total USING gist
    (geom);

ALTER TABLE polys_total ADD COLUMN max INTEGER DEFAULT 0;
ALTER TABLE polys_total ADD COLUMN aggregate INTEGER DEFAULT 0;
UPDATE polys_total polys set max = p.max,aggregate = p.sum
FROM (
  SELECT max(score) AS max, sum(score) as sum, p.id AS id  
  FROM polys_total p 
  JOIN overlay_total c 
  ON ST_Contains(c.geom, ST_PointOnSurface(p.geom)) 
  GROUP BY p.id
) AS p
WHERE p.id = polys.id;

  --remove degraded and transformed areas

select aoiclass.id,aoiclass.score,st_intersection(aoiclass.geom,lc.geom) geom 
from aoiclass,lc_status_poly lc
where lc.cat = 1;
