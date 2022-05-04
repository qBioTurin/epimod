library(parallel)
library(epimod)

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

if(is.null(params$files$parameters_fname)
   && is.null(params$files$functions_fname)
   && is.null(params$ini_v))
{
    params$config = NULL
} else {
    # Generate configuration
    params$config <- experiment.configurations(n_config = params$n_config,
                                              parm_fname = params$files$functions_fname,
                                              parm_list = params$files$parameters_fname,
                                              out_dir = chk_dir(params$out_dir),
                                              out_fname = params$out_fname,
                                              extend = params$extend,
                                              ini_vector = params$ini_v,
                                              ini_vector_mod = params$ini_vector_mod,
    																					config = config)
}
saveRDS(params,  file = paste0(param_fname), version = 2)

### NEW ###
print("[model.mngr] Generating command template")

# Choose where and how to run parallel
if(params$n_config > params$n_run)
{
	if(params$n_config >= params$parallel_processors)
	{
		# Run configurations in parallel
		config_processors <- params$parallel_processors
		# if there are multiple run for each configuration, then run them one after the other
		run_processors <- 1
	}
	else
	{
		# Run configurations in parallel
		config_processors <- params$n_config
		if(params$n_run > 1 && params$n_run < params$parallel_processors - params$n_config) {

			# If there are enough processors, run in parallel the configuration runs
			run_processors = floor((params$parallel_processors - params$n_config)/params$n_run)
		}
		else {
			run_processors = 1
		}
	}
} else {
	if(params$n_run >= params$parallel_processors)
	{
		# Run configurations one after the other
		config_processors <- 1
		# Run in parallel the configuration runs
		run_processors <- params$parallel_processors
	}
	else
	{
		# Execute configurations runs in parallel
		run_processors <- params$n_run
		if(params$n_config > 1 && params$n_config < params$parallel_processors - params$n_run) {
			# If there are enough processors, run in parallel the some configurations
			config_processors = floor((params$parallel_processors - params$n_run)/params$n_config)
		}
		else {
			config_processors = 1
		}
	}
}
run_processors <- 1
# Create a cluster
cl <- makeCluster(config_processors,
									type = "FORK")
# Save session's info
clusterEvalQ(cl, sessionInfo())


parLapply( cl = cl,
					 #X = c(1:params$n_config),
					 X = c(n:(n+params$n_config-1)),
					 fun = function(X, params, seed, parallel_processors)
					 {
					 	if(length(params$event_times) != 0)
					 	{
					 		i_s = seed + (X - 1)*(params$n_run * length(params$event_times)) #i_s = seed + (n-1)*params$n_config*params$n_run + ((X - 1)*(params$n_run * length(params$event_times))) ??
					 	} else {
					 		i_s = seed + (X - 1)*params$n_run # i_s = seed + (n-1)*params$n_config*params$n_run + ((X - 1)*params$n_run) ??
					 	}
					 	mngr.worker(id = X, solver_fname = params$files$solver_fname,
					 							solver_type = params$solver_type, taueps = params$taueps,
					 							i_time = params$i_time, f_time = params$f_time,
					 							s_time = params$s_time, n_run = params$n_run,
					 							timeout = params$timeout, run_dir = params$run_dir,
					 							out_fname = params$out_fname, out_dir = params$out_dir,
					 							seed = i_s, event_times = params$event_times,
					 							event_function = params$event_function,
					 							files = params$files, config = params$config,
					 							parallel_processors = parallel_processors)
					 },
					 params = params,
					 seed = init_seed,
					 parallel_processors = run_processors)
# Print all the output to the stdout
# system(paste0("cat ", params$out_fname,".log >&2"))
# unlink(x = paste0(params$out_fname,".log"), force = TRUE)

# lapply(X = c(1:params$n_config),
# 			 FUN = function(X, params, seed, parallel_processors)
# 		 	 {
# 			 	if(length(event_times) != 0)
# 		 		{
# 			 		i_s = seed + (X - 1)*(n_run * length(event_times))
# 		 		} else {
# 		 			i_s = seed + (X - 1)*n_run
# 	 			}
# 			 	mngr.worker(id = X, solver_fname = params$files$solver_fname,
# 							solver_type = params$solver_type, taueps = params$taueps,
# 							i_time = params$i_time, f_time = params$f_time,
# 							s_time = params$s_time, n_run = params$n_run,
# 							timeout = params$timeout, run_dir = params$run_dir,
# 							out_fname = params$out_fname, out_dir = params$out_dir,
# 							seed = i_s, event_times = params$event_times,
# 							event_function = params$event_function,
# 							files = params$files, config = params$config,
# 							parallel_processors = parallel_processors)
# 		 		}
# 				params = params,
# 				seed = init_seed,
# 				parallel_processors = run_processors)
stopCluster(cl)

# Save final seed
extend_seed <- .Random.seed
n <- n + params$n_config
save(init_seed, extend_seed, n, file = params$seed)

file.copy(from = params$target_value_fname, to = params$run_dir)
