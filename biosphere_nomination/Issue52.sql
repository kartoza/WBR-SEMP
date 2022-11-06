--overlay WBR zones with vegetation so we can report on vegetation types and areas per zone
--trying in PostGIS since geometry error make intersection fail in QGIS

drop table overlay_veg;

create table overlay_veg as
select st_transform(veg.geom,32735) geom, name_18 name, null as zone from nvm2018_aea_v22_7_16082019_final veg join wbr_limit wbr on st_intersects(st_transform(wbr.geom,4326),veg.geom)
UNION
select geom, null as name, zone from wbr_boundary_nov22;

CREATE INDEX sidx_overlay_veg_geom
    ON overlay_veg USING gist(geom);

        --this uses the exteriorrings approach for multipolygons, try it too with DumpRings?

drop table boundaries_veg;
CREATE TABLE boundaries_veg AS
with foo as
(SELECT (ST_Dump(geom)).geom As geom
			FROM overlay_veg),
collectfoo as
(SELECT ST_Collect(ST_ExteriorRing(geom)) AS erings
	FROM foo)
select ST_union(st_snaptogrid(erings,0.01)) geom from collectfoo;
	
drop sequence polyvegseq;
drop table polys_veg;
CREATE SEQUENCE polyvegseq;
CREATE TABLE polys_veg AS
  SELECT nextval('polyvegseq') AS id, 
         (ST_Dump(ST_Polygonize(geom))).geom AS geom
  FROM boundaries_veg;
  
CREATE INDEX sidx_polys_veg_geom
    ON polys_veg USING gist(geom);


ALTER TABLE polys_veg ADD COLUMN veg character varying;
ALTER TABLE polys_veg ADD COLUMN zone character varying;

UPDATE polys_veg polys set veg = ov.name
FROM overlay_veg ov
 where ST_Contains(ov.geom, ST_PointOnSurface(polys.geom)) and ov.name is not null
  ;
  
UPDATE polys_veg polys set zone = ov.zone
FROM overlay_veg ov
 where ST_Contains(ov.geom, ST_PointOnSurface(polys.geom)) and ov.zone is not null
  ;
  
delete from polys_veg where zone is null or veg is null;

select zone,veg,sum(st_area(geom)/10000)::int area_ha from polys_veg
group by zone,veg
order by zone,area_ha DESC;