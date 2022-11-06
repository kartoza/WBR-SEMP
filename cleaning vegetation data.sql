--QGIS Intersection operation failed because of invalid geometry in the VegMap layer so I tried to clean it. The below fixed a bunch of mainly self-intersections but there were still other errors that caused the Intersection operation to fail. So then I tried further cleaning via QGIS tools and an alternative pure PostGIS overlay operation

update nvm2018_aea_v22_7_16082019_final set geom = st_makevalid(geom) where not st_isvalid(geom)


update wbr_boundary_nov22 set geom = st_makevalid(geom) where not st_isvalid(geom)
--no invalid geoms. 