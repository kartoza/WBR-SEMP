--4.4: see Issue48.sql

--4.5a

select name,(st_area(geom)/10000)::int as area_ha, source, owner as owner_or_type from core_protected_areas
order by name
;

--4.5b

select erven_id,allotmntno,standno,portionno,suburbname,cityname,farmname,lc,round((st_area(geom)/10000)::numeric,2) area_ha from farmportions where zone = 'buffer' order by area_ha desc;

--4.5c

select erven_id,allotmntno,standno,portionno,suburbname,cityname,farmname,lc,round((st_area(geom)/10000)::numeric,2) area_ha from farmportions where zone = 'transition' order by area_ha desc;