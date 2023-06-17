source(here::here("R", "common.R"))

gonads <- c("testisPos", "testisSize", "ovaryOpening", "mammaeCondition", "mammaeFormula")

clean_collname <- function(df) {
  df |> 
    dplyr::rename(collectorLastName = cataloger) |>
    dplyr::rename(species = specificEpithet) |>
    dplyr::rename(state = stateProvince) |>
    dplyr::rename(prepType = preparation) |>
    dplyr::mutate(fieldNumber = stringr::str_extract(fieldID, pattern = "\\d+")) |>
    tidyr::unite("locality", municipality:specificLocality, sep = ", ", remove = FALSE) |>
    tidyr::separate_wider_delim(prepType, delim = "|", names = prepType.colnames,  too_few = "align_start") |>
    tidyr::separate_wider_delim(coordinates, delim = "|", names = coordinates.colnames,  too_few = "align_start") |>
    tidyr::unite("remarks", gonads, sep = ", ", remove = FALSE, na.rm = TRUE)
}


prep_types.lsumz_cols <- "PrepType PreparedDate Count TissueType Preservation	StorageLocation Notes"

prepType.size <- col_size(df$preparation)

tissue_list <- c("Liver", "Lung", "Heart", "Muscle", "Kidney")

prep_types.nahpu_cols <- "PrepType Preservation	Count	TissueType	StorageLocation PreparedDate	 Notes"

nahpu.allCols <- space_split_to_vec(prep_types.nahpu_cols)

prepType.colnames <- paste0("PrepType", 1:prepType.size)

prepType.allCols <- space_split_to_vec(prep_types.lsumz_cols)

split_prepType <- function(cols) {
  index <- stringr::str_extract(cols, pattern = "\\d+")
  coll_names <- paste0(nahpu.allCols, index)
  lsu_cols<- paste0(prepType.allCols, index)
  tissueType <- paste0("TissueType", index)
  prepType <- paste0("PrepType", index)
  cleaned.df |> 
    dplyr::select("specimenUUID", cols) |>
    tidyr::separate_wider_delim(cols, delim = ";", names = coll_names, too_few = "align_start", too_many = "merge") |>
    dplyr::select("specimenUUID", lsu_cols)
}

nahpu_coord.cols <- c("name", "lat/long", "elevation", "MaxErrorDistance", "datum", "gps", "notes")

coordinate.size <- col_size(df$coordinates)

coordinates.colnames <- paste0("Coordinate", 1:coordinate.size)

split_coordinate <- function(cols) {
  coll_names <- paste0(nahpu_coord.cols, ".", cols)
  latlong_cols <- paste0(c("Latitude", "Longitude"), ".", cols)
  cleaned.df |>
    dplyr::select("specimenUUID", cols) |>
    tidyr::separate_wider_delim(cols, delim = ";", names = coll_names, too_few = "align_start", too_many = "merge") |>
    tidyr::separate_wider_delim(3, delim = ",", names = latlong_cols, too_few = "align_start", too_many = "merge") |>
    tidyr::separate_wider_regex(5, c(elevationTemp = "\\d+", unitTemp = "\\w+")) |>
    dplyr::rename("Elevation.{cols}" := elevationTemp) |>
    dplyr::rename("ElevationUnit.{cols}" := unitTemp)
}