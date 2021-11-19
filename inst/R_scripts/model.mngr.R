library(parallel)
library(epimod)

model.worker<-function(id,
                       solver_fname, solver_type,taueps,
                       s_time, f_time, n_run,
                       timeout, run_dir, out_fname, out_dir, seed,
                       files, config = NULL){
    if(!is.null(config))
    {
        # Setup the environment
        experiment.env_setup(id = id, files= files, config = config, dest_dir = run_dir)
        # Environment settled, now run
    }
    else
    {
        # Handle simulations without parameters
        dir.create(paste0(run_dir, id), recursive = TRUE, showWarnings = FALSE)
        file.copy(from = solver_fname, to = paste0(run_dir, id))
    }
    # Change working directory to the one corresponding at the current id
    pwd <- getwd()
    setwd(paste0(run_dir,id))
    cl <- makeCluster(params$parallel_processors,# outfile=paste0("log-", params$out_fname, ".txt"),
                      type = "FORK")
    # Save session's info
    clusterEvalQ(cl, sessionInfo())
    # Generate the appropriate command to run on the Docker
    # cmd <- experiment.cmd(id = id, solver_fname = solver_fname, solver_type = solver_type, s_time = s_time, f_time = f_time, timeout = timeout, out_fname = out_fname, n_run = 1)
    # Measure simulation's run time
    # T1 <- Sys.time()
    # Launch the simulation on the Doker
    # system(paste(cmd), wait = TRUE)
    trace_names <- lapply(c(1:n_run),
                         function(x, id){
                             paste0(id,"-",x)
                             },
                         id=id
                         )

    cmds <- parLapply(cl=cl,
                      X=trace_names,
                      fun=experiment.cmd,
                      solver_fname=solver_fname,
                      solver_type=solver_type,
                      taueps=taueps,
                      s_time=s_time,
                      f_time=f_time,
    									seed = seed + id,
                      timeout=timeout,
                      out_fname=out_fname,
                      n_run=1)
    T1 <- Sys.time()
    parLapply(cl = cl,
              X = cmds,
              fun = system,
              wait = TRUE
              )
    T2 <- difftime(Sys.time(), T1, unit = "secs")
    stopCluster(cl)
    lapply(trace_names,function(x){
        fnm <- paste0(out_dir, out_fname,"-", id, ".trace")
        tr <- read.csv(paste0(run_dir,id,.Platform$file.sep, out_fname,"-",x,".trace"), sep = "")
        if(!file.exists(fnm)){
            write.table(tr, file = fnm, sep = " ", col.names = TRUE, row.names = FALSE)
        }
        else{
            write.table(tr, file = fnm, append = TRUE, sep = " ", col.names = FALSE, row.names = FALSE)
        }
        file.remove(paste0(run_dir,id,.Platform$file.sep, out_fname,"-",x,".trace"))
    })
    cat("\n\n",id,": Execution time ODEs:",T2, "sec.\n")
    # Change the working directory back to the original one
    setwd(pwd)
    # Move relevant files to their final location and remove all the temporary files
    experiment.env_cleanup(id = id, run_dir = run_dir, out_fname = out_fname, out_dir = out_dir)
    return(T2)
}
chk_dir<- function(path){
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
    params$config <-experiment.configurations(n_config = params$n_config,
                                              parm_fname = params$files$functions_fname,
                                              parm_list = params$files$parameters_fname,
                                              out_dir = chk_dir(params$out_dir),
                                              out_fname = params$out_fname,
                                              extend = params$extend,
                                              ini_vector = params$ini_v,
                                              ini_vector_mod = params$ini_vector_mod,
    																					config = config)
}

# Save final seed
extend_seed <- .Random.seed
n <- n + params$n_config
save(init_seed, extend_seed, n, file = params$seed)

saveRDS(params,  file = paste0(param_fname), version=2)
# Create a cluster
# cl <- makeCluster(params$parallel_processors,# outfile=paste0("log-", params$out_fname, ".txt"),
#                   type = "FORK")
# # Save session's info
# clusterEvalQ(cl, sessionInfo())
# Run simulations
# exec_times <- parLapply( cl,
#                          c(1:params$n_config),          # execute n_config istances
#                          model.worker,                  # of sensitivity.worker
#                          solver_fname = params$files$solver_fname,  # using the following parameters
#                          solver_type = params$solver_type,
#                          s_time = params$s_time,
#                          f_time = params$f_time,
#                          n_run = params$n_run,
#                          timeout = params$timeout,
#                          run_dir = params$run_dir,
#                          out_fname = params$out_fname,
#                          out_dir = params$out_dir,
#													 seed = init_seed,
#                          files = params$files,
#                          config = params$config)
exec_times <- lapply(X = c(1:params$n_config),
                     FUN = model.worker,
                     solver_fname = params$files$solver_fname,
                     solver_type = params$solver_type,
                     taueps = params$taueps,
                     s_time = params$s_time,
                     f_time = params$f_time,
                     n_run = params$n_run,
                     timeout = params$timeout,
                     run_dir = params$run_dir,
                     out_fname = params$out_fname,
                     out_dir = params$out_dir,
										 seed = init_seed,
                     files = params$files,
                     config = params$config)

write.table(x = exec_times, file = paste0(params$out_dir,"exec-times_",params$out_fname,".csv"), col.names = TRUE, row.names = TRUE, sep = " ")
file.copy(from = params$target_value_fname, to = params$run_dir)
