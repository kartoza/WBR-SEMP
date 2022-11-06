--as a proxy for current activity on each property in the buffer and transition zones (core zone properties are by definition protected), I use the most recent national land cover land use database and assign the class that takes up more than any other class on a farm, to that farm ('majority' statistic). To do this I ran zonal statistics in QGIS with the farmportions over the NLC raster. I loaded the temporary output into the DB as "Zonal statistics" and ran the queries below to attach the descriptive class of the majority cover to the farm portion rather than the raster value, as well as the variety statistic in case we want to use that.  

delete from nlc_2018_lut where class_name is null;

select * from nlc_2018_lut limit 1
 
select fp.*, lut.class_name, zs.lc_variety, zs.lc_majority from "Zonal Statistics" zs join farmportions fp on fp.id = zs.id
join nlc_2018_lut lut  on zs.lc_majority = lut.id;

alter table farmportions add column lc character varying(100);
alter table farmportions add column lc_variety int4;

  update farmportions fp
set lc = lut.class_name, lc_variety = zs.lc_variety
from "Zonal Statistics" zs , nlc_2018_lut lut  where fp.id = zs.id and zs.lc_majority = lut.id;