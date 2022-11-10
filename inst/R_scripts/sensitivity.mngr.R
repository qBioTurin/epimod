library(parallel)
library(epimod)
library(ggplot2)
library(tidyr)
library(dplyr)

# Utility function
chk_dir <- function(path){
	pwd <- basename(path)
	return(paste0(file.path(dirname(path),pwd, fsep = .Platform$file.sep), .Platform$file.sep))
}
# Read commandline arguments
args <- commandArgs(TRUE)
cat(args)
param_fname <- args[1]

# Load parameters
params <- readRDS(param_fname)

# Load seed and previous configuration, if required.

if(is.null(params$seed)){
	# Save initial seed value
	params$seed <- paste0(params$out_dir, "seeds-", params$out_fname, ".RData")

	timestamp <- as.numeric(Sys.time())
	set.seed(kind = "Super-Duper", seed = timestamp)

	init_seed <- runif(min = 1, max = .Machine$integer.max, n = 1)
	extend_seed <- init_seed
	n <- 1

	save(init_seed, extend_seed, n, file = params$seed)
}else{
	load(params$seed)
	if(params$extend){
		# We want to extend a previous experiment
		assign(x = ".Random.seed", value = extend_seed, envir = .GlobalEnv)
		load(paste0(params$out_dir, params$out_fname, ".RData"))
	}
	else{
		n <- 1
	}
}

if(!params$extend){
	set.seed(kind = "Mersenne-Twister", seed = init_seed)
}


folder_trace = paste0("/home/docker/data/",basename(params$folder_trace) )
# Save final seed
extend_seed <- .Random.seed
### NEW ###
# Choose where and how to run parallel
if(params$n_config >= params$parallel_processors)
{
	# Run configurations in parallel
	config_processors <- params$parallel_processors
	# if there are multiple run for each configuration, then run them one after the other
	run_processors <- 1
} else {
	# Run configurations in parallel
	config_processors <- params$n_config
	run_processors <- 1
}

# List all the traces in the output directory
# if(!is.null(params$files$distance_measure_fname))
if(!is.null(params$distance_measure) && !is.null(param_fname))
{
	# Create a cluster
	cl <- makeCluster(config_processors,
										type = "FORK",
										# outfile = paste0(params$out_fname,".log"),
										port = 11000)
	# Save session's info
	clusterEvalQ(cl, sessionInfo())
	rank <- parLapply(cl,
										list.files(
											path = folder_trace,
											pattern =  "(-[0-9]+)+.trace"
										),
										tool.distance,
										out_dir = params$out_dir,
										# distance_measure_f_name = params$files$distance_measure_fname,
										distance_measure = params$distance_measure,
										reference_data = params$files$reference_data,
										function_fname = params$file$functions_fname )
	stopCluster(cl)
	# Sort the rank ascending, according to the distance computed above.
	rank <- do.call("rbind", rank)
	rank <- rank[order(rank$measure),]
	save(rank, file = paste0(params$out_dir,"ranking_",params$out_fname,".RData"))
}

### NEW ###
n <- n + params$n_config
save(init_seed, extend_seed, n, file = params$seed)

# if(!is.null(params$files$target_value_fname))
if(!is.null(params$target_value)  && !is.null(param_fname) )
{
	# Load external function to compute prcc
	source("/usr/local/lib/R/site-library/epimod/R_scripts/sensitivity.prcc.R")

	prcc <- sensitivity.prcc(config = params$config,
													 # target_value_fname = params$files$target_value_fname,
													 functions_fname = params$file$functions_fname,
													 target_value = params$target_value,
													 i_time = params$i_time,
													 s_time = params$s_time,
													 f_time = params$f_time,
													 out_fname = params$out_fname,
													 out_dir = params$out_dir,
													 folder_trace = params$folder_trace,
													 out_fname_analysis =  params$out_fname_analysis,
													 parallel_processors = params$parallel_processors)
	# Plot PRCC
	# Get the parameter names and the total number of parameters
	prcc_frame = prcc$PRCC %>% gather(-Time,key = "Param", value = "PRCC") %>% na.omit()
	# names_param= names(prcc$PRCC)
	# n_params = length(names_param)
	# Setup time
	# time <- seq(from = params$i_time, to = params$f_time, by = params$s_time)
	# Modify the prcc data structure to ease the plotting
	# prcc_frame <- lapply(c(1:n_params),function(x){
	#     return(data.frame(PRCC = matrix(prcc$PRCC[,x], ncol = 1),
	#                       Param = matrix(rep(names_param[x],length(prcc$PRCC[,x])), ncol = 1),
	#                       Time = matrix(time, ncol = 1)))
	#     })
	# prcc_frame <- do.call("rbind",prcc_frame)
	plt <- ggplot(prcc_frame)+
		geom_line(aes(x=Time,y=PRCC,group=Param,col=Param)) +
		ylim(-1,1) +
		xlab("Time")+
		ylab("PRCC")+
		theme_bw() +
		geom_rect(
			mapping=aes(xmin=-Inf, xmax=Inf, ymin=-.2, ymax=.2),
			alpha=0.001961,
			fill="yellow")
	ggsave(plot = plt,filename = paste0(params$out_dir,"prcc_",params$out_fname,".pdf"),dpi = 760)
	# Get final time
	save(prcc, plt, file = paste0(params$out_dir,"prcc_",params$out_fname,".RData"))
}
