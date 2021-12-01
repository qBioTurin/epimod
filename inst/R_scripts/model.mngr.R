library(parallel)
library(epimod)

# model.worker <- function(id,
#                          solver_fname, solver_type,taueps,
#                          i_time, f_time, s_time, n_run,
#                          timeout, run_dir, out_fname, out_dir, seed,
#                          event_times, event_function,
#                          files, config = NULL,
#                          parallel_processors, greed)
# {
# 	print("[analysis.worker] Starts with parameters:")
# 	print(paste0("[analysis.worker] - id ", id))
#   if (!is.null(config))
#   {
#   	print(paste0("[analysis.worker] - config ", config))
#     # Setup the environment
#     experiment.env_setup(id = id, files = files, config = config, dest_dir = run_dir)
#   }
#   else
#   {
#     # Handle simulations without parameters
#     dir.create(paste0(run_dir, id), recursive = TRUE, showWarnings = FALSE)
#     file.copy(from = solver_fname, to = paste0(run_dir, id))
#   }
# 	print(paste0("[analysis.worker] - seed ", seed))
# 	print(paste0("[analysis.worker] - params ", params))
#
#   # Change working directory to the one corresponding at the current id
#   pwd <- getwd()
#   setwd(paste0(run_dir,id))
#
#   print("[calibration.worer] Generating command template")
#   # Generate the appropriate command to run on the Docker
#   cmd <- experiment.cmd(solver_fname = solver_fname,
#   											solver_type = solver_type,
#   											taueps = taueps,
#   											timeout = timeout,
#   											seed = seed + id)
#   print("[calibration.worer] Done generating command template")
#   print("[calibration.worer] Starting simulations..")
#   if(n_run != 1)
#   {
#   	print("[analysis.worker] Creating subdirectories...")
#   	# setup the environment for each run
#   	fns <- list.files(recursive = FALSE)
#   	print(paste0("[analysis.worker] ", fns))
#   	lapply(X = c(1:n_run),
#   				 FUN = function(X, fns){
#   				 	dir.create(paste0(X))
#   				 	file.copy(from = fns,
#   				 						to = paste0(X, .Platform$file.sep, fns))
#   				 },
#   				 fns = fns)
#   	print("[analysis.worker] Done creating subdirectories")
#   	# Create a cluster
#   	cl <- makeCluster(parallel_processors,
#   										type = "FORK")
#   	# Launch simulations
#   	start_time <- Sys.time()
#   	parLapply(cl = cl,
#   						fun = function(X, cmd, i_time, f_time, s_time, event_times, event_function, out_fname, id){
#   							pwd <- getwd()
#   							setwd(paste0(X))
#   							print(paste0("[analysis.worker] Running simulation ", id, "-", X, "..."))
#   							experiment.run(id = X,
#   														 cmd = cmd,
#   														 i_time = i_time,
#   														 f_time = f_time,
#   														 s_time = s_time,
#   														 n_run = 1,
#   														 event_times = event_times,
#   														 event_function = event_function,
#   														 out_fname = paste0(out_fname,"-", id))
#   							print(paste0("[analysis.worker] Simulation ", id, "-", X, " done!"))
#   							setwd(pwd)
#   						},
#   						X = c(1:n_run),
#   						id = id,
#   						cmd = cmd,
#   						i_time = i_time,
#   						f_time = f_time,
#   						s_time = s_time,
#   						event_times = event_times,
#   						event_function = event_function,
#   						out_fname = out_fname)
#   	elapsed <-  Sys.time()-start_time
#   	print("[analysis.worker] Merging files..")
#   	# Get file names
#   	res <- list.files(pattern = ".trace",
#   										recursive = TRUE)
#   	# Merge all trace files in one
#   	lapply(X = res, function(X, outname)
#   		{
#   			# tr <- read.csv(paste0(run_dir, id, .Platform$file.sep, out_fname, "-", basename(X), ".trace"), sep = "")
#   			tr <- read.csv(X,
#   										 sep = "")
#   			if (!file.exists(outname)) {
#   				write.table(tr, file = outname, sep = " ", col.names = TRUE, row.names = FALSE)
# 				} else {
# 					write.table(tr, file = outname, append = TRUE, sep = " ", col.names = FALSE, row.names = FALSE)
# 				}
#   			unlink(x = basename(dirname(X)),
#   						 recursive = TRUE,
#   						 force = TRUE)
# 			},
# 			outname = paste0(out_dir, out_fname,"-", id, ".trace"))
#   		print("[analysis.worker] Done merging files")
#   } else {
#   	print(paste0("[analysis.worker] Running simulation ", id, "..."))
#   	elapsed <- experiment.run(id = id,
#   														cmd = cmd,
#   														i_time = i_time,
#   														f_time = f_time,
#   														s_time = s_time,
#   														n_run = n_run,
#   														event_times = event_times,
#   														event_function = event_function,
#   														out_fname = out_fname)
#   	print(paste0("[analysis.worker] Simulation ", id, " done!"))
#   }
#   cat("\n\n",id,": Execution time ODEs:",elapsed, "sec.\n")
#   # Change the working directory back to the original one
#   setwd(pwd)
#   # Move relevant files to their final location and remove all the temporary files
#   experiment.env_cleanup(id = id, run_dir = run_dir, out_fname = out_fname, out_dir = out_dir)
#   return(elapsed)
# }

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
# Generate the appropriate command to run on the Docker
cmd <- experiment.cmd(solver_fname = params$files$solver_fname,
											solver_type = params$solver_type,
											taueps = params$taueps,
											timeout = params$timeout)
print("[model.mngr] Done generating command template")
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
n_config <- params$n_config / config_processors
n_run <- params$n_run / run_processors
print(paste0("[model.mngr] Running ", config_processors, " first level threads to handle ", run_processors, " each running ", n_run, " simulation."))
print(paste0("[model.mngr] Overall, running ", (n_config*config_processors*run_processors*n_run)," simulation."))

# Create a cluster
cl <- makeCluster(config_processors,
									type = "FORK")
# Save session's info
clusterEvalQ(cl, sessionInfo())

exec_times <- parLapply( cl = cl,
                         X = params$n_config,
                         fun = mngr.worker,
                         solver_fname = params$files$solver_fname,  # using the following parameters
                         solver_type = params$solver_type,
                         taueps = params$taueps,
                         i_time = params$i_time,
                         f_time = params$f_time,
                         s_time = params$s_time,
                         n_run = params$n_run,
												 cmd = cmd,
                         timeout = params$timeout,
                         run_dir = params$run_dir,
                         out_fname = params$out_fname,
                         out_dir = params$out_dir,
                         seed = init_seed,
                         event_times = params$event_times,
                         event_function = params$event_function,
                         files = params$files,
                         config = params$config,
												 parallel_processors = run_processors)

# exec_times <- lapply(X = c(1:config_processors),
#                      FUN = mngr.worker,
#                      solver_fname = params$files$solver_fname,
#                      solver_type = params$solver_type,
#                      taueps = params$taueps,
#                      i_time = params$i_time,
#                      f_time = params$f_time,
#                      s_time = params$s_time,
#                      n_run = n_run,
# 										 cmd = cmd,
#                      timeout = params$timeout,
#                      run_dir = params$run_dir,
#                      out_fname = params$out_fname,
#                      out_dir = params$out_dir,
# 										 seed = init_seed,
#                      event_times = params$event_times,
#                      event_function = params$event_function,
#                      files = params$files,
#                      config = params$config,
#                      parallel_processors = run_processors)

stopCluster(cl)

# Save final seed
extend_seed <- .Random.seed
n <- n + params$n_config
save(init_seed, extend_seed, n, file = params$seed)

write.table(x = exec_times, file = paste0(params$out_dir,"exec-times_",params$out_fname,".csv"), col.names = TRUE, row.names = TRUE, sep = " ")
file.copy(from = params$target_value_fname, to = params$run_dir)
