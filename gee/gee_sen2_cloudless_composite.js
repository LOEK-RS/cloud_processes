var aoi = ee.FeatureCollection("users/Ludwigm6/muenster").geometry().bounds();


// function for masking of low quality pixels according to the SCL band

function maskS2clouds(image) {
  var scl = image.select('SCL');
  var wantedPixels = scl.gt(3).and(scl.lt(7)).or(scl.eq(1)).or(scl.eq(2));
  return image.updateMask(wantedPixels)
}

// Map the function over the time period of data and take the median.
var collection = ee.ImageCollection('COPERNICUS/S2_SR')
    .filterBounds(aoi)
    .filterDate('2017-05-01', '2017-09-30')
    .map(maskS2clouds)
    .select('B2', 'B3', 'B4', 'B8')

var composite = collection.median()



Export.image.toDrive({
  image: composite,
  description: 'sentinel',
  scale: 10,
  region: aoi
});
