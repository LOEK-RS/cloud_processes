#' Open EO Sentinel 2 Composite
#' @description Processing Graph for Sentinel 2 Composite in open EO
#' 
#' @param region sf, the area of interest
#' @param t vector of length 2 with two date stings e.g. c("2021-04-01", "2021-10-01")
#' 
#' @author Jonathan Bahlmann, Marvin Ludwig
#' 
#' @details Before running this function, you have to estanblish a connection to openEO
#'    by running \code{openeo::connect()}. Note: Currently just takes the bounding box of region.
#'    
#' 


sentinel_composite = function(region, t){
    
    
    # input handling
    region = st_bbox(region)
    
    
    aoi = list(west = region["xmin"],
               south = region["ymin"],
               east = region["xmax"],
               north = region["ymax"]) 
    
    # TODO: check here that t is in the right format
    
    # create open EO process
    # get a process graph builder, see ?processes
    p <- processes()
    
    
    
    
    cube_s2 <- p$load_collection(
        id = "SENTINEL2_L2A",
        spatial_extent = aoi,
        temporal_extent = t,
        # load less bands for faster computation
        bands=c("B02", "B03", "B04", "B05", "B06", "B07", "B08", "B8A", "B11", "B12")
        # bands= c("B02", "B04", "B08")
        # AFAIK resolution stays at highest by default
    )
    
    # load SCL in separate collection, must be same aoi and t extent!
    cube_SCL <- p$load_collection(
        id = "SENTINEL2_L2A",
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
    # default: replaced with 0. change to -99?
    
    cube_s2_yearly_composite <- p$reduce_dimension(cube_s2_masked, function(x, context) {
        p$median(x, ignore_nodata = TRUE)
    }, "t")
    
    # compute indices here, possibly move up when needed per season or something
    # CHANGE BAND INDICES HERE WHEN CHANGING BANDS LOADED
    # ("B02", "B03", "B04", "B05", "B06", "B07", "B08", "B8A", "B11", "B12")
    
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
    
    cube_s2_yearly_ndvi <- p$reduce_dimension(cube_s2_yearly_composite, ndvi_, "bands")
    cube_s2_yearly_ndvi <- p$add_dimension(cube_s2_yearly_ndvi, name = "bands", label = "NDVI", type = "bands")
    
    cube_s2_yearly_evi <- p$reduce_dimension(cube_s2_yearly_composite, evi_, "bands")
    cube_s2_yearly_evi <- p$add_dimension(cube_s2_yearly_evi, name = "bands", label = "EVI", type = "bands")
    
    # merge cubes
    cube_s2_yearly_merge1 <- p$merge_cubes(cube_s2_yearly_composite, cube_s2_yearly_ndvi)
    cube_s2_yearly_merge2 <- p$merge_cubes(cube_s2_yearly_merge1, cube_s2_yearly_evi)
    
    # create result node
    res <- p$save_result(data = cube_s2_yearly_merge2, format = "GTIFF")
    
    # export with option
    # res <- p$save_result(data = cube_s2_yearly_extr, format = "NetCDF", options = list(sample_by_feature = TRUE))
    
    # send job to back-end
    #job <- create_job(graph = res, title = "NRW Sentinel 2")
    
    
    process = as(res, "Process")
    
    
    return(process)
    
    
}


