# Remote Sensing processing in Cloud Platforms

This repository contains code snippets and workflow suggestions for cloud computing platforms (Google Earth Engine and openEO). The goal is, to provide a user friendly description and modularity of common tasks that are needed to get remote sensing data from the platforms. This usually revolves around the following steps and decisions:


1. Decide on product you want to have.
1. Define the Area of Interest and time frame
1. Filter clouds or other unwanted features in the images
1. Select and Calculate Bands, Indices etc.
1. Do you need a composite or the full time series?
1. Do you need the image(s) or the extraction of values in the AOI?


## Google Earth Engine

### Functions

Processes in GEE are most of the time specific for a particular `ImageCollection`.
I suggest, as a naming convention for modular functions we use the name of the `ImageCollection` as a prefix e.g.

```
exports.S2_SR_maskclouds = function (image) {
  var scl = image.select('SCL');
  var wantedPixels = scl.gt(3).and(scl.lt(7)).or(scl.eq(1)).or(scl.eq(2));
  return image.updateMask(wantedPixels)
}
```

The `exports.` means that we can reuse this function in other scripts by importing the file with `require()`.
See here for more explanation about this: [Google Earth Engine Code Editor Documentation](https://developers.google.com/earth-engine/guides/playground)


### Snippets

Snippets are little code chunks that probably do not work on their own but serve as a guidline on how to do something.
If you copy snippets from here you most likely have to change some names or parameters in code. Everything that is a variable name is written in CAPS and most likely has to be adjusted to you names.


## openEO

The [openEO cookbook](https://openeo.org/documentation/1.0/cookbook/).

The [openEO Documentation](https://docs.openeo.cloud/)


## Terminology

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
