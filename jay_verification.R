# Comparing Dan's results to Sean's results:
# Load packages
library("sf")
library("tmap")
library("readr")
library("dplyr")
library("ggplot2")
library("stringr")
library("glue")
library("dplyr")
library("purrr")
library("janitor")


# read 007 results
files <- list.files("./data/Results_Jay/ARCR001/") %>% 
  as.data.frame() %>% 
  filter(!grepl("metadata",.))%>% 
  transmute(files = gsub("_2022-07-19_12-41-37.csv","",.))

Jay_007_Results <- list.files(path = "./data/Results_Jay/ARCR007/",
                              recursive = TRUE,
                              pattern = "9.csv",
                              full.names = TRUE) %>%
  map(~read_csv(.))

DAN_007_Results <- list.files(path = "./data/ARC_001_007_Dan_Results/ARC007/",
                              recursive = TRUE,
                              pattern = "18.csv",
                              full.names = TRUE)%>% 
  as.data.frame() %>%
  clean_names() %>% 
  rowwise() %>% 
  mutate(extract = str_split(x,"/")[[1]][5],
         clean = str_replace(extract,"_2022-08-09_14-10-18.csv","")) %>% 
  filter(clean %in% files$files)%>% 
  select(x) %>% 
  pull(x) %>% 
  map(~read_csv(.))

SEAN_007_Results <- list.files(path = "./models/ARC007/results/output/Extract_2022-08-02_15-09-05/",
                               recursive = TRUE,
                               pattern = "7.csv",
                               full.names = TRUE) %>% 
  as.data.frame() %>%
  clean_names() %>% 
  rowwise() %>% 
  mutate(extract = str_split(x,"/")[[1]][7],
         clean = str_replace(extract,"_2022-08-01_16-42-07.csv","")) %>% 
  filter(clean %in% files$files) %>% 
  select(x) %>% 
  pull(x) %>% 
  map(~read_csv(.))


## Had no idea how to do this in a filter...will ask Dan...
# filter(grepl(paste(files7,collapse = "|"),x))

# read 001 results
Jay_001_Results <- list.files(path = "./data/Results_Jay/ARCR001/",
                              recursive = TRUE,
                              pattern = "7.csv",
                              full.names = TRUE) %>%
  map(~read_csv(.))

DAN_001_Results <- list.files(path = "./data/ARC_001_007_Dan_Results/ARC001/",
                              recursive = TRUE,
                              pattern = "15.csv",
                              full.names = TRUE) %>% 
  as.data.frame() %>%
  clean_names() %>% 
  rowwise() %>% 
  mutate(extract = str_split(x,"/")[[1]][5],
         clean = str_replace(extract,"_2022-08-09_12-12-15.csv","")) %>% 
  filter(clean %in% files$files)%>% 
  select(x) %>% 
  pull(x) %>% 
  map(~read_csv(.))

SEAN_001_Results <- list.files(path = "./models/ARC001/results/output/Extract_2022-08-04_12-11-10/",
                               recursive = TRUE,
                               pattern = "8.csv",
                               full.names = TRUE) %>% 
  as.data.frame() %>%
  clean_names() %>% 
  rowwise() %>% 
  mutate(extract = str_split(x,"/")[[1]][7],
         clean = str_replace(extract,"_2022-08-01_13-14-38.csv","")) %>% 
  filter(clean %in% files$files) %>% 
  select(x) %>% 
  pull(x) %>% 
  map(~read_csv(.))

# Double check with both of our results:

result_7_check <- pmap(list(Jay_007_Results,SEAN_007_Results),anti_join) 
result_1_check <- pmap(list(Jay_001_Results,SEAN_001_Results),anti_join) 

# Dan's zips did not have households, so limiting to just the first two elements.
result_7_check_dan <- pmap(list(Jay_007_Results[1:2],DAN_007_Results),anti_join) 
result_1_check_dan <- pmap(list(Jay_001_Results[1:2],DAN_001_Results),anti_join) 
