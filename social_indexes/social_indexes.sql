-- Create a materialized view use of wood for cooking. This is a join between the table "energy-for-cooking", sub_place
-- and wbr aoi.


CREATE MATERIALIZED VIEW public.mv_use_of_wood_for_cooking
 AS
 WITH limpopo_subplace AS (
         SELECT a_1.*,
            b_1.geom
           FROM "energy-for-cooking" a_1
             JOIN sub_place b_1 ON a_1.sp_code = b_1.sp_code
          WHERE a_1.pr_name::text = 'Limpopo'::text
        )
 SELECT a.id,a.sal_code,a.sp_code,a.sp_name,a.mp_code,a.mp_name,a.mn_mdb_c,a.mn_code,
    a.mn_name,a.dc_mdb_c,a.dc_code,a.dc_name,a.pr_code,a.pr_name,a.electricity,
    a.gas,a.paraffin,a.wood,a.coal,a.animal_dung,a.solar,a.other,a.nothing,a.unspecified,a.not_applicable,
    st_transform(st_intersection(a.geom,b.geom),32735) AS geom
   FROM limpopo_subplace a
     JOIN aoi_wbr b ON st_intersects(b.geom, a.geom);

-- Create a layer with statistics for the wood_for_cooking index
CREATE MATERIALIZED VIEW public.mv_use_of_wood_for_cooking_index AS
 WITH sample AS (
         SELECT a.id,a.sal_code,a.sp_code,a.sp_name,a.mp_code,
            a.mp_name,a.mn_mdb_c,a.mn_code,a.mn_name,a.dc_mdb_c,a.dc_code,a.dc_name,a.pr_code,
            a.pr_name,a.electricity,a.gas,a.paraffin,a.wood,a.coal,a.animal_dung,
            a.solar,a.other,a.nothing,a.unspecified,a.not_applicable,
            a.wood::double precision / st_area(a.geom) * 1000000::double precision AS wood_density,
            a.geom
           FROM mv_use_of_wood_for_cooking as a
        )
 SELECT sample.id,
    sample.sp_code,
    sample.sp_name,
        CASE
            WHEN (10::double precision * (sample.wood_density / (( SELECT percentile_cont(0.9::double precision)
                WITHIN GROUP (ORDER BY sample_1.wood_density) AS percentile_cont
               FROM sample sample_1)))) > 10::double precision THEN 10::double precision
            ELSE 10::double precision * (sample.wood_density / (( SELECT percentile_cont(0.9::double precision)
                WITHIN GROUP (ORDER BY sample_1.wood_density) AS percentile_cont
               FROM sample sample_1)))
        END AS index,
    sample.geom
   FROM sample
WITH DATA;


-- Create a materialized view use of wood for heating. This is a join between the table "energy-for-heating", sub_place
-- and wbr aoi.

CREATE MATERIALIZED VIEW public.mv_use_of_wood_for_heating
 AS
 WITH limpopo_subplace AS (
         SELECT a_1.*,
            b_1.geom
           FROM "energy-for-heating" a_1
             JOIN sub_place b_1 ON a_1.sp_code = b_1.sp_code
          WHERE a_1.pr_name::text = 'Limpopo'::text
        )
 SELECT a.id, a.sal_code, a.sp_code, a.sp_name, a.mp_code, a.mp_name, a.mn_mdb_c, a.mn_code,
        a.mn_name, a.dc_mdb_c, a.dc_code, a.dc_name, a.pr_code, a.pr_name, a.electricity, a.gas,
		a.paraffin, a.wood, a.coal, a.animal_dung, a.solar, a.other, a.nothing, a.unspecified, a.not_applicable,
		st_transform(st_intersection(a.geom,b.geom),32735) AS geom
		FROM limpopo_subplace a
     	JOIN aoi_wbr b ON st_intersects(b.geom, a.geom);

-- Create a layer with statistics for the wood_for_heating index
CREATE MATERIALIZED VIEW public.mv_use_of_wood_for_heating_index AS
 WITH sample AS (
         SELECT a.id, a.sal_code, a.sp_code, a.sp_name, a.mp_code, a.mp_name, a.mn_mdb_c, a.mn_code, a.mn_name, a.dc_mdb_c, a.dc_code,
			a.dc_name, a.pr_code, a.pr_name, a.electricity, a.gas, a.paraffin,
			a.wood::double precision / st_area(a.geom) * 1000000::double precision AS wood_density, a.coal, a.animal_dung, a.solar, a.other,
			a.nothing, a.unspecified, a.not_applicable, a.geom
		FROM public.mv_use_of_wood_for_heating as a
        )
 SELECT sample.id,
    sample.sp_code,
    sample.sp_name,
        CASE
            WHEN (10::double precision * (sample.wood_density / (( SELECT percentile_cont(0.9::double precision)
                WITHIN GROUP (ORDER BY sample_1.wood_density) AS percentile_cont
               FROM sample sample_1)))) > 10::double precision THEN 10::double precision
            ELSE 10::double precision * (sample.wood_density / (( SELECT percentile_cont(0.9::double precision)
                WITHIN GROUP (ORDER BY sample_1.wood_density) AS percentile_cont
               FROM sample sample_1)))
        END AS index,
    sample.geom
   FROM sample
WITH DATA;


-- Create a materialized view supply of building materials. This is a join between the table "type-of-main-dwelling", sub_place
-- and wbr aoi.

CREATE MATERIALIZED VIEW public.mv_supply_of_building_materials
 AS
 WITH limpopo_subplace AS (
         SELECT a_1.*,
            b_1.geom
           FROM "type-of-main-dwelling" a_1
             JOIN sub_place b_1 ON a_1.sp_code = b_1.sp_code
          WHERE a_1.pr_name::text = 'Limpopo'::text
        )
 SELECT a.id, a.sal_code, a.sp_code, a.sp_name, a.mp_code, a.mp_name, a.mn_mdb_c,
        a.mn_code, a.mn_name, a.dc_mdb_c, a.dc_code, a.dc_name, a.pr_code, a.pr_name, a.brick_concrete,
        a.traditional_dwelling, a.flat_apartment, a.cluster_house, a.townhouse, a.semi_detached_house,
        a.house_flat_room_in_backyard, a.informal_dwelling, a.informal_dwelling_shack, a.room_flatlet, a.caravan_tent,
        a.other, a.unspecified, a.not_applicable,
		st_transform(st_intersection(a.geom,b.geom),32735) AS geom
		FROM limpopo_subplace a
     	JOIN aoi_wbr b ON st_intersects(b.geom, a.geom);

-- Create a layer with statistics for the supply of building materials index
CREATE MATERIALIZED VIEW public.mv_supply_of_building_materials_index AS
 WITH sample AS (
         SELECT a.id, a.sal_code, a.sp_code, a.sp_name, a.mp_code, a.mp_name, a.mn_mdb_c, a.mn_code, a.mn_name,
a.dc_mdb_c, a.dc_code, a.dc_name, a.pr_code, a.pr_name, a.brick_concrete,
a.traditional_dwelling::double precision / st_area(a.geom) * 1000000::double precision AS dwelling_density,
a.flat_apartment, a.cluster_house, a.townhouse, a.semi_detached_house, a.house_flat_room_in_backyard,
a.informal_dwelling, a.informal_dwelling_shack, a.room_flatlet, a.caravan_tent, a.other, a.unspecified,
a.not_applicable, a.geom
		FROM public.mv_supply_of_building_materials as a
        )
 SELECT sample.id,
    sample.sp_code,
    sample.sp_name,
        CASE
            WHEN (10::double precision * (sample.dwelling_density / (( SELECT percentile_cont(0.9::double precision)
                WITHIN GROUP (ORDER BY sample_1.dwelling_density) AS percentile_cont
               FROM sample sample_1)))) > 10::double precision THEN 10::double precision
            ELSE 10::double precision * (sample.dwelling_density / (( SELECT percentile_cont(0.9::double precision)
                WITHIN GROUP (ORDER BY sample_1.dwelling_density) AS percentile_cont
               FROM sample sample_1)))
        END AS index,
    sample.geom
   FROM sample
WITH DATA;

-- Create a materialized view supply of building materials. This is a join between the table "source-of-water", sub_place
-- and wbr aoi.

CREATE MATERIALIZED VIEW public.mv_direct_supply_of_water_from_the_environment
 AS
 WITH limpopo_subplace AS (
         SELECT a_1.*,
            b_1.geom
           FROM "source-of-water" a_1
             JOIN sub_place b_1 ON a_1.sp_code = b_1.sp_code
          WHERE a_1.pr_name::text = 'Limpopo'::text
        )
 SELECT  a.id, a.sal_code, a.sp_code, a.sp_name, a.mp_code, a.mp_name,
        a.mn_mdb_c, a.mn_code, a.mn_name, a.dc_mdb_c, a.dc_code, a.dc_name, a.pr_code,
        a.pr_name, a.regional_local_water_source, a.borehole, a.spring, a.rain_water,
        a.dam_pool_stagnant_water, a.river_stream, a.water_vendor, a.water_tanker, a.other, a.not_applicable,
		st_transform(st_intersection(a.geom,b.geom),32735) AS geom
		FROM limpopo_subplace a
     	JOIN aoi_wbr b ON st_intersects(b.geom, a.geom);

-- Create a layer with statistics for direct supply of water from the environment index
CREATE MATERIALIZED VIEW public.mv_direct_supply_of_water_from_the_environment_index AS
 WITH sample AS (
         SELECT a.id,  a.sp_code, a.sp_name,sum(a.borehole + a.spring + a.rain_water +a.dam_pool_stagnant_water
											+ a.river_stream + a.water_tanker ) / st_area(a.geom) * 1000000::double precision AS water_density ,
											 a.geom
		FROM public.mv_direct_supply_of_water_from_the_environment as a
	    group by (a.id,a.sp_code,a.sp_name, a.geom)
        )
 SELECT sample.id,
    sample.sp_code,
    sample.sp_name,
        CASE
            WHEN (10::double precision * (sample.water_density / (( SELECT percentile_cont(0.9::double precision)
                WITHIN GROUP (ORDER BY sample_1.water_density) AS percentile_cont
               FROM sample sample_1)))) > 10::double precision THEN 10::double precision
            ELSE 10::double precision * (sample.water_density / (( SELECT percentile_cont(0.9::double precision)
                WITHIN GROUP (ORDER BY sample_1.water_density) AS percentile_cont
               FROM sample sample_1)))
        END AS index,
    sample.geom
   FROM sample
WITH DATA;
