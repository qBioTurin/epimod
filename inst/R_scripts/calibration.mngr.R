library(GenSA)
library(epimod)
library(parallel)

calibration.worker <- function(id, config, params, seed)
{
  print("[calibration.worker] Starts with parameters:")
  print(paste0("[calibration.worker] - id ", id))
  print(paste0("[calibration.worker] - config ", config))
  print(paste0("[calibration.worker] - seed ", seed))
  print(paste0("[calibration.worker] - params ", params))
  # Setup simulation's environment
  experiment.env_setup(id = id,
                       files = params$files,
                       dest_dir = params$run_dir,
                       config = config)
  # Store the current working direrctory
  pwd <- getwd()
  # Change current directory to the run_dir parameter
  setwd(paste0(params$run_dir, id))
  print("[calibration.worer] Generating command template")
  # Generate the appropriate command to run on the Docker
  cmd <- experiment.cmd(solver_fname = params$files$solver_fname,
                        solver_type = params$solver_type,
  											seed = seed,
                        taueps = params$taueps,
                        timeout = params$timeout)
  print("[calibration.worer] Done generating command template")
  print("[calibration.worer] Starting simulations..")
  experiment.run(base_id = id,
                 cmd = cmd,
                 i_time = params$i_time,
                 f_time = params$f_time,
                 s_time = params$s_time,
                 n_run = 1,
                 event_times = params$event_times,
                 event_function = params$event_function,
                 parallel_processors = params$processors,
                 out_fname = params$out_fname)
  print("[calibration.worer] Simulation done!")
  # Set-up the result's file name
  # fnm <- paste0(params$out_fname,"-",id,".trace")
  print(paste0("[calibration.worer] Returning file name: ", unlist(list.files(pattern = paste0(params$out_fname,"(-[0-9]+){1}(-[0-9]+)+(.trace){1}")))))
  fnm <- unlist(list.files(pattern = paste0(params$out_fname,
  										  "(-[0-9]+){1}(-[0-9]+)+(.trace){1}")))
  # Clear the simulation's environment
  experiment.env_cleanup(id = id,
                         run_dir = params$run_dir,
                         out_fname = params$out_fname,
                         out_dir = params$out_dir)
  # Restore the previous working directory
  setwd(pwd)
  return(paste0(params$out_dir,fnm))
}

objfn <- function(x, params, cl, seed) {
	# Generate a new configuration using the configuration provided by the optimization engine
	id <- length(list.files(path = params$out_dir, pattern = ".trace")) + 1
	# Generate the simulation's configuration according to the provided input x
	config <- experiment.configurations(n_config = 1,
										parm_fname = params$files$functions_fname,
										parm_list = params$files$parameters_fname,
										out_dir = params$out_dir,
										out_fname = params$out_fname,
										ini_vector = x,
										ini_vector_mod = params$ini_vector_mod)
	# Solve n_run instances of the model
	print("[objfn] Calling calibration.worer")
	cnt <- get(x = "counter", envir = .GlobalEnv)
	curr_seed = seed + cnt
	assign(x = "counter", value = cnt + 1, envir = .GlobalEnv)
	# traces_name <- parLapply(cl,
	# 						 c(paste0(id,"-",c(1:params$n_run))),
	# 						 calibration.worker,
	# 						 config = config,
	# 						 params = params,
	# 						 seed = curr_seed)
	### DEBUG ###
	traces_name <- lapply(c(paste0(id,"-",c(1:params$n_run))),
						  calibration.worker,
						  config = config,
						  params = params,
						  seed = curr_seed)
	### DEBUG ###
	print("[objfn] Done calibration.worer")
	# Append all the solutions in one single data.frame
	print("[objfn] Settling files...")
	print(traces_name)
	traces <- lapply(traces_name,function(x){
		print(paste0("[objfn] reading file", x))
		tr <- read.csv(file = x,
					   sep = "")
		file.remove(x)
		return(tr)
	})
	traces <- do.call("rbind", traces)
	write.table(traces,
				file = paste0(params$out_dir,
							  params$out_fname,
							  "-",
							  id,
							  ".trace"),
				sep = " ",
				col.names = TRUE,
				row.names = FALSE,
				append = FALSE)
	print("[objfn] done settling files!")
	# Compute the score for the current configuration
	source(params$files$distance_measure_fname)
	print("[objfn] Computing distance")
	distance <- do.call(params$distance_measure, list(t(read.csv(file = params$files$reference_data, header = FALSE, sep = "")), traces))
	# Write header to the file
	optim_trace_fname <- paste0(params$out_dir,params$out_fname,"_optim-config.csv")
	if(!file.exists(optim_trace_fname)) {
		nms <- c("distance", "id", paste0("optim_v-",c(1:length(x))))
		cat(unlist(nms),"\n", file = optim_trace_fname)
	}
	cat(unlist(c(distance,id, x)),"\n", file = optim_trace_fname ,append=TRUE)
	print("[objfn] Done computing distance")
	return(distance)
}

# Utility function
chk_dir<- function(path){
    pwd <- basename(path)
    return(paste0(file.path(dirname(path),pwd, fsep = .Platform$file.sep), .Platform$file.sep))
}

# Read commandline arguments (i.e. the location of the parameters list)
args <- commandArgs(TRUE)
cat(args)
params_fname <- args[1]
# Read the parameters list
params <- readRDS(params_fname)

# Define a variable counter in the .GlobalEnv.
counter <- 0
# This variable will be used to trace the number o f
# assign(x = "counter", value = 0, envir = .GlobalEnv)
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

# set.seed(kind = "Mersenne-Twister", seed = init_seed)
# .GlobalEnv.counter <- 1

# Copy files to the run directory
experiment.env_setup(files = params$files,
                     dest_dir = params$run_dir)
# Create a cluster
print(paste0("[calibration.mngr] Availabe processors: ", params$processors))
cl <- makeCluster(spec = params$processors,
                  type = "FORK")
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
ctl$seed <- init_seed + .GlobalEnv.counter
.GlobalEnv.counter <- .GlobalEnv.counter + 1

ret <- GenSA(par=params$ini_v,
             fn=objfn,
             upper=params$ub_v,
             lower=params$lb_v,
             control = ctl,
             params = params,
             cl = cl,
						 seed = init_seed)

stopCluster(cl)
# Save the output of the optimization problem to file
save(ret, file = paste0(params$out_dir,params$out_fname,"_optim.RData"))
