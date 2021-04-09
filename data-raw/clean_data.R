library(tidyverse)
library(readxl)
# save cleaned data to `data/`

# Look at existing datasets
enclosure_growth_data <- read_excel("data-raw/mandy-salmanid-habitat-monitoring/Enclosure Study - Growth Rates/enclosure-study-growth-rate-data.xlsx") %>%
  glimpse()
write_csv(enclosure_growth_data, 'data/enclosure-study-growth-rate-data.csv')

enclosure_gut_data <- read_excel("data-raw/mandy-salmanid-habitat-monitoring/Enclosure Study - Gut Contents/enclosure-study-gut-contents-data.xlsx") %>%
  glimpse() 
write_csv(enclosure_gut_data, "data/enclosure-study-gut-contents-data.csv")

microhabitat_data <- read_excel("data-raw/mandy-salmanid-habitat-monitoring/Microhabitat Use Data/microhabitat-use-data-2018-2020.xlsx") %>% 
  mutate(date = as.Date(date),
         comments = str_remove_all(comments, ","),
         cover_type = str_replace_all(cover_type, ",", " -")) %>%
  glimpse()
write_csv(microhabitat_data, "data/microhabitat-use-data-2018-2020.csv")

seining_data <- read_excel("data-raw/mandy-salmanid-habitat-monitoring/Seining Data/seining-weight-lengths-2018-2020.xlsx") %>%
  mutate(date = as.Date(date)) %>%
  glimpse()
write_csv(seining_data, "data/seining-weight-lengths-2018-2020.csv")

snorkel_index_data <- read_excel("data-raw/mandy-salmanid-habitat-monitoring/Snorkel Index Data/snorkel-index-data-2015-2020.xlsx") %>%
  mutate(date = as.Date(date), time = strftime(time, format = "%H:%M:%S"),
         comments = str_remove_all(comments, ",")) %>%
  glimpse()
write_csv(snorkel_index_data, "data/snorkel-index-data-2015-2020.csv")

