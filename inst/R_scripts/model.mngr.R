library(parallel)
library(EpiTCM)

model.worker<-function(id,
                       solver_fname, solver_type,
                       init_fname, s_time, f_time,
                       timeout, run_dir, out_fname, out_dir,
                       files, config){
    # Setup the environment
    experiment.env_setup(id = id, files= files, config = config, dest_dir = run_dir)
    # Environment settled, now run
    # Change working directory to the one corresponding at the current id
    pwd <- getwd()
    setwd(paste0(run_dir,id))
    # Generate the appropriate command to run on the Docker
    cmd <- experiment.cmd(id = id, solver_fname = solver_fname, solver_type = solver_type, init_fname = init_fname, s_time = s_time, f_time = f_time, timeout = timeout, out_fname = out_fname)
    # Measure simulation's run time
    T1 <- Sys.time()
    # Launch the simulation on the Doker
    system(paste(cmd), wait = TRUE)
    T2 <- difftime(Sys.time(), T1, unit = "secs")
    cat("\n\n",id,": Execution time ODEs:",T2, "sec.\n")
    # Change the working directory back to the original one
    setwd(pwd)
    # Move relevant files to their final locatio and remove all the temporary files
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
if(is.null(params$seed)){
    # Save initial seed value
    set.seed(kind = "Mersenne-Twister", seed = NULL)
    init_seed <- .Random.seed
}else{
    load(params$seed)
    if(is.null(params$extend))
    {
        # We want to reproduce the output of a previous set of experiments
        assign(x = ".Random.seed", value = init_seed, envir = .GlobalEnv)
        params$extend <- ""
    }
    else
        # We want to extend a previous experiment
        assign(x = ".Random.seed", value = final_seed, envir = .GlobalEnv)
}
# Generate configuration
params$config <-experiment.configurations(n_config = 1,
                                          parm_fname = params$files$functions_fname,
                                          parm_list = params$files$parameters_fname,
                                          out_dir = chk_dir(params$out_dir),
                                          out_fname = params$out_fname,
                                          extend = params$extend,
                                          optim_vector = params$ini_v)
saveRDS(params,  file = paste0(param_fname))
# Create a cluster
cl <- makeCluster(params$processors, outfile=paste0("log-", params$out_fname, ".txt"), type = "FORK")
# Save session's info
clusterEvalQ(cl, sessionInfo())
# Run simulations
exec_times <- parLapply( cl,
                         c(1:params$n_run),                # execute n_run istances
                         model.worker,                  # of sensitivity.worker
                         solver_fname = params$solver_fname,  # using the following parameters
                         solver_type = params$solver_type,
                         init_fname = params$init_fname,
                         s_time = params$s_time,
                         f_time = params$f_time,
                         timeout = params$timeout,
                         run_dir = params$run_dir,
                         out_fname = params$out_fname,
                         out_dir = params$out_dir,
                         files = params$files,
                         config = params$config)
write.table(x = exec_times, file = paste0(params$out_dir,"exec-times_",params$out_fname,".csv"), col.names = TRUE, row.names = TRUE, sep = " ")
# Save final seed
final_seed<-.Random.seed
save(init_seed, final_seed, file = paste0(params$out_dir,"seeds",params$out_fname,".RData"))
file.copy(from = params$target_value_fname, to = params$run_dir)
