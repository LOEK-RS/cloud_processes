// Build RF Model 
// Lucas Data vs. Selected Sentinel Variables

// Author: Zander Venter - zander.venter@nina.no

// This code is part of a workflow to classify land cover over Europe
// For final ELC10 map and link to manuscript see: https://doi.org/10.5281/zenodo.4407051

// Modified by Marvin Ludwig


// Import training dataset cleaned and tested in R
  // I am importing a demo dataset, but you should import your own
var trainingFeats = ee.FeatureCollection('projects/nina/ELC10/ELC10_training_feats');



/*
  // Train RF model and make predictions ///////////////////////////////////////////////////////////////////////////
*/

// Define the top 15 predictors identified in R scripts
  // this is to maximize efficiency of running RF predictions
var selectVars = [
  "ndvi_p25",
  "green_median",
  "temp" ,
  "light",
  "nbr_stdDev", 
  "asc_vh_median" ,
  "desc_vh_median",
  "swir2_median" ,
  "elevation" ,
  "desc_dpol_median",
  "R1_median",
  "precip" ,
  "asc_dpol_median",
  "temp_stDev",
  "asc_vv_stDev"
  ];

// Train Random Forest model
exports.classifier = ee.Classifier.smileRandomForest({
    numberOfTrees: 100
  }).setOutputMode('CLASSIFICATION')
  .train({
  features: trainingFeats, 
  classProperty: 'LC_num',
  inputProperties: selectVars
});


