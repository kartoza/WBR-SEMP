set search_path to wbr_survey,public;

--attempt at replacing village geometry with voronoi polygons  ABANDONED
update survey_villages sv 
set geom = st_multi(st_intersection(st_buffer(st_centroid(sv.geom)::geography,500)::geometry,vp.geom)) from voronoipolys vp where st_within(st_centroid(sv.geom),vp.geom);

--once-off generate small buffers around villages (they were too big before)

--create voronoi view
create view voronoi_villages as
with vp as
(select st_VoronoiPolygons(st_collect(st_centroid(geom))) as geom from survey_villages
)
select (st_dump(geom)).path[1] as id, (st_dump(geom)).geom as geom from vp;

--update polygons for those village that have points to encompass all the points in the village
with 
cv as 
(select sv.id,name,count(*), st_multi(st_intersection(st_buffer(st_concavehull(st_collect(st_force2d(wbr.geometry)),0.5)::geography,100)::geometry,vp.geom)) as geom 
 from sync_main.wbr wbr 
 join voronoi_villages vp 
 on st_within(wbr.geometry,vp.geom) 
 join survey_villages sv  
 on st_within(st_centroid(sv.geom),vp.geom) 
 group by sv.name,sv.id,vp.geom),
 matches as
 (select sv.id from survey_villages sv join cv using(id)
 )
--run first with this to set all polygons (without survey points) to small circles
--update survey_villages sv set geom = st_multi(st_buffer(st_centroid(sv.geom)::geography,500)::geometry) from cv where sv.id not in (select id from matches)
--then run this to set all villages with points to the cv polygons
update survey_villages sv set geom = cv.geom from cv where cv.id = sv.id;

 --once-off add count column for reporting
 
 alter table survey_villages add column count int;

--update counts based on how how many points in each village polygon
update survey_villages sv set count = 0;
with counts as (
select sv.id,count(*) from sync_main.wbr wbr  join survey_villages sv  on st_within(wbr.geometry,sv.geom) group by sv.id)
update survey_villages sv set count = counts.count from counts where sv.id = counts.id