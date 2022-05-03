// This script extract the Sentinel 2 Band Values for all the scenes in the specified time frame

// --> You get multiple date values for each point

var samples = ee.FeatureCollection("users/Ludwigm6/muenster")

var aoi = ee.FeatureCollection("users/Ludwigm6/muenster").geometry().bounds();


function maskS2clouds(image) {
  var scl = image.select('SCL');
  var wantedPixels = scl.gt(3).and(scl.lt(7)).or(scl.eq(1)).or(scl.eq(2));
  return image.updateMask(wantedPixels)
}

var collection = ee.ImageCollection('COPERNICUS/S2_SR')
    .filterBounds(aoi)
    .filterDate('2017-05-01', '2017-09-30')
    .map(maskS2clouds)
    .select('B2', 'B3', 'B4', 'B8')


// iterate over all images in the image collection and
// extract the values
var sampledPoints = collection.map(function (image) {
  return image.sampleRegions({
  collection: samples,
  scale: 10});
}).flatten();


Export.table.toDrive(sampledPoints);
