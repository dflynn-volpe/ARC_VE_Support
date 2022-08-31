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

# Run as scenarios ----
# Using 'manual scenarios' 
if(!dir.exists('VERSPM-scenarios-ms')){
  # Say 'yes' at prompt
  installModel("VERSPM",var="scenarios-ms") 
}

# This should work! ARC-Scenarios should have the same structure as VERSPM-scenarios-ms, but this returns an error. Compare the setup of ARC-Scenarios with the VERSPM-scenario-ms, paying attention to the details in teh various visioneval.cnf files, including at each stage and in the scenarios directory.
arcScenarios <- openModel('ARC-Scenarios')

modelPath = 'ARC-Scenarios'

# Content of openModel
# function (modelPath = "", log = "error") 
# {
#   if (missing(modelPath) || !nzchar(modelPath)) {
#     return(dir(file.path(getRuntimeDirectory(), visioneval::getRunParameter("ModelRoot"))))
#   }
#   else {
#     if (!is.null(log)) 
#       initLog(Save = FALSE, Threshold = log, envir = new.env())
#     return(VEModel$new(modelPath = modelPath))
#   }
# }


# Content of VEModel$new


# problem is in loadConfiguration?
# https://github.com/VisionEval/VisionEval-Dev/blob/8205169358a87a412c40e57176ec73f7600eeddf/sources/framework/visioneval/R/environment.R#L616

# Where params_ls comes from ve.model.configure
# Returns empty list 
Param_ls <- getSetup() # runtime configuration

# Also returns empty list
loadedParam_ls = visioneval::loadConfiguration(ParamDir=modelPath)

modelParam_ls <- visioneval::mergeParameters(Param_ls,loadedParam_ls) # override runtime parameters
# Still empty

modelName <- basename(modelPath)

modelParam_ls <- visioneval::addRunParameter(Param_ls=modelParam_ls,Source="VEModel::findModel",ModelDir=modelPath)
if ( ! "ResultsDir" %in% names(modelParam_ls) ) {
  # Load default parameter or get from larger runtime environment
  modelParam_ls <- visioneval::addRunParameter(
    Param_ls=modelParam_ls,
    visioneval::getRunParameter("ResultsDir",Param_ls=Param_ls)
  )
}

# https://github.com/VisionEval/VisionEval-Dev/blob/ea11ac212e0d5587dd684fafbd2258132be78cd1/sources/framework/VEModel/R/models.R#L276 

# We want to be able to do the following
arcScenarios$run()


example_sc <- openModel('VERSPM-scenarios-ms(1)')



example_sc$run()

# 

installModel('VERSPM', var = 'pop')
