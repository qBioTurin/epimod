library(parallel)
library(epimod)
library(ggplot2)

sensitivity.worker<-function(id,
                             solver_fname, solver_type, s_time, f_time,
                             timeout, run_dir, out_fname, out_dir,
                             event.list,
                             files, config){
    # Setup the environment
    experiment.env_setup(id = id, files= files, config = config, dest_dir = run_dir)
    # Environment settled, now run
    # Change working directory to the one corresponding at the current id
    pwd <- getwd()
    setwd(paste0(run_dir,id))
    if(is.null(event.list))
    {
      # Generate the appropriate command to run on the Docker
      cmd <- experiment.cmd(id = id, solver_fname = solver_fname, solver_type = solver_type, s_time = s_time,
                            f_time = f_time, timeout = timeout, out_fname = out_fname)
      # Measure simulation's run time
      T1 <- Sys.time()
      # Launch the simulation on the Doker
      system(paste(cmd), wait = TRUE)
      T2 <- difftime(Sys.time(), T1, unit = "secs")
    }else{
      experiment.event.cmd(id = id, solver_fname = solver_fname, solver_type = solver_type,
                           s_time = s_time, f_time = f_time, timeout = timeout,
                           out_fname = out_fname,
                           event.list=event.list)
    }
    
    cat("\n\n",id,": Execution time ODEs:",T2, "sec.\n")
    # Change the working directory back to the original one
    setwd(pwd)
    # Move relevant files to their final locatio and remove all the temporary files
    experiment.env_cleanup(id = id, run_dir = run_dir, out_fname = out_fname, out_dir = out_dir)
    return(T2)
}
# Function to compute the distance between one simulation trace and the reference data
sensitivity.distance <- function(id,
                                 run_dir,
                                 out_fname,
                                 out_dir,
                                 distance_measure_fname,
                                 distance_measure,
                                 reference_data){
    pwd <- getwd()
    setwd(out_dir)
    # Read the output and compute the distance from reference data
    trace <- read.csv(paste0(out_fname, "-", id, ".trace"), sep = "")
    # Load distance definition
    source(distance_measure_fname)
    # Load reference data (IMPORTANT it has to be a column vector)
    reference <- as.data.frame(t(read.csv(reference_data, header = FALSE, sep = "")))
    # Compute the user defined distance measure
    measure <- do.call(distance_measure, list(reference, trace))
    setwd(pwd)
    return(data.frame(measure=measure, id=id))
}
chk_dir<- function(path){
    pwd <- basename(path)
    return(paste0(file.path(dirname(path),pwd, fsep = .Platform$file.sep), .Platform$file.sep))
}
# Get initial time
t1 <- Sys.time()
# Read commandline arguments
args <- commandArgs(TRUE)
cat(args)
param_fname <- args[1]
# Load parameters
params <- readRDS(param_fname)
# Get functions name from file path
if(!is.null(params$files$distance_measure_fname))
{
    distance_measure <- tools::file_path_sans_ext(basename(params$files$distance_measure_fname))
}
if(!is.null(params$files$target_value_fname))
{
    target_value <- tools::file_path_sans_ext(basename(params$files$target_value_fname))
    file.copy(from = params$files$target_value_fname, to = params$run_dir)
}
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
params$config <-experiment.configurations(n_config = params$n_config,
                                   parm_fname = params$files$functions_fname,
                                   parm_list = params$files$parameters_fname,
                                   out_dir = chk_dir(params$out_dir),
                                   out_fname = params$out_fname,
                                   extend = params$extend)
saveRDS(params,  file = paste0(param_fname), version = 2)
# Save final seed
final_seed<-.Random.seed
save(init_seed, final_seed, file = paste0(params$out_dir,"seeds-",params$out_fname,".RData"))
# Create a cluster
cl <- makeCluster(params$parallel_processors,
                  # outfile=paste0("log-", params$out_fname, ".txt"),
                  type = "FORK")
# Save session's info
clusterEvalQ(cl, sessionInfo())
# Run simulations
exec_times <- parLapply( cl,
                         c(1:params$n_config),                # execute n_config istances
                         sensitivity.worker,                  # of sensitivity.worker
                         solver_fname = params$files$solver_fname,  # using the following parameters
                         solver_type = "LSODA",
                         s_time = params$s_time,
                         f_time = params$f_time,
                         timeout = params$timeout,
                         run_dir = params$run_dir,
                         out_fname = params$out_fname,
                         out_dir = params$out_dir,
                         files = params$files,
                         config = params$config,
                         event.list= params$event.list)

write.table(x = exec_times, file = paste0(params$out_dir,"exec-times_",params$out_fname,".RData"), col.names = TRUE, row.names = TRUE, sep = ",")
# List all the traces in the output directory
if(!is.null(params$files$distance_measure_fname))
{
    rank <- parLapply(cl,
                      c(1:abs(params$config[[1]][[1]][[2]])),
                      sensitivity.distance,
                      out_fname = params$out_fname,
                      out_dir = params$out_dir,
                      run_dir = params$run_dir,
                      distance_measure_fname = params$files$distance_measure_fname,
                      distance_measure = distance_measure,
                      reference_data = params$files$reference_data)
    # Sort the rank ascending, according to the distance computed above.
    rank <- do.call("rbind", rank)
    rank <- rank[order(rank$measure),]
    save(rank, file = paste0(params$out_dir,"ranking_",params$out_fname,".RData"))
}
stopCluster(cl)
if(!is.null(params$files$target_value_fname))
{
    # Load external function to compute prcc
    source("/usr/local/lib/R/site-library/epimod/R_scripts/sensitivity.prcc.R")
    prcc <- sensitivity.prcc(config = params$config,
                             target_value_fname = params$files$target_value_fname,
                             target_value = target_value,
                             s_time = params$s_time,
                             f_time = params$f_time,
                             out_fname = params$out_fname,
                             out_dir = params$out_dir,
                             parallel_processors = params$parallel_processors)
    # Plot PRCC
    # Get the parameter names and the total number of parameters
    names_param= names(prcc$PRCC)
    n_params = length(names_param)
    # Get the istants of time at which the PRCC is evaluated
    time <- c(1:(params$f_time %/% params$s_time)) * params$s_time
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
    exec_time <- difftime(Sys.time(), t1, unit = "secs")
    save(prcc, plt, exec_time, file = paste0(params$out_dir,"prcc_",params$out_fname,".RData"))
}
