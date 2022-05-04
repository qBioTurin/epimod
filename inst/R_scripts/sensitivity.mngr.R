library(parallel)
library(epimod)
library(ggplot2)

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
# Get functions name from file path
# if(!is.null(params$files$distance_measure_fname))
# {
#     distance_measure <- tools::file_path_sans_ext(basename(params$files$distance_measure_fname))
# }
# if(!is.null(params$files$target_value_fname))
# {
#     target_value <- tools::file_path_sans_ext(basename(params$files$target_value_fname))
#     file.copy(from = params$files$target_value_fname, to = params$run_dir)
# }

# Load seed and previous configuration, if required.
config <- list()
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

# Generate configuration
params$config <-experiment.configurations(n_config = params$n_config,
                                   parm_fname = params$files$functions_fname,
                                   parm_list = params$files$parameters_fname,
                                   out_dir = chk_dir(params$out_dir),
                                   out_fname = params$out_fname,
                                   extend = params$extend,
																	 config = config)
saveRDS(params,  file = paste0(param_fname), version = 2)

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

# Create a cluster
cl <- makeCluster(config_processors,
									type = "FORK",
									# outfile = paste0(params$out_fname,".log"),
									port = 11000)
# Save session's info
clusterEvalQ(cl, sessionInfo())

parLapply(cl = cl,
					X = c(n:(n+params$n_config-1)),
					fun = function(id, params, seed, parallel_processors)
					{
					 	if(length(params$event_times) != 0)
					 	{
					 		i_s = seed + (id - 1)*length(params$event_times)
					 	} else {
					 		i_s = seed + (id - 1)
					 	}
					 	mngr.worker(id = id, solver_fname = params$files$solver_fname,
					 							solver_type = params$solver_type,
					 							taueps = params$taueps,
					 							i_time = params$i_time,
					 							f_time = params$f_time,
					 							s_time = params$s_time,
					 							n_run = 1,
					 							timeout = params$timeout,
					 							run_dir = params$run_dir,
					 							out_fname = params$out_fname,
					 							out_dir = params$out_dir,
					 							seed = i_s,
					 							event_times = params$event_times,
					 							event_function = params$event_function,
					 							files = params$files,
					 							config = params$config,
					 							parallel_processors = parallel_processors)
					},
					params = params,
					seed = init_seed+1,
					parallel_processors = run_processors)

# Print all the output to the stdout
# system(paste0("cat ", params$out_fname,".log >&2"))
# unlink(x = paste0(params$out_fname,".log"), force = TRUE)

# lapply(X = c(1:params$n_config),
# 			 FUN = function(id, params, seed, parallel_processors)
# 			 {
# 					if(length(params$event_times) != 0)
# 					{
# 						i_s = seed + (id - 1)*length(params$event_times)
# 					} else {
# 						i_s = seed + (id - 1)
# 					}
# 					mngr.worker(id = id, solver_fname = params$files$solver_fname,
# 											solver_type = params$solver_type, taueps = params$taueps,
# 											i_time = params$i_time, f_time = params$f_time,
# 											s_time = params$s_time, n_run = 1,
# 											timeout = params$timeout, run_dir = params$run_dir,
# 											out_fname = params$out_fname, out_dir = params$out_dir,
# 											seed = i_s, event_times = params$event_times,
# 											event_function = params$event_function,
# 											files = params$files, config = params$config,
# 											parallel_processors = parallel_processors)
# 					},
# 					params = params,
# 					seed = init_seed,
# 					parallel_processors = run_processors)

# List all the traces in the output directory
# if(!is.null(params$files$distance_measure_fname))
if(!is.null(params$distance_measure) && !is.null(param_fname))
{
	rank <- parLapply(cl,
										list.files(path = params$out_dir,
															 pattern = paste0(params$out_fname, "(-[0-9]+)+")),
										tool.distance,
										out_dir = params$out_dir,
										# distance_measure_f_name = params$files$distance_measure_fname,
										distance_measure = params$distance_measure,
										reference_data = params$files$reference_data,
										function_fname = params$file$functions_fname)
	# Sort the rank ascending, according to the distance computed above.
	rank <- do.call("rbind", rank)
	rank <- rank[order(rank$measure),]
	save(rank, file = paste0(params$out_dir,"ranking_",params$out_fname,".RData"))
}
stopCluster(cl)
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
                             parallel_processors = params$parallel_processors)
    # Plot PRCC
    # Get the parameter names and the total number of parameters
    names_param= names(prcc$PRCC)
    n_params = length(names_param)
    # Setup time
    time <- seq(from = params$i_time, to = params$f_time, by = params$s_time)
    # Modify the prcc data structure to ease the plotting
    prcc_frame <- lapply(c(1:n_params),function(x){
        return(data.frame(PRCC = matrix(prcc$PRCC[,x], ncol = 1),
                          Param = matrix(rep(names_param[x],length(prcc$PRCC[,x])), ncol = 1),
                          Time = matrix(time, ncol = 1)))
        })
    prcc_frame <- do.call("rbind",prcc_frame)
    plt <- ggplot(prcc_frame, aes(x=Time/params$s_time))+
        geom_line(aes(y=PRCC,group=Param,col=Param)) +
        ylim(-1,1) +
        xlab("Time")+
        ylab("PRCC")+
        geom_rect(
            mapping=aes(xmin=-Inf, xmax=Inf, ymin=-.2, ymax=.2),
            alpha=0.001961,
            fill="yellow")
    ggsave(plot = plt,filename = paste0(params$out_dir,"prcc_",params$out_fname,".pdf"),dpi = 760)
    # Get final time
    save(prcc, plt, file = paste0(params$out_dir,"prcc_",params$out_fname,".RData"))
}
