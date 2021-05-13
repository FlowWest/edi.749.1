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

# dO ALL DATASETS
datatable_metadata <- dplyr::tibble(filename = c("enclosure-study-growth-rate-data.csv",
                                             "enclosure-study-gut-contents-data.csv",
                                             "microhabitat-use-data-2018-2020.csv",
                                             "seining-weight-lengths-2018-2020.csv",
                                             "snorkel-index-data-2015-2020.csv"),  
                               attribute_info = c("data-raw/mandy-salmanid-habitat-monitoring/Enclosure Study - Growth Rates/enclosure-study-growth-rates-metadata.xlsx",
                                                  "data-raw/mandy-salmanid-habitat-monitoring/Enclosure Study - Gut Contents/enclosure-study-gut-contents-metadata.xlsx",
                                                  "data-raw/mandy-salmanid-habitat-monitoring/Microhabitat Use Data/microhabitat-use-metadata.xlsx",
                                                  "data-raw/mandy-salmanid-habitat-monitoring/Seining Data/seining-weight-length-metadata.xlsx",
                                                  "data-raw/mandy-salmanid-habitat-monitoring/Snorkel Index Data/snorkel-index-metadata.xlsx"),
                               datatable_description = c("Growth Rates - Enclosure Study",
                                                         "Gut Contents - Enclosure Study",
                                                         "Microhabitat Data",
                                                         "Seining Weight Lengths Data",
                                                         "Snorkel Survey Data"),
                               datatable_url = c("https://raw.githubusercontent.com/FlowWest/CVPIA_Salmonid_Habitat_Monitoring/make-xml/data/enclosure-study-growth-rate-data.csv?token=AMGEQ7R4E5RMNKRMD57BBQTAOSW6W",
                                                 "https://raw.githubusercontent.com/FlowWest/CVPIA_Salmonid_Habitat_Monitoring/make-xml/data/enclosure-study-gut-contents-data.csv?token=AMGEQ7VJADFEYARKPUM4AYTAOSXAQ",
                                                 "https://raw.githubusercontent.com/FlowWest/CVPIA_Salmonid_Habitat_Monitoring/make-xml/data/microhabitat-use-data-2018-2020.csv?token=AMGEQ7WQ3NCY62J75HI3BULAOSXB6",
                                                 "https://raw.githubusercontent.com/FlowWest/CVPIA_Salmonid_Habitat_Monitoring/make-xml/data/seining-weight-lengths-2018-2020.csv?token=AMGEQ7SOD4FLW2SOIZ373CDAOSXDQ",
                                                 "https://raw.githubusercontent.com/FlowWest/CVPIA_Salmonid_Habitat_Monitoring/make-xml/data/snorkel-index-data-2015-2020.csv?token=AMGEQ7SOHIYOGP3MDE2AB4DAOSXFI")
                               
)

# Create dataset list 

dataset <- list() %>% 
  add_pub_date() %>% 
  add_title(metadata$title) %>%
  add_personnel(metadata$personnel) %>%
  add_keyword_set(metadata$keyword_set) %>%
  add_abstract(abstract_docx) %>%
  add_license(metadata$license) %>%
  add_method(methods_docx) %>%
  add_maintenance(metadata$maintenance) %>%
  add_project(metadata$title, metadata$personnel, metadata$funding) %>%
  add_coverage(metadata$coverage, metadata$taxonomic_coverage) %>%
  add_data_table(datatable_metadata)

custom_units <- data.frame(id = c("fishPerEnclosure", "thermal unit", "day", "fishPerSchool"),
                           unitType = c("density", "temperature", "dimensionless", "density"),
                           parentSI = c(NA, NA, NA, NA),
                           multiplierToSI = c(NA, NA, NA, NA),
                           description = c("Fish density in the enclosure, number of fish in total enclosure space", 
                                           "thermal unit of energy given off of fish",
                                           "count of number of days that go by",
                                           "Number of fish counted per school"))

unitList <- EML::set_unitList(custom_units)

eml <- list(packageId = "edi.749.1",
            system = "EDI",
            access = add_access(),
            dataset = dataset,
            additionalMetadata = list(metadata = list(
              unitList = unitList)))


file_name <- paste("edi.749.1", "xml", sep = ".")
EML::write_eml(eml, file_name)
EML::eml_validate(file_name)
