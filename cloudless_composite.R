library(openeo)

# establish connection
con <- connect(host = "https://openeo.cloud")

# get a process graph builder, see ?processes
p <- processes()

# define aoi and t extents here so they can be reused
aoi <- list(west = 10.452617, south = 51.361166, east = 10.459773, north = 51.364194)
t <- c("2017-07-01", "2017-09-01")

cube_s2 <- p$load_collection(
  id = "SENTINEL2_L2A_SENTINELHUB",
  spatial_extent = aoi,
  temporal_extent = t,
  bands=c("B02", "B03", "B04", "B08", "B12")
)

# load SCL in separate collection, must be same aoi and t extent!
cube_SCL <- p$load_collection(
  id = "SENTINEL2_L2A_SENTINELHUB",
  spatial_extent = aoi,
  temporal_extent = t,
  bands=c("SCL")
)

# define filter function to create mask from a cube that only contains 1 band: SCL
clouds_ <- function(data, context) {
  SCL <- data[1] # select SCL band
  # we wanna keep:
  veg <- p$eq(SCL, 4) # select pixels with the respective codes
  no_veg <- p$eq(SCL, 5)
  water <- p$eq(SCL, 6)
  unclassified <- p$eq(SCL, 7)
  snow <- p$eq(SCL, 11)
  # or has only 2 arguments so..
  or1 <- p$or(veg, no_veg) # veg | no_veg
  or2 <- p$or(water, unclassified) # water | unclassified
  or3 <- p$or(or2, snow) # water | unclassified | snow
  # create mask
  return(p$not(p$or(or1, or3))) # NOT (veg | no_veg | water | unclassified | snow)
}

# create mask by reducing bands with our defined formula
cube_SCL_mask <- p$reduce_dimension(data = cube_SCL, reducer = clouds_, dimension = "bands")

# mask the S2 cube
cube_s2_masked <- p$mask(cube_s2, cube_SCL_mask)

# reduce the temporal dimension with a median (p$mean also possible)
cube_s2_composite <- p$reduce_dimension(cube_s2_masked, function(x, context) {
  p$median(x, ignore_nodata = TRUE)
}, dimension = "t")

# create result node
res <- p$save_result(data = cube_s2_composite, format = "GTiff")

# send job to back-end
# job <- create_job(graph = res, title = "composite_test_04/17-06/17")

# create process graph
process <- as(res, "Process")
process_json <- jsonlite::toJSON(process$serialize(), auto_unbox = TRUE, force = TRUE) # doesnt work anymore

# if needed, write graph JSON to file
cat(process_json, file = "./cloudless_composite.json")
