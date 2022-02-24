# Useful Notes

Notes. If there's anything really useful we can think about adding it to the [openEO cookbook](https://openeo.org/documentation/1.0/cookbook/).

### AOI

AOI is usually an extent like
```R
aoi <- list(west = 10.452617, south = 51.361166, east = 10.459773, north = 51.364194)
```
but can also be an sf object that will be converted to geojson by the R client. Currently, a geojson `FeatureCollection` is not supported, which means that you should only pass the geometry of the sf object like `st_geometry(aoi_sf)` so it will be converted to a `POLYGON` and not a collection.

when dealing with larger areas these sf polygons can become quite large, in which case the process graph will become exceptionally long and will be rejected by the backend. In this case just use
```R
st_convex_hull(aoi_sf)
```
to create a polygon that contains the complete AOI but is still smaller that the bbox, hopefully.