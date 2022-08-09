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




