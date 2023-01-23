--project and filter farm_portions
select * from farm_portion limit 1

create table farmportions as
select fp.id_0 as id, fp.id as sg_code, tag_value, value, st_transform(fp.geom,32735) as geom,comments from farm_portion fp join aoi_wbr aoi on st_intersects(st_transform(fp.geom,32735),aoi.geom);

alter table farmportions alter column  geom type geometry(Multipolygon,32735);

--added spatial index
select * from "Farm_portions" limit 1;

drop table farmportions_new;
create table farmportions_new as
select fp.id, erven_id, parcel_tpe,fea_layer, fea_label,allotmntno, standno, portionno, suburbname, cityname,life_cycle, farmname, st_transform(fp.geom,32735)::geometry(Multipolygon,32735) as geom from "Farm_portions" fp join aoi_wbr aoi on st_intersects(st_transform(fp.geom,32735),aoi.geom);

ALTER TABLE public.farmportions_new
    ADD PRIMARY KEY (id);

CREATE SEQUENCE public.farmportions_new_id_seq
    INCREMENT 1
    START 1;

select setval('farmportions_new_id_seq',(select max(id)+1 from farmportions_new));

ALTER TABLE public.farmportions_new
    ALTER COLUMN id SET DEFAULT nextval('farmportions_new_id_seq');
	
ALTER SEQUENCE farmportions_new_id_seq
OWNED BY farmportions_new.id;

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
(select geom from "Waterberg_ProtectedAreas_2015_u35s"
 union
select geom from paes
union
select st_transform(geom,32735) geom from protected_areas
union
select st_transform(geom,32735) geom from sapad_or_2020_q1)
select row_number() over () id, ST_multi((ST_Dump(st_union(st_snaptogrid(c.geom,0.001)))).geom)::geometry(Multipolygon,32735) geom from collection c join aoi_wbr a on st_intersects(c.geom,a.geom)
--row_number() doesn't work over SRF (Dump) so need another approach to get unique ids

alter table protected drop column id;
alter table protected add column id serial;

ALTER TABLE public.protected
    ADD PRIMARY KEY (id);
	
CREATE INDEX idx_protected_gist_geom
    ON public.protected USING gist
    (geom);	

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
alter table farmportions add column motivation text;

--you can start here to re-run all queries below

--reset all allocations
update farmportions set zone=null, motivation=null;

--allocate farms to buffer where they meet some criterion from the composite raster (see QGIS zonal stats step above)
update farmportions set zone = 'buffer', motivation='buffer: median ISP > 70' where __median > 70; --(also try mean, majority etc). _ for m6 stats. __ for m7 stats

--allocate farms to buffer that are within x distance of one of the major rivers, to ensure that where possible, rivers have unbroken buffer zones all along them
with r as
(select st_transform(r.geom,32735) geom from "rivers-nfepa" r join aoi_wbr aoi on st_intersects (r.geom,st_transform(aoi.geom,3857)) where r.river_name in ('Limpopo','Matlabas','Motlhabatsi','Sand','Crocodile','Nyl','Mogalakwena','Lephalala','Mokolo','Marico'))
update farmportions fp set zone = 'buffer', motivation=concat(motivation, '; buffer: along major river') from r where st_dwithin(fp.geom,r.geom,500);

--allocate farms to buffer that have additional motivation beyond the original SEMP process
--wild dog ranges
update farmportions fp set zone = 'buffer', motivation=concat(motivation, '; buffer: wild dog range' )
 from wild_dog_4520_range p
 where st_intersects(fp.geom,p.geom);

--switch farms from buffer to core if they are protected
update farmportions fp set zone = 'core', motivation=concat(motivation, '; core: protected' )
 from protected p
 where zone = 'buffer' and --st_intersects(fp.geom,p.geom);
 --st_within(st_centroid(fp.geom),p.geom); --I think this is the reason some small PAES areas were missed - no farm centroids fell within them
st_contains(fp.geom,st_pointonsurface(p.geom));

--now that some farms are core, that intersect protected polys, reverse select all the other farms that intesect those protected polys that might not have been buffer and make them core too (fairly long query)
with p as
(select p.geom from protected p join farmportions fp on st_intersects (p.geom,fp.geom) where fp.zone = 'core')
update farmportions fp set zone = 'core', motivation=concat(motivation, '; core: protected') from p where st_within(st_centroid(fp.geom),p.geom);

--allocate farms to core that fall in the current core zone
--select * from biosphere_reserves_waterberg where site_stype = 'BR - Core Area';
update farmportions fp set zone = 'core', motivation=concat(motivation, '; core: current core' )
 from biosphere_reserves_waterberg p
 where st_within(st_centroid(fp.geom),p.geom) and p.site_stype = 'BR - Core Area';
 
--allocate farms to buffer that fall within the current buffer zone and which have not been classified yet nor have which been newly classfied as core 
/*
select * from biosphere_reserves_waterberg where site_stype = 'BR - Buffer Zone';
select * from farmportions fp join biosphere_reserves_waterberg p
 on st_within(st_centroid(fp.geom),p.geom) and p.site_stype = 'BR - Buffer Zone' and (fp.zone <> 'core' or fp.zone is null); 
*/
update farmportions fp set zone = 'buffer', motivation=concat(motivation, '; buffer: current buffer') 
 from biosphere_reserves_waterberg p
 where st_within(st_centroid(fp.geom),p.geom) and p.site_stype = 'BR - Buffer Zone' and (fp.zone <> 'core' or fp.zone is null);

--allocate farms to transition that are in the current transition zone but which have not been newly classified as core or buffer
select * from biosphere_reserves_waterberg where site_stype = 'BR - Transition Area';
update farmportions fp set zone = 'transition', motivation=concat(motivation, '; transition: current transition')
 from biosphere_reserves_waterberg p
 where st_within(st_centroid(fp.geom),p.geom) and p.site_stype = 'BR - Transition Area' and (fp.zone not in ('core','buffer') or fp.zone is null);
 
--add farms to the buffer zone that are in my workshop core areas but not in protected areas already
update farmportions fp set zone = 'buffer', motivation=concat(motivation, '; buffer: should be core but not protected' )
 from wbr_boundary_new p
 where st_within(st_centroid(fp.geom),p.geom) and p.zone = 'core' and (fp.zone <> 'core' or fp.zone is null);
 
--remove farms that are not in Limpopo (did manually)

--add farms to the buffer zone that are in my workshop buffer areas but not classified already as buffers through above queries. This after I made some mods to my workshop zonation to take into account some feedback
update farmportions fp set zone = 'buffer', motivation=concat(motivation, '; buffer: stakeholder feedback' )
 from wbr_boundary_new p
 where st_within(st_centroid(fp.geom),p.geom) and p.zone = 'buffer' and (fp.zone <> 'core' or fp.zone is null);
 
--add farms to the transition zone that are in my workshop transition areas but not classified already as buffers or cores through above queries. 
update farmportions fp set zone = 'transition', motivation=concat(motivation, '; transition: stakeholder feedback' )
 from wbr_boundary_new p
 where st_within(st_centroid(fp.geom),p.geom) and p.zone = 'transition' and (fp.zone not in ('core','buffer') or fp.zone is null);

--move farms to the transition zone that are in my workshop 'transition override' areas yet classified already as buffers through above queries. 
update farmportions fp set zone = 'transition', motivation=concat(motivation, '; transition: stakeholder override') 
 from wbr_boundary_new p
 where st_within(st_centroid(fp.geom),p.geom) and p.zone = 'transition override' and (fp.zone not in ('core') or fp.zone is null);
 
--reclassify as core any protected areas that have come under buffer or transition areas grown above
with p as
(select p.geom from protected p join farmportions fp on st_intersects(p.geom,fp.geom) where fp.zone is not null)
update farmportions fp set zone = 'core', motivation=concat(motivation, '; core: falls in area extended by previous steps') from p where st_within(st_centroid(fp.geom),p.geom);

--ensure all core areas are surrounded by a buffer zone, i.e. add a a buffer to edge core areas. 
-- actually not required
 
--finally, reset all farm zones outside the limit to NULL 
update farmportions fp set zone=null,motivation='outside limit' from wbr_limit lim where not st_intersects(fp.geom,lim.geom);

--union zones
drop table wbr_boundary_nov22;
create table wbr_boundary_nov22 as
select row_number() over() as id, zone, st_union(geom)::geometry(Multipolygon,32735) geom from farmportions
where zone is not null
group by zone;

ALTER TABLE public.wbr_boundary_nov22
    ADD PRIMARY KEY (id);
	
CREATE INDEX idx_wbr_boundary_nov22_gist_geom
    ON public.wbr_boundary_nov22 USING gist
    (geom);
	

--report on protected areas selected as proposed buffer core zone
drop table core_protected_areas;
create table core_protected_areas as
with collection as
(select geom, initcap(name) as name, 'CBA' as source, mgmt_agent as owner from "Waterberg_ProtectedAreas_2015_u35s"
 union
select st_transform(geom,32735) geom, focus_area as name, 'NPAES' as source, 'planned' as owner from npaes_focus_areas_completetable
union
select st_transform(geom,32735) geom, cur_nme as name, 'SANBI "protected_areas"' as source, site_type as owner from protected_areas
union
select st_transform(geom,32735) geom, cur_nme as name, 'DEFF "sapad_or_2020_q1"' as source, site_type as owner from sapad_or_2020_q1
where cur_nme <> 'Fossil Hominid Sites of SA')
select row_number() over () id, c.geom, c.name, c.source, c.owner from collection c join wbr_boundary_nov22 a on st_within(st_pointonsurface(c.geom),a.geom)--removed distinct on (name)
where a.zone = 'core';

--find dups
/*select name,count(*) from core_protected_areas 
group by name
having count(*) >1
order by name, count
*/
--remove dups where owner is null
/*with dups as (select name,count(*) from core_protected_areas 
where name <> 'Limpopo Central Bushveld'
			  group by name
having count(*) >1 order by name),
deleted as (
delete from core_protected_areas where name in (select name from dups) and owner is null
returning name )
select name from deleted 
group by name having count(*) >1
order by name;
*/

--remove reserves with duplicate names (keeping the largest)
--https://wiki.postgresql.org/wiki/Deleting_duplicates
DELETE FROM core_protected_areas
WHERE id IN (
    SELECT
        id
    FROM (
        SELECT
            id,
            row_number() OVER w as rnum, name
        FROM core_protected_areas
		where name <> 'Limpopo Central Bushveld'
        WINDOW w AS (
            PARTITION BY name
            ORDER BY st_area(geom) DESC
        ) 

    ) t
WHERE t.rnum > 1)
;
--there are still overlapping reserves - name changes, consolidations etc. 

--select * from core_protected_areas where name like '%Limpopo%'

--select distinct name from core_protected_areas where source <> 'NPAES' order by name ; --add source to distinct and order by

ALTER TABLE public.core_protected_areas
    ADD PRIMARY KEY (id);
	
CREATE INDEX idx_core_protected_areas_gist_geom
    ON public.core_protected_areas USING gist
    (geom);

--repeat above but to get report on protected areas in the current (2001) core area

drop table core_protected_areas_2001;
create table core_protected_areas_2001 as
with collection as
(select geom, initcap(name) as name, 'CBA' as source, mgmt_agent as owner from "Waterberg_ProtectedAreas_2015_u35s"
 union
select st_transform(geom,32735) geom, focus_area as name, 'NPAES' as source, 'planned' as owner from npaes_focus_areas_completetable
union
select st_transform(geom,32735) geom, cur_nme as name, 'SANBI "protected_areas"' as source, site_type as owner from protected_areas
union
select st_transform(geom,32735) geom, cur_nme as name, 'DEFF "sapad_or_2020_q1"' as source, site_type as owner from sapad_or_2020_q1
where cur_nme <> 'Fossil Hominid Sites of SA')
select row_number() over () id, c.geom, c.name, c.source, c.owner from collection c join biosphere_reserves a on st_within(st_pointonsurface(c.geom),st_transform(a.geom,32735))
where a.site_stype = 'BR - Core Area' and a.cur_nme = 'Waterberg Biosphere Reserve';

--find dups

--remove reserves with duplicate names (keeping the largest)
--https://wiki.postgresql.org/wiki/Deleting_duplicates
DELETE FROM core_protected_areas_2001
WHERE id IN (
    SELECT
        id
    FROM (
        SELECT
            id,
            row_number() OVER w as rnum, name
        FROM core_protected_areas_2001
		where name <> 'Limpopo Central Bushveld'
        WINDOW w AS (
            PARTITION BY name
            ORDER BY st_area(geom) DESC
        ) 

    ) t
WHERE t.rnum > 1)
;

ALTER TABLE public.core_protected_areas_2001
    ADD PRIMARY KEY (id);
	
CREATE INDEX idx_core_protected_areas_2001_gist_geom
    ON public.core_protected_areas_2001 USING gist
    (geom);

