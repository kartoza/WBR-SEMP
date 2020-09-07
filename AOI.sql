--defining the WBR SEMP AOI
--refresh materialized view kartoza.wbr_aoi;
--drop materialized view kartoza.wbr_aoi;
create materialized view kartoza.wbr_aoi as 
with 
--IBAs in the waterberg district
iba as (select iba.geom from sanbi.iba_2015 iba join mdb.district_municipalities dm on ST_intersects(iba.geom,st_transform(dm.geom,4326)) where municname = 'Waterberg'),
--IBAs + WBR
protected as (select st_union(iba.geom,br.geom) geom from iba, sanbi.protected_area_sa br where br.name = 'Waterberg Biosphere Reserve'),
--pre-clip some catchments
catchclip as (select st_difference(st_transform(dm.geom,4326),st_transform(st_force2d(catch.geom),4326)) geom from dwa.tertiary_catchment catch, mdb.district_municipalities dm where dm.municname = 'Waterberg' and catch.name ='A32'),
--add clipped catchment back to the rest
catchmerge as (select st_union(st_transform(st_force2d(catch.geom),4326),catchclip.geom) geom from catchclip,dwa.tertiary_catchment catch where catch.name IN ('A41','A42','A50','A61','A24','A63','A62')),
--catchments minus any area covered by Vhembe BR
catchments as (select st_difference(catchmerge.geom,br.geom) geom from catchmerge, sanbi.protected_area_sa br where br.name = 'Vhembe Biosphere Reserve'),
--merge catchments and protected areas
pc as (select st_union(protected.geom,catchments.geom) geom from protected,catchments),
--merge all with waterberg district
collection as (select st_multi(st_union(pc.geom,st_transform(dm.geom,4326)))::geometry(MultiPolygon,4326) geom from pc,mdb.district_municipalities dm where dm.municname = 'Waterberg')
--dissolve into one AOI polygon
select 1 id, st_union(geom) geom from collection;





