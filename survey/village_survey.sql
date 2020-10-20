set search_path to wbr_survey,public;

--got the 'WBR WASH Village Questionnaire 17 09 2020' spreadsheet from Lesiba / Richard
--loaded in QGIS
--ran convert table to point layer tool
--loaded into the WBR cloud DB

--found three points with wrong X,Y order and sign

select * from wbr_wash_village_survey;

select st_x(geom),st_astext(geom) from wbr_wash_village_survey where "Village" in ('Uitzight','Ga-Chokwe (Sterkwater)','Nong (Dipere 2)');

update wbr_wash_village_survey set geom = st_setsrid(st_makepoint(-st_y(geom),-st_x(geom)),4326)
where "Village" in ('Uitzight','Ga-Chokwe (Sterkwater)','Nong (Dipere 2)');