// Prediction and Download


var model = require('users/Ludwigm6/globalAOA/:buildModel');
var predictors = require('users/Ludwigm6/globalAOA/:computePredictors')


var classified = masterStack.classify(classifier);


// Update mask
  //classified = classified.updateMask(mask);
  // Set metadata property
  classified = classified.set('CellCode', CellCode).rename('landcover');
  // Reproject to Pflugmacher image at 10m (not really necessary)
  classified = classified.reproject(predictors.masterStack.projection().atScale(10)).clip(predictors.aoi);

predictors.masterStack.addBands(classified)


  
Export.image.toDrive({
  image: masterStack,
  description: 'masterStack',
  scale: 10,
  region: aoi
  });



