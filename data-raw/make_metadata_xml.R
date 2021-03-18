library(EMLaide)
library(tidyverse)
library(EDIutils)
library(readxl)
library(EML)

# save cleaned data to `data/`
#-------------------------------------------------------------------------------
# files and parameters to enter directly into the R script
excel_path <- "data-raw/mandy-salmanid-habitat-monitoring/Enclosure Study - Growth Rates/enclosure-study-growth-rates-metadata.xlsx"
sheets <- readxl::excel_sheets(excel_path)
metadata <- lapply(sheets, function(x) readxl::read_excel(excel_path, sheet = x))
names(metadata) <- sheets

abstract_docx <- "data-raw/mandy-salmanid-habitat-monitoring/Enclosure Study - Growth Rates/enclosure-study-growth-rates-abstract.docx"
methods_docx <- "data-raw/mandy-salmanid-habitat-monitoring/Enclosure Study - Growth Rates/enclosure-study-growth-rates-methods.docx"
#dataset_file <- "data-raw/metadata_complete/ARIS_ALAN.csv"

dataset_file_name <- "enclosure-study-growth-rate-data.csv"
# dO ALL DATASETS
dataset_files <- dplyr::tibble(datatable =  c("data/enclosure-study-growth-rate-data.csv",
                                              "data/enclosure-study-gut-contents-data.csv",
                                              "data/microhabitat-use-data-2018-2020.csv",
                                              "data/seining-weight-lengths-2018-2020.csv",
                                              "data/snorkel-index-data-2015-2020.csv"
), 
                               datatable_name = c("enclosure-study-growth-rate-data.csv",
                                                  "enclosure-study-gut-contents-data.csv",
                                                  "microhabitat-use-data-2018-2020.csv",
                                                  "seining-weight-lengths-2018-2020.csv",
                                                  "snorkel-index-data-2015-2020.csv"
), 
                               attribute_info = c("data-raw/mandy-salmanid-habitat-monitoring/Enclosure Study - Growth Rates/enclosure-study-growth-rates-metadata.xlsx",
                                                  "data-raw/mandy-salmanid-habitat-monitoring/Enclosure Study - Gut Contents/enclosure-study-gut-contents-metadata.xlsx",
                                                  "data-raw/mandy-salmanid-habitat-monitoring/Microhabitat Use Data/microhabitat-use-metadata.xlsx",
                                                  "data-raw/mandy-salmanid-habitat-monitoring/Seining Data/seining-weight-length-metadata.xlsx",
                                                  "data-raw/mandy-salmanid-habitat-monitoring/Snorkel Index Data/snorkel-index-metadata.xlsx"
))

# EDI number -------------------------------------------------------------------
edi_number = "edi.749.1"

# Add Access -------------------------------------------------------------------
access <- add_access()

### Add Publication Date -------------------------------------------------------
pub_date <- add_pub_date(list())

### Add Personnel: Creator, Contact, and Associated Parties.--------------------
personnel <- list()
adds_person <- function(first_name, last_name, email, role, organization, orcid) {
  personnel <- add_personnel(personnel, first_name, last_name, email,
                             role, organization, orcid)
}
personnel <- purrr::pmap(metadata$personnel, adds_person) %>% flatten()

### Add Title and Short Name ---------------------------------------------------
title <- add_title(list(), title = metadata$title$title,
                   short_name = metadata$title$short_name)

### Add Keyword Set ------------------------------------------------------------
keywords <- add_keyword_set(list(), metadata$keyword_set[,1])

### Add Abstract ---------------------------------------------------------------
abstract <- add_abstract(list(), abstract = abstract_docx)

### Add License and Intellectual Rights ----------------------------------------
license <- add_license(list(), default_license = metadata$license$default_license)

### Add Methods ----------------------------------------------------------------
methods <- add_method(list(), methods_file = methods_docx)

### Add Maintenance

maintenance <- add_maintenance(list(), status = metadata$maintenance$status,
                               update_frequency = metadata$maintenance$update_frequency)

### Add Project:

#### Add Project personnel -----------------------------------------------------
project_personnel <- personnel$creator[1:3]


#### Add Project funding -------------------------------------------------------
award_information <- purrr::pmap(metadata$funding, add_funding) %>% flatten()

#### Add Combining Project Elements --------------------------------------------

project <- add_project(list(),
                       project_title = metadata$project$project_title,
                       award_information,
                       project_personnel)

### Add Coverage: Geographic, Temporal, Taxonomic ------------------------------
taxonomic_coverage <- purrr::pmap(metadata$taxonomic_coverage, add_taxonomic_coverage)

#### Add Combining Coverage Elements -------------------------------------------
coverage <- add_coverage(list(),
                         geographic_description = metadata$coverage$geographic_description,
                         west_bounding_coordinate = metadata$coverage$west_bounding_coordinate,
                         east_bounding_coordinate = metadata$coverage$east_bounding_coordinate,
                         north_bounding_coordinate = metadata$coverage$north_bounding_coordinate,
                         south_bounding_coordinate = metadata$coverage$south_bounding_coordinate,
                         begin_date = metadata$coverage$begin_date,
                         end_date = metadata$coverage$end_date,
                         taxonomic_coverage = taxonomic_coverage)

### Add DataTable or SpatialRaster or SpatialVector ----------------------------
#### Add Physical --------------------------------------------------------------
#physical <- add_physical(file_path = dataset_file, data_url = NULL)


#### Add data tables -----------------------------------------------------------
# Create helper function to add code definitions if domain is "enumerated"
adds_datatable <- function(datatable, datatable_name, attribute_info, dataset_methods = NULL, additional_info = NULL){
  attribute_table <- readxl::read_xlsx(attribute_info, sheet = "attribute")
  codes <- readxl::read_xlsx(attribute_info, sheet = "code_definitions")
  attribute_list <- list()
  attribute_names <- unique(codes$attribute_name)
  
  # Code helper function
  code_helper <- function(code, definitions) {
    codeDefinition <- list(code = code, definition = definitions)
  }
  # Attribute helper function to input into pmap
  attributes_and_codes <- function(attribute_name, attribute_definition, storage_type,
                                   measurement_scale, domain, type, units, unit_precision,
                                   number_type, date_time_format, date_time_precision, minimum, maximum,
                                   attribute_label){
    if (domain %in% "enumerated") {
      definition <- list()
      current_codes <- codes[codes$attribute_name == attribute_name, ]
      definition$codeDefinition <- purrr::pmap(current_codes %>% select(-attribute_name), code_helper)
    } else {
      definition = attribute_definition
    }
    new_attribute <- EMLaide::add_attribute(attribute_name = attribute_name, attribute_definition = attribute_definition,
                                             storage_type = storage_type, measurement_scale = measurement_scale,
                                             domain = domain, definition = definition, type = type, units = units,
                                             unit_precision = NULL, number_type = number_type,
                                             date_time_format = date_time_format, date_time_precision = date_time_precision,
                                             minimum = minimum, maximum = maximum, attribute_label = attribute_label)
  }
  attribute_list$attribute <- purrr::pmap(attribute_table, attributes_and_codes) %>% na.omit()
  
  physical <- add_physical(file_path = datatable)
  dataTable <- list(entityName = datatable_name,
                    entityDescription = metadata$dataset$name,
                    physical = physical,
                    attributeList = attribute_list)
}
data_tables <- purrr::pmap(dataset_files, adds_datatable)

# Adding additional metadata with custom units
# TODO make a function to take care of cutom units
custom_units <- data.frame(id = c("fishPerEnclosure", "thermal unit", "day", "fishPerSchool"),
                           unitType = c("density", "temperature", "dimensionless", "density"),
                           parentSI = c(NA, NA, NA, NA, NA),
                           multiplierToSI = c(NA, NA, NA, NA, NA),
                           description = c("Fish density in the enclosure, number of fish in total enclosure space", 
                                           "thermal unit of energy given off of fish",
                                           "count of number of days that go by",
                                           "Number of fish counted per school"))

unitList <- set_unitList(custom_units)

# Appending all to dataset list
dataset <- list(title = title$title,
                shortName = title$shortName,
                creator = personnel$creator,
                contact = personnel$contact,
                pubDate = pub_date,
                abstract = abstract$abstract,
                associatedParty = list(personnel[[3]], personnel[[4]], personnel[[5]]),
                keywordSet = keywords$keywordSet,
                coverage = coverage$coverage,
                project = project$project,
                intellectualRights = license$intellectualRights,
                licensed = license$licensed,
                methods = methods,
                maintenance = maintenance$maintenance,
                dataTable = data_tables)

## Making the EML document -----------------------------------------------------
eml <- list(packageId = edi_number,
            system = "EDI",
            access = access,
            dataset = dataset, 
            additionalMetadata = list(metadata = list(
              unitList = unitList)))

file_name <- paste(edi_number, "xml", sep = ".")
EML::write_eml(eml, file_name)
EML::eml_validate(file_name)


