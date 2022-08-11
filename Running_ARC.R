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

# We want to be able to do the following
acrScenarios$run()
