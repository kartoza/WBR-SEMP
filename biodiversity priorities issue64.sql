--biodiversity priorities https://github.com/kartoza/WBR-SEMP/issues/64

--CBAs
select distinct final_cat,cba from sanbi.limpopo_cba_esa;

select case when cba in ('PA','CBA1') then 10 
	when cba in ('CBA2') then 5 
	when cba in ('ESA1','ESA2') then 2 end as score
from sanbi.limpopo_cba_esa
where cba in ('PA','CBA1','CBA2','ESA1','ESA2')

--remove transformed: Cultivated areas, plantations, dams, urban, industrial and mining areas

--protected area expansion priorities
--we should be using the Limpopo PAES (from LBIMS) but in the meantime use the national one

select distinct focus_area from sanbi.npaes_focus_areas_completetable;