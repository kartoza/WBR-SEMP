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
    dependency_ratio = ''' CREATE MATERIALIZED VIEW public.mv_dependency_ratio
 AS
 WITH limpopo_subplace AS (
         SELECT a_1.*,
            b_1.geom
           FROM "employment-status-hhold-head" a_1
             JOIN sub_place b_1 ON a_1.sp_code = b_1.sp_code
          WHERE a_1.pr_name::text = 'Limpopo'::text
        )
 SELECT a.id, a.sal_code, a.sp_code, a.sp_name, a.mp_code, a.mp_name,
a.mn_mdb_c, a.mn_code, a.mn_name, a.dc_mdb_c, a.dc_code, a.dc_name, a.pr_code, a.pr_name, a.employed,
a.unemployed, a.dosicoraged_worker_seeker, a.not_economically_active, a.less_than_15,
    st_transform(st_intersection(a.geom,b.geom),32735) AS geom
   FROM limpopo_subplace a
     JOIN aoi_wbr b ON st_intersects(b.geom, a.geom);'''
    cursor.execute(dependency_ratio)
    connection.commit()
    dependency_ratio_index = ''' 
            CREATE MATERIALIZED VIEW public.mv_dependency_ratio_index AS
SELECT id,  sp_code, sp_name,
case when employed = 0 then
0 else
round((100 - ((sum(unemployed::decimal + dosicoraged_worker_seeker::decimal
                       + not_economically_active::decimal + less_than_15::decimal) / employed::decimal)/100))/10,4)

end AS "index",geom
FROM public.mv_dependency_ratio
group by (id,sp_code,sp_name,geom,employed,unemployed,dosicoraged_worker_seeker,not_economically_active,less_than_15) ;'''
    cursor.execute(dependency_ratio_index)
    connection.commit()

    proportion_of_low_income_households = ''' 
        CREATE MATERIALIZED VIEW public.mv_proportion_of_low_income_households
 AS
 WITH limpopo_subplace AS (
         SELECT a_1.*,
            b_1.geom
           FROM "annual-household-income" a_1
             JOIN sub_place b_1 ON a_1.sp_code = b_1.sp_code
          WHERE a_1.pr_name::text = 'Limpopo'::text
        )
 SELECT a.id,  a.sal_code, a.sp_code, a.sp_name, a.mp_code, a.mp_name,
a.mn_mdb_c, a.mn_code, a.mn_name, a.dc_mdb_c, a.dc_code, a.dc_name, a.pr_code,
a.pr_name, a.no_income, a."1-4800k", a."4801-9600", a."9601-19600", a."19601-38200",
a."38201-76400", a."76401-153800", a."153801-307600", a."307601-614400",
a."614001-1228800", a."1228801-2457600", a."greater than 24576001", a.unspecified,
    st_transform(st_intersection(a.geom,b.geom),32735) AS geom
   FROM limpopo_subplace a
     JOIN aoi_wbr b ON st_intersects(b.geom, a.geom);'''
    cursor.execute(proportion_of_low_income_households)
    connection.commit()
    proportion_of_low_income_households_index = ''' CREATE MATERIALIZED VIEW public.mv_proportion_of_low_income_households_index AS
WITH sample AS (
SELECT a.id, a.sp_code, sum(a.no_income + a."1-4800k" + a."4801-9600") / st_area(a.geom) * 1000000::decimal
    as income_density, geom
FROM public.mv_proportion_of_low_income_households as a
group by (a.id, a.sp_code,geom))
    SELECT sample.id,
    sample.sp_code,

        CASE WHEN
        (sample.income_density / (( SELECT percentile_cont(0.9::decimal)
                WITHIN GROUP (ORDER BY sample_1.income_density) AS percentile_cont
               FROM sample sample_1))) > 10 THEN 10
        ELSE
        (sample.income_density / (( SELECT percentile_cont(0.9::decimal)
                WITHIN GROUP (ORDER BY sample_1.income_density) AS percentile_cont
               FROM sample sample_1)))
    END AS "index" ,sample.geom
   FROM sample;'''
    cursor.execute(proportion_of_low_income_households_index)
    connection.commit()

    connection.close()
    index_layers = ['proportion_of_low_income_households_index', 'mv_dependency_ratio_index']
    for layer in index_layers:
        raster_layer = layer + '.tif'
        raster_output = os.path.join(target, raster_layer)
        rasterize = ''' gdal_rasterize -l public.%s -a index -tr 15.0 15.0 -a_nodata \
        -999.0 -te 438530.8125 7196987.0 744556.4375 7518031.0 -ot Float32 -of GTiff \
        -co COMPRESS=DEFLATE -co PREDICTOR=2 -co ZLEVEL=9 "PG:dbname='%s' host=%s port=5432 user='%s' password='%s'" \
        %s ''' % (layer, db, host, user, pw, raster_output)
        subprocess.call(rasterize, shell=True)
    os.chdir(target)
    poverty_index_layer = ''' 
        gdal_calc.py --calc "A+B+C+D" --format GTiff --type Float32 \
        --NoDataValue -999.0 \
        -A proportion_of_low_income_households_index.tif \
        --A_band 1 -B mv_dependency_ratio_index.tif --B_band 1  \
        --co COMPRESS=DEFLATE --co PREDICTOR=2 --co ZLEVEL=9 \
        --outfile poverty_index.tif'''
    subprocess.call(poverty_index_layer, shell=True)


if __name__ == "__main__":
    main()
