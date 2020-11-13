select * from mv_access_to_services_electricity limit 1;
select * from mv_access_to_services_piped_water limit 1;
select * from mv_access_to_services_refuse_disposal limit 1;
select * from mv_access_to_services_sanitation limit 1;

drop view raw_ratios;
create view raw_ratios as
with e as 
	(select distinct on (sp_code) sp_code::int,CASE WHEN (gas+paraffin+candles+solar+nothing+unspecified+not_applicable) <> 0 
	 	THEN electricity::double precision / (gas+paraffin+candles+solar+nothing+unspecified+not_applicable) ELSE NULL END as elec_ratio from mv_access_to_services_electricity),
pw as 
	(select distinct on (sp_code) sp_code::int, CASE WHEN (pipwtr_4::int+pipwtr_5::int+pipwtr_6::int+pipwtr_7::int+pipwtr_8::int+pipwtr_9::int) <> 0 THEN (pipwtr_1::int+pipwtr_2::int+pipwtr_3::int)::double precision / (pipwtr_4::int+pipwtr_5::int+pipwtr_6::int+pipwtr_7::int+pipwtr_8::int+pipwtr_9::int) ELSE NULL END water_ratio from mv_access_to_services_piped_water),
rd as 
	(select distinct on (sp_code) sp_code::int, CASE WHEN (communal_refuse_dump+ own_refuse_dump+no_refuse_dump) <> 0 THEN (removed_local_auth_1_per_week+removed_local_auth_less_often)::double precision / (communal_refuse_dump+ own_refuse_dump+no_refuse_dump) ELSE NULL END refuse_ratio from mv_access_to_services_refuse_disposal),
s as 
	(select distinct on (sp_code) sp_code::int,CASE WHEN (pit_toilet_without_ventilation+bucket_toilet+nothing) <> 0 THEN (flush_toilet_connected_to_sewer+flush_with_septic_tank+chemical_toilet+pit_toilet_with_ventilation)::double precision / (pit_toilet_without_ventilation+bucket_toilet+nothing)  ELSE NULL END as sani_ratio from mv_access_to_services_sanitation)
	select dr.geom,dr.sp_code::int, e.elec_ratio, s.sani_ratio, pw.water_ratio, rd.refuse_ratio
from dependency_ratio dr
join e using (sp_code)
join pw using (sp_code)
join rd using (sp_code)
join s using (sp_code);

select * from raw_ratios limit 1;

drop view poverty_of_access;
create view poverty_of_access as
select geom,sp_code,
CASE WHEN elec_ratio is not null then 1 - (elec_ratio - min(elec_ratio) over ())/(max(elec_ratio) over () - min(elec_ratio) over ()) else 0 end as pov_elec_access,
CASE WHEN sani_ratio is not null then 1 - (sani_ratio - min(sani_ratio) over ())/(max(sani_ratio) over () - min(sani_ratio) over ()) else 0 end as pov_sani_access,
CASE WHEN water_ratio is not null then 1 - (water_ratio - min(water_ratio) over ())/(max(water_ratio) over () - min(water_ratio) over ()) else 0 end as pov_water_access,
CASE WHEN refuse_ratio is not null then 1 - (refuse_ratio - min(refuse_ratio) over ())/(max(refuse_ratio) over () - min(refuse_ratio) over ()) else 0 end as pov_refuse_access
from raw_ratios;

drop table access_to_services;
create table access_to_services as 
select st_multi(st_curvetoline(geom))::geometry(Multipolygon,32735) as geom, sp_code,pov_elec_access+pov_sani_access+pov_water_access+pov_refuse_access as access
from poverty_of_access;

ALTER TABLE public.access_to_services
    ADD PRIMARY KEY (sp_code);
	
CREATE INDEX idx_access_to_services_gist_geom
    ON public.access_to_services USING gist
    (geom);

select st_isvalidreason(geom) from access_to_services where not st_isvalid(geom);

select distinct st_geometrytype(geom) from access_to_services