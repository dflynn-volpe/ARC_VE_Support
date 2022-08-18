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


# read in Dan's results.
files7 <- list.files("./data/ARC_001_007_Dan_Results/ARC007/") %>% 
  as.data.frame() %>% 
  filter(!grepl("metadata",.)) %>% 
  transmute(files = gsub("_2022-08-09_14-10-18.csv","",.))

files1 <- list.files("./data/ARC_001_007_Dan_Results/ARC001/") %>% 
  as.data.frame() %>% 
  filter(!grepl("metadata",.)) %>% 
  transmute(files = gsub("_2022-08-09_12-12-15.csv","",.))
  
DAN_007_Results <- list.files(path = "./data/ARC_001_007_Dan_Results/ARC007/",
                            recursive = TRUE,
                            pattern = "18.csv",
                            full.names = TRUE)%>% 
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
  filter(clean %in% files7$files) %>% 
  select(x) 

SEAN_007_Results <- SEAN_007_Results[["x"]] %>% 
  map(~read_csv(.))

## Had no idea how to do this in a filter...will ask Dan...
  # filter(grepl(paste(files7,collapse = "|"),x))



DAN_001_Results <- list.files(path = "./data/ARC_001_007_Dan_Results/ARC001/",
                              recursive = TRUE,
                              pattern = "15.csv",
                              full.names = TRUE) %>% 
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
  filter(clean %in% files1$files) %>% 
  select(x) 

SEAN_001_Results <- SEAN_001_Results[["x"]] %>% 
  map(~read_csv(.))

result_7_check <- pmap(list(DAN_007_Results,SEAN_007_Results),anti_join) 
result_1_check <- pmap(list(DAN_001_Results,SEAN_001_Results),anti_join) 

  