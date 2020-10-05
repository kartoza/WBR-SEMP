import os
import subprocess
import sys
from optparse import OptionParser

import psycopg2
import psycopg2.extras


def main():
    parser = OptionParser()
    parser.add_option(
        "-r", "--directory", dest="directory", help="directory with shapefiles",
        metavar="DIRECTORY")
    parser.add_option(
        "-d", "--database", dest="database", help="Database to be used",
        metavar="DATABASE")
    parser.add_option(
        "-U", "--database-user", dest="database_user", help="Database user",
        metavar="DATABASE_USER")
    parser.add_option(
        "-P", "--database-password", dest="database_password",
        help="Database password", metavar="DATABASE_PASSWORD")
    parser.add_option(
        "-p", "--port", dest="database_port", help="Database port",
        metavar="PORT")
    parser.add_option(
        "-l", "--log", dest="log_file", help="Log file location",
        metavar="LOG")
    parser.add_option(
        "-s", "--database-host", dest="database_host", help="Database host",
        metavar="HOST"
    )

    parser.add_option(
        "-t", "--database-table", dest="database_table", help="Database table",
        metavar="TABLE_NAME"
    )
    parser.add_option(
        "-j", "--job", dest="job",
        help="job", metavar="JOB", type="int")

    (options, args) = parser.parse_args()

    root_directory = options.directory
    user = options.database_user
    pw = options.database_password
    port = options.database_port
    db = options.database
    host = options.database_host

    target = r'%s' % root_directory
    # Define our connection string

    try:
        connection = psycopg2.connect(host=host, database=db, user=user, password=pw, port=port)
    except psycopg2.OperationalError as e:
        print(e)
        sys.exit(1)

    cursor = connection.cursor()
    wood_for_cooking = ''' CREATE MATERIALIZED VIEW public.mv_use_of_wood_for_cooking AS
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
            JOIN aoi_wbr b ON st_intersects(b.geom, a.geom);'''
    cursor.execute(wood_for_cooking)
    connection.commit()
    wood_for_cooking_index = ''' 
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
        WITH DATA;'''
    cursor.execute(wood_for_cooking_index)
    connection.commit()

    use_of_wood_for_heating = ''' 
        CREATE MATERIALIZED VIEW public.mv_use_of_wood_for_heating AS
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
        JOIN aoi_wbr b ON st_intersects(b.geom, a.geom);'''
    cursor.execute(use_of_wood_for_heating)
    connection.commit()
    wood_for_heating_index = ''' CREATE MATERIALIZED VIEW public.mv_use_of_wood_for_heating_index AS
 WITH sample AS (
         SELECT a.id, a.sal_code, a.sp_code, a.sp_name, a.mp_code, a.mp_name, a.mn_mdb_c, a.mn_code,
          a.mn_name, a.dc_mdb_c, a.dc_code,
            a.dc_name, a.pr_code, a.pr_name, a.electricity, a.gas, a.paraffin,
            a.wood::double precision / st_area(a.geom) * 1000000::double precision AS wood_density,
             a.coal, a.animal_dung, a.solar, a.other,
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
WITH DATA;'''
    cursor.execute(wood_for_heating_index)
    connection.commit()
    supply_of_building_materials = ''' CREATE MATERIALIZED VIEW public.mv_supply_of_building_materials
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
        JOIN aoi_wbr b ON st_intersects(b.geom, a.geom); '''
    cursor.execute(supply_of_building_materials)
    connection.commit()

    supply_of_building_materials_index = ''' CREATE MATERIALIZED VIEW public.mv_supply_of_building_materials_index AS
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
WITH DATA;'''
    cursor.execute(supply_of_building_materials_index)
    connection.commit()
    direct_supply_of_water_from_the_environment = ''' 
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
        JOIN aoi_wbr b ON st_intersects(b.geom, a.geom);'''
    cursor.execute(direct_supply_of_water_from_the_environment)
    connection.commit()
    direct_supply_of_water_from_the_environment_index = ''' 
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
WITH DATA;'''
    cursor.execute(direct_supply_of_water_from_the_environment_index)
    connection.commit()

    connection.close()
    index_layers = ['mv_use_of_wood_for_cooking_index', 'mv_use_of_wood_for_heating_index',
                    'mv_supply_of_building_materials_index', 'mv_direct_supply_of_water_from_the_environment_index']
    for layer in index_layers:
        raster_layer = layer + '.tif'
        raster_output = os.path.join(target, raster_layer)
        rasterize = ''' gdal_rasterize -l public.%s -a index -tr 15.0 15.0 -a_nodata \
        -999.0 -te 438530.8125 7196987.0 744556.4375 7518031.0 -ot Float32 -of GTiff \
        -co COMPRESS=DEFLATE -co PREDICTOR=2 -co ZLEVEL=9 "PG:dbname='%s' host=%s port=5432 user='%s' password='%s'" \
        %s ''' % (layer, db, host, user, pw, raster_output)
        subprocess.call(rasterize, shell=True)
    os.chdir(target)
    natural_resource_layer = ''' 
        gdal_calc.py --calc "A+B+C+D" --format GTiff --type Float32 \
        --NoDataValue -999.0 -A mv_direct_supply_of_water_from_the_environment_index.tif \
        --A_band 1 -B mv_supply_of_building_materials_index.tif \
        --B_band 1 -C mv_use_of_wood_for_cooking_index.tif \
        --C_band 1 -D mv_use_of_wood_for_heating_index.tif \
        --D_band 1 --co COMPRESS=DEFLATE --co PREDICTOR=2 --co ZLEVEL=9 \
        --outfile local_natural_resource_dependence.tif'''
    subprocess.call(natural_resource_layer, shell=True)


if __name__ == "__main__":
    main()
