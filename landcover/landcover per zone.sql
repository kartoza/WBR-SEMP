--to get land cover stats per zone I did a zonal histogram in QGIS, transposed them in Calc and loaded into the DB (output_zones). This gives number of pixels per class per zone. 
--pixels are 20m hence 400sq.m each

select lut.class_name, (ot.core::double precision*400/10000)::int as core_ha, (ot.buffer::double precision*400/10000)::int as buffer_ha, (ot.transition::double precision*400/10000)::int as transition_ha from output_zones ot join nlc_2018_lut lut on trim(leading 'HISTO_' from ot.zone)::int = lut.value order by lut.value;



