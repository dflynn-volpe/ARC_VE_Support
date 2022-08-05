# Running ARCs model

# Setup ----
# Downloaded fresh version of VisionEval from GitHub, VE-3.0-Installer-Windows-R4.1.3_2022-05-27.zip
# Change R version in RStudio to 4.1.3 if necessary

# Copy ARC input files from email 
# Turn into single model run scenarios by setting up .cnf and inputs... (Dan will add detail)

# Run models ----
# First, run the base scenario for 2015 and 2050
arc <- openModel('ARC001')

# arc$run()

# Now run scenario 7
arc7 <- openModel('ARC007')

# arc7$run()


# Query results ---

# Want 1. results by bzone, to also 
arc1 <- openModel('ARC001')
results1 <- arc1$results()
# results1$export()

arc7 <- openModel('ARC007')
results7 <- arc7$results()
# results7$export()

# Work with results ----

# # of trips, DVMT, # of transit trips, and Daily CO2e at Bzone level for now
# bzone_compile = vector()


# for(mods in c('arc1', 'arc7')){
#   
#   model = get(mods) # arc1 or arc7
#   
#   futureyear = model$loadedParam_ls$Years[2]
#   
#   outdir = file.path(model$modelPath, 'results', 'output')
#   
#   outputs <- dir(outdir)
#   
#   # take the first one if multiple
#   output = outputs[1]
#   output_date <- gsub('Extract_', '', output)
#   # Find the run date from the output
#   run_date <- stringr::str_extract(dir(file.path(outdir, output)), '\\d{4}-\\d{2}-\\d{2}_\\d{2}-\\d{2}-\\d{2}')
#   run_date <- unique(na.omit(run_date))
#   
#   bz_out = read.csv(file.path(outdir, output, paste0('_', futureyear, '_Bzone_', run_date, '.csv')))
#   
#   bzone_compile = rbind(bzone_compile, data.frame(Model = mods, bz_out))
# }

library("sf")
library("tmap")
library("readr")
library("dplyr")
library("ggplot2")
library("stringr")

Bzones <- read_sf("./data/Bzone/tl_2010_13_tract10.shp")
Azones <- read_sf("./data/Azone/tl_2010_13_county10.shp")

households_007_50 <- read_csv("./models/ARC007/results/output/Extract_2022-08-02_15-09-05/_2050_Household_2022-08-01_16-42-07.csv")
households_001_50 <- read_csv("./models/ARC001/results/output/Extract_2022-08-04_12-11-10/_2050_Household_2022-08-01_13-14-38.csv")

Bzone_007_50 <- households_007_50 %>% 
  group_by(Bzone) %>% 
  summarize_at(vars(contains("trip"),"Dvmt"), sum)

Bzone_001_50 <- households_001_50 %>% 
  group_by(Bzone) %>% 
  summarize_at(vars(contains("trip"),"Dvmt"), sum)

Azone_007_50 <- households_007_50 %>% 
  group_by(Azone) %>% 
  summarize_at(vars(contains("trip"),"Dvmt"), sum)

Azone_001_50 <- households_001_50 %>% 
  group_by(Azone) %>% 
  summarize_at(vars(contains("trip"),"Dvmt"), sum)

core <- c("DeKalb", "Fulton", "Clayton", "Cobb", "Gwinnett") %>% 
  toupper()
suburb <- c("Douglas", "Fayette", "Forsyth", "Henry", "Paulding", "Rockdale", "Walton") %>% 
  toupper()
rural <- c("Barrow", "Bartow", "Carroll", "Cherokee", "Coweta", "Hall", "Newton", "Spalding", "Dawson") %>% 
  toupper()

Azones_2050 <- Azones %>% 
  transmute(county_trim = word(NAMELSAD10,1),
            county_trim = toupper(county_trim)) %>% 
  left_join(Azone_001_50, by = c("county_trim"="Azone")) %>% 
  rename_at(vars(-county_trim,-geometry), ~ paste0(., '_001')) %>% 
  left_join(Azone_007_50, by = c("county_trim"="Azone")) %>%  
  rename_at(vars(-(1:8)), ~ paste0(., '_007'))  %>% 
  mutate(category = if_else(county_trim %in% core,"core",
                            if_else(county_trim %in% suburb,"suburb",
                                    if_else(county_trim %in% rural,"rural","NA"))))

ggplot(Azones_2050,aes(x=WalkTrips_001, y=WalkTrips_007, color=category)) + 
  geom_point() +
  geom_abline()
ggsave("./charts/walktrips.png")
ggplot(Azones_2050,aes(x=VehicleTrips_001, y=VehicleTrips_007, color=category)) + 
  geom_point() +
  geom_abline()
ggsave("./charts/vehicletrips.png")
ggplot(Azones_2050,aes(x=AveVehTripLen_001, y=AveVehTripLen_007, color=category)) + 
  geom_point()+
  geom_abline()
ggsave("./charts/avevehtriplen.png")
ggplot(Azones_2050,aes(x=BikeTrips_001, y=BikeTrips_007, color=category)) + 
  geom_point()+
  geom_abline()
ggsave("./charts/biketrips.png")
ggplot(Azones_2050,aes(x=Dvmt_001, y=Dvmt_007, color=category)) + 
  geom_point()+
  geom_abline()
ggsave("./charts/dvmt.png")
ggplot(Azones_2050,aes(x=TransitTrips_001, y=TransitTrips_007, color=category)) + 
  geom_point()+
  geom_abline()
ggsave("./charts/transittrips.png")

Azones_2050_long <- Azones_2050%>% 
  pivot_longer(cols =3:14,names_to = "Metric_Run",values_to = "Values") %>% 
  filter(Metric_Run != "Dvmt_001",
         Metric_Run != "Dvmt_007")



trip_maps <- tm_shape(Azones_2050_long) +
  tm_fill(col = "Values", palette = "YlOrRd")+
  tm_facets("Metric_Run")

tmap_save(trip_maps,"./charts/trip_maps.png")

dvmt_001 <- tm_shape(Azones_2050)+
  tm_fill(col = "Dvmt_001", palette = "YlOrRd")

tmap_save(dvmt_001,"./charts/dvmt_001.png")

dvmt_007 <- tm_shape(Azones_2050)+
  tm_fill(col = "Dvmt_007", palette = "YlOrRd")

tmap_save(dvmt_007,"./charts/dvmt_007.png")

# Can do this, but take the difference and map them
# do this for B Zones as well
# Add population metrics
# C02 equivalent emissions - "DailyCO2e"


