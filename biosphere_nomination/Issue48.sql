--areas of original zones in ha
select site_stype as zone, sum(sum(st_area(geom))/10000) over ()::int as total, (sum(st_area(geom))/10000)::int area from biosphere_reserves_waterberg
where site_stype is not null
group by site_stype;

--areas of new zones in ha
select zone,sum(sum(st_area(geom))/10000) over ()::int as total,(sum(st_area(geom))/10000)::int area from farmportions
where zone is not null
group by zone;