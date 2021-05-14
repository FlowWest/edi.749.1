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
methods_docx <- "data-raw/mandy-salmanid-habitat-monitoring/methods.md"

# Add all datatables and associated metadata in a datatable_metadata tibble to be used by the add_datatable() function
datatable_metadata <- 
  dplyr::tibble(filepath = c("data/enclosure-study-growth-rate-data.csv",
                             "data/enclosure-study-gut-contents-data.csv",
                             "data/microhabitat-use-data-2018-2020.csv",
                             "data/seining-weight-lengths-2018-2020.csv",
                             "data/snorkel-index-data-2015-2020.csv"),  
                attribute_info = paste0("data-raw/mandy-salmanid-habitat-monitoring/",
                                        c("Enclosure Study - Growth Rates/enclosure-study-growth-rates-metadata.xlsx",
                                          "Enclosure Study - Gut Contents/enclosure-study-gut-contents-metadata.xlsx",
                                          "Microhabitat Use Data/microhabitat-use-metadata.xlsx",
                                          "Seining Data/seining-weight-length-metadata.xlsx",
                                          "Snorkel Index Data/snorkel-index-metadata.xlsx")),
                datatable_description = c("Growth Rates - Enclosure Study",
                                          "Gut Contents - Enclosure Study",
                                          "Microhabitat Data",
                                          "Seining Weight Lengths Data",
                                          "Snorkel Survey Data"),
                datatable_url = paste0("https://raw.githubusercontent.com/FlowWest/edi.749.1/main/data/",
                                       c("enclosure-study-growth-rate-data.csv",
                                         "enclosure-study-gut-contents-data.csv",
                                         "microhabitat-use-data-2018-2020.csv",
                                         "seining-weight-lengths-2018-2020.csv",
                                         "snorkel-index-data-2015-2020.csv")))

View(datatable_metadata)

# Create dataset list and pipe on metadata elements 
dataset <- list() %>%
  add_pub_date() %>% 
  add_title(metadata$title) %>%
  add_personnel(metadata$personnel) %>%
  add_keyword_set(metadata$keyword_set) %>%
  add_abstract(abstract_docx) %>%
  add_license(metadata$license) %>%
  add_method(methods_docx) %>%
  add_maintenance(metadata$maintenance) %>%
  add_project(metadata$funding) %>%
  add_coverage(metadata$coverage, metadata$taxonomic_coverage) %>%
  add_datatable(datatable_metadata)

# Create custom units to add to the additional metadata section of EML 
custom_units <- data.frame(id = c("fishPerEnclosure", "thermal unit", "day", "fishPerSchool"),
                           unitType = c("density", "temperature", "dimensionless", "density"),
                           parentSI = c(NA, NA, NA, NA),
                           multiplierToSI = c(NA, NA, NA, NA),
                           description = c("Fish density in the enclosure, number of fish in total enclosure space",
                                           "thermal unit of energy given off of fish",
                                           "count of number of days that go by",
                                           "Number of fish counted per school"))

unitList <- EML::set_unitList(custom_units)

# Add dataset and additiobal elements of eml to eml list
eml <- list(packageId = "edi.749.1",
            system = "EDI",
            access = add_access(),
            dataset = dataset,
            additionalMetadata = list(metadata = list(unitList = unitList)))

# Write and validate EML
EML::write_eml(eml, "edi.749.1.xml")
EML::eml_validate("edi.749.1.xml")

