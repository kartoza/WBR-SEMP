drop table wild_dog_4520_track;
create table wild_dog_4520_track as
select 1 id,st_transform(st_makeline(array(select geom from wild_dog_4520 order by "Time Stamp"::timestamp)),32735)::geometry(Linestring,32735) geom;

--convex hull from points
drop table wild_dog_4520_range;
create table wild_dog_4520_range as
select 1 id, st_buffer(st_concavehull(st_transform(st_collect(geom),32735),0.3),1000)::geometry(Polygon,32735) geom from wild_dog_4520;

--convex hull from track
drop table wild_dog_4520_range;
create table wild_dog_4520_range as
select 1 id, st_buffer(st_concavehull(geom,0.3),1000)::geometry(Polygon,32735) geom from wild_dog_4520_track;

select st_length(geom)/1000 from wild_dog_4520_track;