create table farmportions as
select fp.id_0 as id, fp.id as sg_code, tag_value, value, st_transform(fp.geom,32735) as geom,comments from farm_portion fp join aoi_wbr aoi on st_intersects(st_transform(fp.geom,32735),aoi.geom);

--added spatial index

select * from farm_portion limit 1

alter table farmportions alter column  geom type geometry(Multipolygon,32735);

--then did zonal stats in QGIS on farms against composite

--prepare protected area layer
update protected_areas set geom = st_makevalid(geom) where not st_isvalid(geom);
alter table sapad_or_2020_q1 alter column  geom type geometry(MultiPolygon,4326) using st_multi(geom);
update sapad_or_2020_q1 set geom = st_makevalid(geom) where not st_isvalid(geom);

drop table protected;
create table protected as
with collection as
(select geom from paes
union
select st_transform(geom,32735) geom from protected_areas
union
select st_transform(geom,32735) geom from sapad_or_2020_q1)
select row_number() over () id, ST_multi((ST_Dump(st_union(st_snaptogrid(c.geom,0.001)))).geom)::geometry(Multipolygon,32735) geom from collection c join aoi_wbr a on st_intersects(c.geom,a.geom)

ALTER TABLE public.protected
    ADD PRIMARY KEY (id);
	
CREATE INDEX idx_protected_gist_geom
    ON public.protected USING gist
    (geom)	


--assign farms to zones
alter table farmportions add column zone character varying(20);
update farmportions set zone=null;
update farmportions set zone = 'buffer' where _mean > 100;
update farmportions fp set zone = 'core' 
 from protected p
 where zone = 'buffer' and st_intersects(fp.geom,p.geom);
 --and st_within(st_centroid(fp.geom),p.geom);

--now that some farms are core, that intersect protected polys, reverse select all the other farms that intesect those protected polys that might not have been buffer and make them core too
with p as
(select p.geom from protected p join farmportions fp on st_intersects (p.geom,fp.geom) where fp.zone = 'core')
update farmportions fp set zone = 'core' from p where st_intersects(p.geom,fp.geom)
   
