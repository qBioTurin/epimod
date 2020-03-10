library(epimod)

# chk_dir<- function(path){
# 	pwd <- basename(path)
# 	return(paste0(file.path(dirname(path),pwd, fsep = .Platform$file.sep), .Platform$file.sep))
# }
# Read commandline arguments
# args <- commandArgs(TRUE)
# cat(args)
# param_fname <- args[1]
# Load parameters
# params <- readRDS(param_fname)
# Load seed and previous configuration, if required.
runApp(appDir = "~/data",
	   port = 8080
	   )
