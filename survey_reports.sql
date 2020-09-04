set search_path to wbr_survey,public;
--CREATE EXTENSION IF NOT EXISTS tablefunc;
--preparing a spatial view of access to water, for charting in QGIS
--first git list of unique values to become field names in crosstab
select distinct main_source_water from wbr_report;

--drop view wateraccess_by_village;
create or replace view wateraccess_by_village AS 
with crosstab as 
(SELECT *
FROM   crosstab(
   'select village_name, main_source_water, count(*) ct
from wbr_survey.wbr_report
where village_name is not null and main_source_water is not null
group by village_name, main_source_water
order by village_name, main_source_water'
  , $$VALUES ('No source of drinkable water'), ('Borehole'), ('Piped to yard/plot'), ('Public tap/standpipe'), ('Natural spring'), ('Tanker truck'), ('Bottled water'), ('River/stream'), ('Dug well'), ('Piped water'), ('Other')$$
   ) AS ct (village character varying, "No source of drinkable water" int, "Borehole" int, "Piped to yard/plot" int, "Public tap/standpipe" int, "Natural spring" int, "Tanker truck" int, "Bottled water" int, "River/stream" int, "Dug well" int, "Piped water" int, "Other" int)
 )
 select id,geom,crosstab.* from wbr_survey.survey_villages sv join crosstab on sv.name = crosstab.village;
 
GRANT SELECT ON TABLE wbr_survey.wateraccess_by_village TO readonly;