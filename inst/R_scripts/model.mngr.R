library(parallel)
library(epimod)

model.worker<-function(cl,
                       id,
                       solver_fname, solver_type,
                       s_time, f_time, n_run,
                       timeout, run_dir, out_fname, out_dir,
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
    # Generate the appropriate command to run on the Docker
    # cmd <- experiment.cmd(id = id, solver_fname = solver_fname, solver_type = solver_type, s_time = s_time, f_time = f_time, timeout = timeout, out_fname = out_fname, n_run = 1)
    # Measure simulation's run time
    T1 <- Sys.time()
    # Launch the simulation on the Doker
    # system(paste(cmd), wait = TRUE)
    trace_names <- parLapply(cl,
                             c(1:n_run),
                             function(x){
                                 cmd <- experiment.cmd(id=paste0(id,"-",x),
                                                       solver_fname=tools::file_path_as_absolute(solver_fname),
                                                       solver_type=solver_type,
                                                       s_time=s_time,
                                                       f_time=f_time,
                                                       timeout=timeout,
                                                       out_fname=out_fname,
                                                       n_run=1)
                                 write.csv(cmd,file="./cmd.txt");
                                 system(paste(cmd), wait = TRUE)
                                 return(paste0(id,"-",x))
                                 })
    T2 <- difftime(Sys.time(), T1, unit = "secs")
    lapply(trace_names,function(x){
        fnm <- paste0(out_dir, out_fname,"-", id, ".trace")
        tr <- read.csv(x, sep = "")
        if(!file.exists(fnm)){
            write.table(tr, file = fnm, sep = " ", col.names = TRUE, row.names = FALSE)
        }
        else{
            write.table(tr, file = fnm, append = TRUE, sep = " ", col.names = FALSE, row.names = FALSE)
        }
        file.remove(x)
    })
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
                                              ini_vector_mod = params$ini_vector_mod)
}
saveRDS(params,  file = paste0(param_fname), version=2)
# Create a cluster
cl <- makeCluster(params$parallel_processors,# outfile=paste0("log-", params$out_fname, ".txt"),
                  type = "FORK")
# Save session's info
clusterEvalQ(cl, sessionInfo())
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
#                          files = params$files,
#                          config = params$config)
exec_times <- lapply(c(1:params$n_config),
                     model.worker,
                     cl = cl,
                     solver_fname = params$files$solver_fname,
                     solver_type = params$solver_type,
                     s_time = params$s_time,
                     f_time = params$f_time,
                     n_run = params$n_run,
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
