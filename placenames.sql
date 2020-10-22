--attempt to use geonames to prep place names for a 'towns' layer
--I gave up and manually created teh towns layer

drop table geonames_wbr;...
create table geonames_wbr as
select geonames.* from geonames join aoi_wbr on st_within(st_transform(aoi_wbr.geom,4326),geonames.geom);

select count(*) from geonames