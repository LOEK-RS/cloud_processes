# create a cloudless composite over a given date range and add NDVI and EVI computation
# if you change the input bands, you'll need to adapt the band indices at the ndvi_and evi_ formulas
library(openeo)

# establish connection
con <- connect(host = "https://openeo.cloud")

# get a process graph builder, see ?processes
p <- processes()

aoa <- list(west = 10.452617, south = 51.361166, east = 10.459773, north = 51.364194) # niederorschel
t <- c("2018-07-01", "2018-07-15")

cube_s2 <- p$load_collection(
  id = "SENTINEL2_L2A_SENTINELHUB",
  spatial_extent = aoa,
  temporal_extent = t,
  bands=c("B02", "B03", "B04", "B05", "B06", "B07", "B08", "B8A", "B11", "B12")
)

# load SCL in separate collection, must be same aoi and t extent!
cube_SCL <- p$load_collection(
  id = "SENTINEL2_L2A_SENTINELHUB",
  spatial_extent = aoa,
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
  or1 <- p$or(veg, no_veg)
  or2 <- p$or(water, unclassified)
  or3 <- p$or(or2, snow)
  # create mask
  return(p$not(p$or(or1, or3)))
}

# create mask by reducing bands with our defined formula
cube_SCL_mask <- p$reduce_dimension(data = cube_SCL, reducer = clouds_, dimension = "bands")

# mask the S2 cube
cube_s2_masked <- p$mask(cube_s2, cube_SCL_mask)

cube_s2_yearly_composite <- p$reduce_dimension(cube_s2_masked, function(x, context) {
  p$median(x, ignore_nodata = TRUE)
}, "t")

# compute indices here, possibly move up when needed per season or something
# at the day of writing this, it is not yet possible to pass x["B08"], so indices must be used.
# they must be changed if the loaded bands are changed.
# copy from above to find indices: ("B02", "B03", "B04", "B05", "B06", "B07", "B08", "B8A", "B11", "B12")
ndvi_ <- function(x, context) {
  b4 <- x[3]
  b8 <- x[7]
  return(p$normalized_difference(b8, b4))
}

evi_ <- function(x, context) {
  b2 <- x[1]
  b4 <- x[3]
  b8 <- x[7]
  return((2.5 * (b8 - b4)) / ((b8 + 6 * b4 - 7.5 * b2) + 1))
}

# compute on bands dimension and then add the band dimension back
cube_s2_yearly_ndvi <- p$reduce_dimension(cube_s2_yearly_composite, ndvi_, "bands")
cube_s2_yearly_ndvi <- p$add_dimension(cube_s2_yearly_ndvi, name = "bands", label = "NDVI", type = "bands")

cube_s2_yearly_evi <- p$reduce_dimension(cube_s2_yearly_composite, evi_, "bands")
cube_s2_yearly_evi <- p$add_dimension(cube_s2_yearly_evi, name = "bands", label = "EVI", type = "bands")

# merge cubes
cube_s2_yearly_merge1 <- p$merge_cubes(cube_s2_yearly_composite, cube_s2_yearly_ndvi)
cube_s2_yearly_merge2 <- p$merge_cubes(cube_s2_yearly_merge1, cube_s2_yearly_evi)

res <- p$save_result(data = cube_s2_yearly_merge2, format = "GTiff")

# send job to back-end
# job <- create_job(graph = res, title = "test extract batch 10m")

# create process graph
process <- as(res, "Process")
process_json <- jsonlite::toJSON(process$serialize(), auto_unbox = TRUE, force = TRUE) # doesnt work anymore

# if needed, write graph JSON to file
cat(process_json, file = "./cloudless_composite_ndvi_evi.json")

