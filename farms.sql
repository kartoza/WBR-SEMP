--project and filter farm_portions
select * from farm_portion limit 1

create table farmportions as
select fp.id_0 as id, fp.id as sg_code, tag_value, value, st_transform(fp.geom,32735) as geom,comments from farm_portion fp join aoi_wbr aoi on st_intersects(st_transform(fp.geom,32735),aoi.geom);

alter table farmportions alter column  geom type geometry(Multipolygon,32735);

--added spatial index
select * from "Farm_portions" limit 1;

drop table farmportions_new;
create table farmportions_new as
select fp.id, fea_layer, cityname,life_cycle, farmname, st_transform(fp.geom,32735)::geometry(Multipolygon,32735) as geom from "Farm_portions" fp join aoi_wbr aoi on st_intersects(st_transform(fp.geom,32735),aoi.geom);

ALTER TABLE public.farmportions_new
    ADD PRIMARY KEY (id);
	
CREATE INDEX idx_farmportions_new_gist_geom
    ON public.farmportions_new USING gist
    (geom);

--then did zonal stats in QGIS on farms against composite Holness raster

--prepare protected area layer, merging all into one
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
--row_number() doesn't work over SRF (Dump) so need another approach to get unique ids

ALTER TABLE public.protected
    ADD PRIMARY KEY (id);
	
CREATE INDEX idx_protected_gist_geom
    ON public.protected USING gist
    (geom)	

--prep waterberg BR zones
create table biosphere_reserves_waterberg as
select id, st_transform(geom,32735)::geometry(MultiPolygon,32735) geom, site_stype from biosphere_reserves where cur_nme like 'Waterberg%';

ALTER TABLE public.biosphere_reserves_waterberg
    ADD PRIMARY KEY (id);
	
CREATE INDEX idx_biosphere_reserves_waterberg_gist_geom
    ON public.biosphere_reserves_waterberg USING gist
    (geom);

--assign farms to zones
alter table farmportions add column zone character varying(20);

--you can start here to re-run all queries below
update farmportions set zone=null;
update farmportions set zone = 'buffer' where _mean > 100;
update farmportions fp set zone = 'core' 
 from protected p
 where zone = 'buffer' and --st_intersects(fp.geom,p.geom);
 st_within(st_centroid(fp.geom),p.geom);

--now that some farms are core, that intersect protected polys, reverse select all the other farms that intesect those protected polys that might not have been buffer and make them core too
with p as
(select p.geom from protected p join farmportions fp on st_intersects (p.geom,fp.geom) where fp.zone = 'core')
update farmportions fp set zone = 'core' from p where st_within(st_centroid(fp.geom),p.geom);

--add any missing farms in current core zone
select * from biosphere_reserves_waterberg where site_stype = 'BR - Core Area';
update farmportions fp set zone = 'core' 
 from biosphere_reserves_waterberg p
 where st_within(st_centroid(fp.geom),p.geom) and p.site_stype = 'BR - Core Area';
 
 --add any missing farms in current buffer zone
select * from biosphere_reserves_waterberg where site_stype = 'BR - Buffer Zone';

select * from farmportions fp join biosphere_reserves_waterberg p
 on st_within(st_centroid(fp.geom),p.geom) and p.site_stype = 'BR - Buffer Zone' and (fp.zone <> 'core' or fp.zone is null); 

update farmportions fp set zone = 'buffer' 
 from biosphere_reserves_waterberg p
 where st_within(st_centroid(fp.geom),p.geom) and p.site_stype = 'BR - Buffer Zone' and (fp.zone <> 'core' or fp.zone is null);

 --add any missing farms in current transition zone
select * from biosphere_reserves_waterberg where site_stype = 'BR - Transition Area';
update farmportions fp set zone = 'transition' 
 from biosphere_reserves_waterberg p
 where st_within(st_centroid(fp.geom),p.geom) and p.site_stype = 'BR - Transition Area' and (fp.zone not in ('core','buffer') or fp.zone is null);
 
--add farms to the buffer zone that are in my workshop core areas but not in protected areas already
update farmportions fp set zone = 'buffer' 
 from wbr_boundary_new p
 where st_within(st_centroid(fp.geom),p.geom) and p.zone = 'core' and (fp.zone <> 'core' or fp.zone is null);
 
--remove farms that are not in Limpopo (did manually)

--add farms to the buffer zone that are in my workshop buffer areas but not classified already as buffers through above queries. This after I made some mods to my workshop zonation to take into account some feedback
update farmportions fp set zone = 'buffer' 
 from wbr_boundary_new p
 where st_within(st_centroid(fp.geom),p.geom) and p.zone = 'buffer' and (fp.zone <> 'core' or fp.zone is null);
 
--add farms to the transition zone that are in my workshop transition areas but not classified already as buffers or cores through above queries. 
update farmportions fp set zone = 'transition' 
 from wbr_boundary_new p
 where st_within(st_centroid(fp.geom),p.geom) and p.zone = 'transition' and (fp.zone not in ('core','buffer') or fp.zone is null);

--move farms to the transition zone that are in my workshop 'transition override' areas yet classified already as buffers through above queries. 
update farmportions fp set zone = 'transition' 
 from wbr_boundary_new p
 where st_within(st_centroid(fp.geom),p.geom) and p.zone = 'transition override' and (fp.zone not in ('core') or fp.zone is null);
 
--reclassify as core any protected areas that have come under buffer or transition areas grown above
with p as
(select p.geom from protected p join farmportions fp on st_intersects(p.geom,fp.geom) where fp.zone is not null)
update farmportions fp set zone = 'core' from p where st_within(st_centroid(fp.geom),p.geom);

 
--finally, reset all farm zones outside the limit to NULL 
update farmportions fp set zone=null from wbr_limit lim where not st_intersects(fp.geom,lim.geom);
