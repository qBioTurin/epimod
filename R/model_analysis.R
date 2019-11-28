model_analysis <-function(
    # Directories
    out_dir, out_fname,
    # User defined simulation's parameters
    parameters_fname = "", functions_fname = "",
    # Parameters to control the simulation
    solver_fname = "", solver_type = "HLSODA", init_fname = NULL, f_time, s_time, n_run = 1,
    # Parameters to manage the simulations' execution
    volume = "", timeout = '1d', processors,
    # Mange reproducibilty and extend previous experiments
    extend = NULL, seed = NULL,
    ini_v
){

    chk_dir<- function(path){
        pwd <- basename(path)
        return(paste0(file.path(dirname(path),pwd, fsep = .Platform$file.sep), .Platform$file.sep))
    }
    # Parameters used to set up the runing environment
    files <- list(
        parameters_fname = parameters_fname,
        functions_fname = functions_fname,
        solver_fname = solver_fname
    )
    # Global parameters used to manage the dockerized environment
    parms_fname <- file.path(paste0("params_",out_fname), fsep = .Platform$file.sep)
    parms <- list(n_run = n_run,
                  run_dir = chk_dir("/root/scratch/Run/"),
                  out_dir = chk_dir("/root/data/"),
                  out_fname = out_fname,
                  solver_fname = solver_fname,
                  solver_type = solver_type,
                  init_fname = init_fname,
                  f_time = f_time,
                  s_time = s_time,
                  processors = processors,
                  volume = volume,
                  timeout = timeout,
                  files = files,
                  ini_v = ini_v)
    # Create the folder to store results
    res_dir <- paste0(chk_dir(volume),"results/")
    dir.create(res_dir, showWarnings = FALSE)
    # Copy all the files to the directory docker will mount to the image's file system
    experiment.env_setup(files = files, dest_dir = res_dir)
    # Change path to the new files' location
    parms$files <- lapply(files, function(x){
        return(paste0(parms$out_dir,basename(x)))
    })
    # Manage experiments reproducibility
    if(!is.null(seed)){
        parms$seed <- paste0(parms$out_dir,basename(seed))
        file.copy(from = seed, to = res_dir )
        if(!is.null(extend)){
            parms$extend <- paste0(parms$out_dir,basename(extend))
            file.copy(from = extend, to = volume )
        }
    }
    # Save all the parameters to file, in a location accessible from inside the dockerized environment
    p_fname <- paste0(res_dir, parms_fname,".RDS")
    # Use version = 2 for compatibility issue
    saveRDS(parms,  file = p_fname, version = 2)
    p_fname <- paste0( parms$out_dir, parms_fname,".RDS") # location on the docker image file system
    # Run the docker image
    docker.run(params = paste0("--cidfile=dockerID ","--volume ", volume,":/root/data/ -d epimod_analysis Rscript /usr/local/lib/R/site-library/epimod/R_scripts/model.mngr.R ", p_fname))
    file.remove("./dockerID")
}
