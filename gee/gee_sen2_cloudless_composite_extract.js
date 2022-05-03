var samples = ee.FeatureCollection("users/Ludwigm6/muenster")
var aoi = samples.geometry().bounds();


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

var composite = collection.median()



var sampledPoints = composite.sampleRegions({
  collection: samples,
  scale: 10
})

Export.table.toDrive(sampledPoints);
