library(GenSA)
library(epimod)

objfn <- function(x, params, seed) {
	# Generate a new configuration using the configuration provided by the optimization engine
	# Generate the simulation's configuration according to the provided input x
	config <- experiment.configurations(n_config = 1,
																			parm_fname = params$files$functions_fname,
																			parm_list = params$files$parameters_fname,
																			out_dir = params$out_dir,
																			out_fname = params$out_fname,
																			ini_vector = x)
	# Solve n_run instances of the model
	print("[objfn] Calling calibration.worer")
	curr_seed <- seed + counter

	print(paste0("[objfn] Parameter n_run ", params$n_run))
	traces_name <- mngr.worker(id = 0,
														 solver_fname = params$files$solver_fname,
														 solver_type = params$solver_type,
														 taueps = params$taueps,
														 i_time = params$i_time,
														 f_time = params$f_time,
														 s_time = params$s_time,
														 n_run = params$n_run,
														 timeout = params$timeout,
														 run_dir = params$run_dir,
														 out_fname = params$out_fname,
														 out_dir = params$out_dir,
														 seed = curr_seed,
														 event_times = params$event_times,
														 event_function = params$event_function,
														 files = params$files,
														 config = config,
														 parallel_processors = params$parallel_processors)
	traces_name <- file.path(params$out_dir, traces_name)
	print(paste0("[objfn] Counter ", counter))
	print(paste0("[objfn] File ", traces_name))
	print(paste0("[objfn] Renaming output file in ", gsub(pattern = "(-0.trace)",
																								 replacement = paste0("-", (counter-1), ".trace"),
																								 x = traces_name)))
	file.rename(traces_name, gsub(pattern = "(-0.trace)",
																replacement = paste0("-", (counter-1), ".trace"),
																x = traces_name))
	traces_name <- gsub(pattern = "(-0.trace)",
											replacement = paste0("-", (counter-1), ".trace"),
											x = traces_name)
	print("[objfn] Done calibration.worer")
	# Append all the solutions in one single data.frame
	print(paste0("[objfn] Settling files...", traces_name))
	# traces <- read.csv(file = traces_name,sep = "")
	print("[objfn] done settling files!")
	# Compute the score for the current configuration
	# source(params$files$distance_measure_fname)
	print("[objfn] Computing distance")
	# distance <- do.call(params$distance_measure,
	# 										list(t(read.csv(file = params$files$reference_data,
	# 																		header = FALSE,
	# 																		sep = "")),
	# 												 traces))
	distance <- do.call("tool.distance",
											list(id = basename(traces_name),
													 out_dir = params$out_dir,
													 distance_measure = params$distance_measure,
													 reference_data = params$files$reference_data,
													 function_fname = params$files$functions_fname))
	# Write header to the file
	optim_trace_fname <- paste0(params$out_dir,params$out_fname,"_optim-config.csv")
	if(!file.exists(optim_trace_fname)) {
		nms <- c("distance", "id", paste0("optim_v-",c(1:length(x))))
		cat(unlist(nms),"\n", file = optim_trace_fname)
	}
	cat(unlist(c(distance[[1]],(counter-1), x)),"\n", file = optim_trace_fname ,append=TRUE)
	print("[objfn] Updating counter..")

	if(length(params$event_times) != 0)
	{
		counter <<- counter+length(params$event_times)
	} else {
		counter <<- counter+1
	}
	print("[objfn] Done computing distance")
	return(distance[[1]])
}

# Utility function
chk_dir <- function(path){
    pwd <- basename(path)
    return(paste0(file.path(dirname(path),pwd, fsep = .Platform$file.sep), .Platform$file.sep))
}
# Read commandline arguments
args <- commandArgs(TRUE)
cat(args)
params_fname <- args[1]
# Load parameters
params <- readRDS(params_fname)

# Define a variable counter in the .GlobalEnv.
counter <- 0
# Load seed and previous configuration, if required.
if(is.null(params$seed)){
	# Save initial seed value
	params$seed <- paste0(params$out_dir, "seeds-", params$out_fname, ".RData")

	timestamp <- as.numeric(Sys.time())
	set.seed(kind = "Super-Duper", seed = timestamp)

	init_seed <- runif(min = 1, max = .Machine$integer.max, n = 1)

	save(init_seed, file = params$seed)
}else{
	load(params$seed)
}

set.seed(kind = "Mersenne-Twister", seed = init_seed)
counter <- 1

# Copy files to the run directory
experiment.env_setup(files = params$files,
                     dest_dir = params$run_dir)
# Call GenSA with init_vector as initial condition, upper_vector and lower_vector as boundaries conditions.
ctl <- list()
if(!is.null(params$max.call))
{
    ctl$max.call <- params$max.call
}
if(!is.null(params$threshold.stop))
{
    ctl$threshold.stop <- params$threshold.stop
}
if(!is.null(params$max.time))
{
    ctl$max.time <- params$max.time
}
ctl$seed <- init_seed + counter
counter <- counter + 1

# print("[calibration.mngr] Generating command template")
# params$cmd <- experiment.cmd(solver_fname = params$files$solver_fname,
# 														 solver_type = params$solver_type,
# 														 taueps = params$taueps,
# 														 timeout = params$timeout)
# print("[calibration.mngr] Done generating command template")

ret <- GenSA(par=params$ini_v,
						 fn=objfn,
						 upper=params$ub_v,
						 lower=params$lb_v,
						 control = ctl,
						 params = params,
						 seed = init_seed + counter)
# Save the output of the optimization problem to file
save(ret, file = paste0(params$out_dir,params$out_fname,"_optim.RData"))
