# Contents of ve.model.configure

self=private=NULL # To avoid R6 class "undefined global" errors
modelPath = 'ARC-Scenarios'
fromFile=TRUE

# --- helpers
writeLog <- function(Msg = "", Level="NONE", Logger="") {
  noLevel <- ( missing(Level) || ! (Level <- toupper(Level) ) %in% log.threshold )
  if ( noLevel ) Level <- "FATAL"
  if ( missing(Msg) || length(Msg)==0 || ! nzchar(Msg) ) {
    message(
      "writeLog(Msg,Level,Logger): No message supplied\n",
      "Available Log Levels:\n",
      paste(log.threshold,collapse=", ")
    )
  } else {
    # Pick the logger
    if ( ! is.character(Logger) || ! nzchar(Logger) ) {
      Logger <- if ( which(log.threshold==Level) >= which(log.threshold=="WARN") ) "stderr" else "ve.logger"
    }
    # Pick the log format 
    if ( noLevel ) {
      on.exit(quote(futile.logger::flog.layout( log.layout.visioneval, name=Logger )))
      futile.logger::flog.layout( log.layout.simple, name=Logger )
    }
    for ( m in Msg ) {
      log.function[[Level]](m,name=Logger)
    }
  }
  invisible(Msg)
}
cullInputPath <- function(InputPath,modelInputPath=NULL) {
  # Remove any element of InputPath that is "" or "."
  InputPath <- InputPath[ nzchar(InputPath) & InputPath != "." ]
  
  if ( ! is.null(modelInputPath) ) {
    # modelInputPath is the InputPath associated with the model, ahead of the stages
    # always make sure those elements come last
    writeLog("Reordering modelInputPath",Level="debug")
    writeLog(paste("Model InputPath:",modelInputPath),Level="debug")
    modelPathLocations <- which(InputPath %in% modelInputPath)
    writeLog(paste("Model InputPath present to cull:",paste(modelPathLocations,collapse=",")),Level="debug")
    InputPath <- InputPath[ - modelPathLocations ]
  }
  
  # Normalize remaining InputPath elements, if any, and remove duplicates
  
  if ( length(InputPath) > 0 ) {
    # Don't cull if there is no stage-specific input path
    writeLog(paste("Culling Input Path:\n",paste(InputPath,collapse="\n")),Level="debug")
    InputPath <- unique(normalizePath(InputPath,winslash="/",mustWork=FALSE))
  }
  
  if ( ! is.null(modelInputPath) ) {
    InputPath <- c(InputPath,modelInputPath)
  }
  
  InputPath <- InputPath[dir.exists( InputPath )]
  writeLog(paste("InputPath length after culling:",length(InputPath)),Level="debug")
  
  return(InputPath)
}


# ---- 


if ( missing(modelPath) || ! is.character(modelPath) ) {
  modelPath <- self$modelPath
}

self$modelPath <- modelPath;

# Load any configuration available in modelPath (on top of ve.runtime base configuration)
Param_ls <- getSetup() # runtime configuration
if ( fromFile || is.null(self$loadedParam_ls) ) {
  self$loadedParam_ls <- visioneval::loadConfiguration(ParamDir=modelPath)
} # if NOT fromFile, use existing loadedParam_ls to rebuild (may have in-memory changes)

modelParam_ls <- visioneval::mergeParameters(Param_ls,self$loadedParam_ls) # override runtime parameters
if ( "Model" %in% modelParam_ls ) {
  self$modelName <- modelParam_ls$Model
} else {
  self$modelName <- basename(modelPath) # may be overridden in run parameters
}

# Set up ModelDir and ResultsDir
modelParam_ls <- visioneval::addRunParameter(Param_ls=modelParam_ls,Source="VEModel::findModel",ModelDir=modelPath)
if ( ! "ResultsDir" %in% names(modelParam_ls) ) {
  # Load default parameter or get from larger runtime environment
  modelParam_ls <- visioneval::addRunParameter(
    Param_ls=modelParam_ls,
    visioneval::getRunParameter("ResultsDir",Param_ls=Param_ls)
  )
}

# Cache the results path (for saving query results that may span multiple stages)
self$modelResults <- normalizePath(
  file.path(
    self$modelPath,
    resultsDir <- visioneval::getRunParameter("ResultsDir",Param_ls=modelParam_ls)
  )
)
writeLog(paste("Model Results go in:",self$modelResults),Level="info")

# Check for LoadModel and LoadStage in model parameters
if ( "LoadModel" %in% names(modelParam_ls ) ) {
  writeLog("Processing LoadModel directive",Level="info")
  baseModel <- VEModel$new( modelPath=modelParam_ls$LoadModel )
  if ( baseModel$valid() ) {
    writeLog(paste("LoadModel =",baseModel$modelName),Level="info")
    if ( ! "LoadStage" %in% names(modelParam_ls) ) {
      loadStage <- names(baseModel$modelStages)[length(baseModel$modelStages)]
    } else loadStage <- modelParam_ls$LoadStage
    runPath <- baseModel$modelStages[[loadStage]]$RunPath
    modelParam_ls <- visioneval::addRunParameter(
      Param_ls=modelParam_ls,
      Source=attr("Source",modelParam_ls$LoadModel),
      LoadDatastoreName=file.path (
        runPath,
        baseModel$setting("DatastoreName",stage=loadStage)
      ),
      LoadDatastore=TRUE
    )
  } else {
    writeLog(paste("LoadModel present but invalid:",modelParam_ls$LoadModel),Level="warn")
    modelParam_ls <- visioneval::addRunParameter(
      Param_ls=modelParam_ls,
      Source=attr("Source",modelParam_ls$LoadModel),
      LoadDatastore=FALSE
    )
  }
}

# Process InputPath for overall model (culling directories for those actually exist)

# Find ModelDir/InputDir if that exists and make it InputPath
# If explicit InputPath in modelParam_ls, just use that
rootInputPath <- normalizePath(
  file.path(modelParam_ls$ModelDir,visioneval::getRunParameter("InputDir",Param_ls=modelParam_ls)),
  winslash="/",mustWork=FALSE
)
if ( "InputPath" %in% names(modelParam_ls) ) {
  # expand default InputPath if necessary
  inputPath <- modelParam_ls$InputPath
  if ( ! isAbsolutePath(inputPath) ) {
    inputPath <- normalizePath(
      file.path(
        modelParam_ls$ModelDir,
        inputPath
      )
    )
  }
  inputPath <- c( rootInputPath, inputPath )
} else {
  inputPath <- rootInputPath
}
# cull input path to keep only unique existing directories
inputPath <- cullInputPath(inputPath)
if ( length(inputPath) > 0 ) {
  modelParam_ls <- visioneval::addRunParameter(
    Param_ls=modelParam_ls,
    Source="VEModel::findModel",
    InputPath=inputPath
  )
  writeLog("Input Paths:",Level="info")
  for ( p in modelParam_ls$InputPath ) {
    writeLog(paste("Input Path:",paste("'",p,"'")),Level="info")
  }
}

# Locate ParamPath for overall model
# If it doesn't exist at the level of the model, could still set for individual stages
#   It makes the most sense to place ParamDir within ModelDir and use the same one
#   for each model stage (weird things will happen if different stages have different
#   defs).
if ( ! "ParamPath" %in% names(modelParam_ls) ) {
  ParamPath <- file.path(
    modelParam_ls$ModelDir,
    visioneval::getRunParameter("ParamDir",Param_ls=modelParam_ls)
  )
  if ( file.exists(ParamPath) ) {
    writeLog(paste("Setting ParamPath to",ParamPath),Level="info")
    modelParam_ls <- visioneval::addRunParameter(
      modelParam_ls,
      Source="VEModel::findModel",
      ParamPath=ParamPath
    )
  } else {
    writeLog("No ParamPath set yet.",Level="info")
  }
}

# Locate ModelScriptPath if it has not yet been set
if ( ! "ModelScriptPath" %in% names(modelParam_ls) ) {
  ScriptName <- visioneval::getRunParameter("ModelScript",Param_ls=modelParam_ls)
  ScriptsDir <- visioneval::getRunParameter("ScriptsDir",Param_ls=modelParam_ls)
  ModelScriptPath <- visioneval::getRunParameter("ModelScriptPath",Default=character(0),Param_ls=modelParam_ls)
  if ( length(ModelScriptPath)>0 && ! nzchar(ModelScriptPath) ) {
    # Not explicitly defined
    writeLog("Searching for ModelScriptPath",Level="info")
    for ( sdir in c(
      file.path(modelParam_ls$ModelDir,ScriptsDir),
      file.path(modelParam_ls$ModelDir)
    ) ) {
      ScriptPath <- file.path(sdir,ScriptName)
      if ( file.exists(ScriptPath) ) {
        ModelScriptPath <- ScriptPath
        break
      }
    }
    if ( length(ModelScriptPath)>0 ) {
      writeLog(paste("Found ModelScriptPath:",ModelScriptPath),Level="info")
    }
  }
}
if ( !is.null(ModelScriptPath) && length(ModelScriptPath)>0 ) {
  ModelScriptPath <- ModelScriptPath[1] # just use first found element
  writeLog(paste("Parsing ModelScriptPath:",ModelScriptPath),Level="info")
  if ( nzchar(ModelScriptPath) && file.exists(ModelScriptPath) ) {
    modelParam_ls <- visioneval::addRunParameter(
      modelParam_ls,
      Source="VEModel::findModel",
      ModelScriptPath=ModelScriptPath,
      ParsedScript=visioneval::parseModelScript(ModelScriptPath)
    )
  }
} else {
  writeLog("No ModelScriptPath; Must set in stages",Level="info")
  modelParam_ls[["ModelScriptPath"]] <- NULL
  # Don't keep ModelScriptPath if there is no ModelScript there!
}

# Save the model's RunParam_ls
self$RunParam_ls <- modelParam_ls
writeLog(paste("Model RunParam_ls contains:"),Level="info")
writeLog(paste(names(self$RunParam_ls),collapse=", "),Level="info")

# Locate model stages
if ( fromFile || is.null(self$modelStages) ) {
  writeLog("Locating model stages",Level="info")
  self$modelStages <- NULL
  if ( ! "ModelStages" %in% names(self$RunParam_ls) ) {
    # In general, to avoid errors with random sub-directories becoming stages
    #  it is best to explicitly set ModelStages in the model's main visioneval.cnf
    writeLog("Implicit model stages from directories",Level="info")
    stages <- list.dirs(modelPath,full.names=FALSE,recursive=FALSE)
    structuralDirs <- c(
      self$setting("DatastoreName"),
      self$setting("QueryDir"),
      self$setting("ScriptsDir"),
      self$setting("InputDir"),
      self$setting("ParamDir"),
      self$setting("ScenarioDir"),
      self$setting("ResultsDir")
    )
    stages <- stages[ ! stages %in% structuralDirs ]
    stages <- stages[ grep(paste0("^",self$setting("ArchiveResultsName")),stages,invert=TRUE) ]
    stages <- c(".",stages) # Add model root directory
    writeLog(paste0("Stage directories:\n",paste(stages,collapse=",")),Level="info")
    modelStages <- lapply(stages,
                          function(stage) {
                            stageParam_ls <- list(
                              Dir=stage,                           # Relative to modelPath
                              Name=sub("^\\.$",basename(self$modelPath),stage),  # Will only change root directory
                              Path=self$modelPath          # Root for stage
                            )
                            VEModelStage$new(
                              Name = stageParam_ls$Name,
                              Model = self,
                              stageParam_ls=stageParam_ls          # Base parameters from model
                            )
                          }
    )
  } else {
    writeLog("Parsing ModelStages setting from model",Level="info")
    modelStages <- lapply(names(self$RunParam_ls$ModelStages), # Use pre-defined structures
                          # At a minimum, must provide Dir or Config
                          function(stage) {
                            obj <- self$RunParam_ls$ModelStages[[stage]] # Get the stageParam_ls structure
                            writeLog(paste("Model Stage:",stage),Level="info")
                            VEModelStage$new(
                              Name=stage,
                              Model=self,
                              stageParam_ls=obj
                            )
                          }
    )
  }
} else {
  # all stage edits in memory should be made to stage$RunParam_ls, not stage$loadedParam_ls
  # stage changes mediated through their files should be reloaded with fromFile=TRUE
  writeLog("Existing Model Stages",Level="info")
  modelStages <- self$modelStages
}

# Call the modelStages by their Names
names(modelStages) <- stageNames <- sapply(modelStages,function(s)s$Name)
if ( length(stageNames) > 0 ) {
  writeLog(paste("Model Stages:",stageNames,collapse=","),Level="info")
}

# Done with base stages (except for initializing below after scenarios are loaded)
self$modelStages <- modelStages

# Load any scenarios from subfolder
scenarios <- self$scenarios(fromFile=fromFile)  # re-create VEModelScenario object from file
scenarioStages <- scenarios$stages()            # scenario stages may be an empty list

if ( length(scenarioStages) > 0 ) { # some scenarios are defined
  # It is possible for a model to ONLY have scenarios (if they are "manually" created)
  # Each "scenario" in that case must be a complete model run
  # Usually in such cases, it may be easier just to make them Reportable modelStages
  if ( ! is.list(self$modelStages) ) {
    if ( is.list(scenarioStages) && length(scenarioStages) > 0 ) {
      self$modelStages <- scenarioStages
    } else {
      # If no stages remain, model is invalid
      writeLog("No model stages found!",Level="error")
      return(self)
    }
  } else if ( is.list(scenarioStages) && length(scenarioStages) > 0 ) {
    self$modelStages <- c( self$modelStages, scenarioStages )
  }
}

# Link the stages
writeLog("Initializing Model Stages",Level="info")
self$modelStages <- self$initstages( self$modelStages )

#   # Not clear this is still needed
#   # Check for scenario element consistency (this should be taken care
#   # of automatically when ScenarioElements are loaded and built).
#   stageNames <- names(self$modelStages)
#   checkElements <- function(base,check) {
#     return(
#       length(base)>0 &&
#       ( length(base) == length(check) ) &&
#       ! is.null( names(base) ) &&
#       ! is.null( names(check) ) &&
#       all(names(base) %in% names(check))
#     )
#   }
#   scenarioElements <- character(0)
#   for ( s in seq_along(stageNames) ) {
#     stage <- self$modelStages[[s]]
#     if ( ! stage$Reportable ) next # only concerned about reportable stages
# 
#     elements <- stage$ScenarioElements
#     if ( ! checkElements( elements, self$setting("ScenarioElements",stageNames[s],defaults=FALSE) ) ) {
#       writeLog(paste("Inconsistent ScenarioElements within",stageNames[s]),Level="error")
#       browser()
#     }
#     if ( length(scenarioElements)==0 ) {
#       scenarioElements = elements
#     } else if ( ! checkElements( scenarioElements, elements ) ) {
#       writeLog(paste("Different ScenarioElements in",stageNames[s]),Level="error")
#       browser()
#     }
#   }
#   if ( length(scenarioElements)==0 ) {
#     writeLog("No Stages have ScenarioElements (visualizer is unavailable)!",Level="error")
#     browser()
#   }

# Update the model status
self$specSummary <- NULL # regenerate when ve.model.list is next called
self$updateStatus()

return(self)
}
