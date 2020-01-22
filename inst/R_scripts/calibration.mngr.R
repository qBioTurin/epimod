library(GenSA)
library(epimod)
library(parallel)

calibration.worker <- function(id, config, params){
    experiment.env_setup(id = id,
                         files = params$files,
                         dest_dir = params$run_dir,
                         config = config)
    pwd <- getwd()
    setwd(paste0(params$run_dir, id))
    cmd <- experiment.cmd(id,
                          solver_fname = params$files$solver_fname,
                          solver_type = params$solver_type,
                          n_run = 1,
                          s_time = params$s_time,
                          f_time = params$f_time,
                          timeout = params$timeout,
                          out_fname = params$out_fname)

    system(cmd, wait = TRUE)
    fnm <- paste0(params$out_fname,"-",id,".trace")
    # trace <- read.csv(file = fnm , header = TRUE, sep = "")
    experiment.env_cleanup(id = id,
                           run_dir = params$run_dir,
                           out_fname = params$out_fname,
                           out_dir = params$out_dir)
    setwd(pwd)
    return(paste0(params$out_dir,fnm))
}

objfn <-function(x, params, cl) {
    # Generate a new configuration using the optimizaton output x
    id <- length(list.files(path = params$out_dir, pattern = ".trace")) + 1
    config <- experiment.configurations(n_config = 1,
                              parm_fname = params$files$functions_fname,
                              parm_list = params$files$parameters_fname,
                              out_dir = params$out_dir,
                              out_fname = params$out_fname,
                              optim_vector = x)
    # calibration.worker(id = id, config = config, params = params)
    # traces <- read.csv(paste0(params$out_dir,params$out_fname,"-",id,".trace"), sep = "")
    trace_names <- parLapply(cl,
                        c(paste0(id,"-",c(1:params$n_run))),
                        calibration.worker,
                        config = config,
                        params = params)
    traces <- lapply(trace_names,function(x){
        fnm <- paste0(params$out_dir, params$out_fname,"-", id, ".trace")
        tr <- read.csv(x, sep = "")
        if(!file.exists(fnm)){
            write.table(tr, file = fnm, sep = " ", col.names = TRUE, row.names = FALSE)
        }
        else{
            write.table(tr, file = fnm, append = TRUE, sep = " ", col.names = FALSE, row.names = FALSE)
        }
        file.remove(x)
        return(tr)
    })
    traces <- do.call("rbind", traces)

    source(params$files$distance_measure_fname)
    # distance <- do.call(params$distance_measure, list(read.csv(file = params$files$reference_data, header = FALSE, sep = ""), trace))
    distance <- do.call(params$distance_measure, list(read.csv(file = params$files$reference_data, header = FALSE, sep = ""), traces))
    # Write header to the file
    optim_trace_fname <- paste0(params$out_dir,params$out_fname,"_optim-trace.csv")
    if(!file.exists(optim_trace_fname))
    {
        nms <- c("distance", "id", paste0("optim_v-",c(1:length(x))))
        cat(unlist(nms),"\n", file = optim_trace_fname)
    }
    cat(unlist(c(distance,id, x)),"\n", file = optim_trace_fname ,append=TRUE)
    return(distance)
}
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
# Copy files to the run directory
experiment.env_setup(files = params$files, dest_dir = params$run_dir)
# Create a cluster
cl <- makeCluster(params$processors, type = "FORK")
# Call gensa with init_vector as initail condition, upper_vector and lower_vector as boundaries conditions.
ret <- GenSA(par=params$ini_v,
             fn=objfn,
             upper=params$ub_v,
             lower=params$lb_v,
             control=list( max.call = params$max.call,
                           threshold.stop = params$threshold.stop,
                           max.time = params$max.time),
             params = params,
             cl = cl)
stopCluster(cl)
# Save the output of the optimization problem to file
save(ret, file = paste0(out_dir,out_fname,"-optim.RData"))
# Save final seed
final_seed<-.Random.seed
save(init_seed, final_seed, file = paste0(params$out_dir,"seeds",params$out_fname,".RData"))
