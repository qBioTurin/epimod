model_analysis <- function(
    # Parameters to control the simulation
    solver_fname, i_time = 0, f_time, s_time, n_config = 1, n_run = 1, solver_type = "LSODA", taueps=0.01,
    # User defined simulation's parameters
    parameters_fname = NULL, functions_fname = NULL, ini_v = NULL, ini_vector_mod = FALSE,
    # Parameters to manage the simulations' execution
    volume = getwd(), timeout = '1d', parallel_processors = 1,
    # List of discrete events
    event_times = NULL, event_function = NULL,
    # Mange reproducibilty and extend previous experiments
    extend = NULL, seed = NULL,
    # Directories
    out_fname = NULL
){

    chk_dir <- function(path){
        pwd <- basename(path)
        return(paste0(file.path(dirname(path),pwd, fsep = .Platform$file.sep), .Platform$file.sep))
    }
    # Parameters used to set up the runing environment
    files <- list()
    # Fix input parameter out_fname
    if (is.null(solver_fname))
    {
        stop("Missing solver file! Abort")
    } else {
        solver_fname <- tools::file_path_as_absolute(solver_fname)
        files[["solver_fname"]] <- solver_fname
    }
    if (is.null(out_fname))
    {
        out_fname <- paste0(basename(tools::file_path_sans_ext(solver_fname)),"-analysys")
    }
    # Fix input parameters path
    if (!is.null(parameters_fname))
    {
        parameters_fname <- tools::file_path_as_absolute(parameters_fname)
        files[["parameters_fname"]] <- parameters_fname
    }
    if (!is.null(functions_fname))
    {
        functions_fname <- tools::file_path_as_absolute(functions_fname)
        files[["functions_fname"]] <- functions_fname
    }

    # Global parameters used to manage the environment within the docker container
    parms_fname <- file.path(paste0("params_",out_fname), fsep = .Platform$file.sep)
    parms <- list(n_run = n_run,
                  n_config = n_config,
                  run_dir = chk_dir("/home/docker/scratch/"),
                  out_dir = chk_dir("/home/docker/data/results_model_analysis/"),
                  out_fname = out_fname,
                  solver_type = solver_type,
                  taueps = taueps,
                  i_time = i_time,
                  f_time = f_time,
                  s_time = s_time,
                  parallel_processors = parallel_processors,
                  volume = volume,
                  timeout = timeout,
                  files = files,
                  ini_v = ini_v,
                  ini_vector_mod = ini_vector_mod,
                  event_times = event_times,
                  event_function = event_function)
    # Create the folder to store results
    res_dir <- paste0(chk_dir(volume),"results_model_analysis/")
    dir.create(res_dir, showWarnings = FALSE)
    # Copy all the files to the directory docker will mount to the image's file system
    experiment.env_setup(files = files, dest_dir = res_dir)
    # Change path to the new files' location
    parms$files <- lapply(files, function(x){
        return(paste0(parms$out_dir,basename(x)))
    })
    # Manage experiments reproducibility
    if (!is.null(seed))
    {
        parms$seed <- paste0(parms$out_dir,basename(seed))
        file.copy(from = seed, to = res_dir )
        if (!is.null(extend))
        {
            parms$extend <- paste0(parms$out_dir,basename(extend))
            file.copy(from = extend, to = volume )
        }
    }
    # Save all the parameters to file, in a location accessible from inside the dockerized environment
    p_fname <- paste0(res_dir, parms_fname,".RDS")
    # Use version = 2 for compatibility issue
    saveRDS(parms,  file = p_fname, version = 2)
    p_fname <- paste0( parms$out_dir, parms_fname,".RDS") # location in the docker image file system
    # Run the docker image
    containers.file = paste(path.package(package = "epimod"), "Containers/containersNames.txt", sep = "/")
    containers.names = read.table(containers.file,header = T, stringsAsFactors = F)
    docker.run(params = paste0("--cidfile=dockerID ","--volume ", volume,":", dirname(parms$out_dir), " -d ", containers.names["analysis",1]," Rscript /usr/local/lib/R/site-library/epimod/R_scripts/model.mngr.R ", p_fname))
}
