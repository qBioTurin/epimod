#' @title Run model analysis
#' @description
#'   Solves the system given a specific parameters configuration simulating the behavior of the developed model.
#'   Furthermore, by changing the input parameters, it is possible to perform a what-if analysis or forecasting the evolution of the diffusion process.
#'
#' @param solver_fname .solver file (generated with the function *model_generation*).
#' @param i_time Initial solution time.
#' @param f_time Final solution time.
#' @param s_time Time step defining the frequency at which explicit estimates for the system values are desired.
#' @param atol Absolute error tolerance that determine the error control performed by the LSODA solver.
#' @param rtol Relative error tolerance that determine the error control performed by the LSODA solver.
#' @param n_config Integer for the number of configurations to generate, to use only if some parameters are generated from a stochastic distribution, which has to be encoded in the functions defined in *functions_fname* or in *parameters_fname*.
#' @param n_run Integer for the number of stochastic simulations to run. If n_run is greater than 1 when the deterministic process is analyzed (solver_type is *Deterministic*), then n_run identical simulation are generated.
#' @param solver_type
#'  \itemize{
#'    \item Deterministic: three explicit methods which can be efficiently used  for systems without stiffness: Runge-Kutta 5th order integration, Dormand-Prince method, and Kutta-Merson method (ODE-E, ODE-RKF, ODE45). Instead for systems with stiffness we provided a Backward Differentiation Formula (LSODA);
#'    \item Stochastic: the Gillespie algorithm,which is an exact stochastic method widely used to simulate chemical systems whose behaviour can be described by the Master equations (SSA); or an approximation method of the SSA called tau-leaping method (TAUG), which provides a good compromise between the solution execution time  and its quality.
#'    \item Hybrid: Stochastic  Hybrid  Simulation, based on the co-simulation of discrete and continuous events (HLSODA).
#'  } Default is LSODA.
#' @param taueps The error control parameter from the tau-leaping approach.
#' @param parameters_fname a textual file in which the  parameters to be studied are listed associated with their range of variability.
#' This file is defined by three mandatory columns (*which must separeted using ;*):
#'  (1) a tag representing the parameter type: *i* for the complete initial marking (or condition),
#'   *m* for the initial marking of a specific place, *c* for a single constant rate,
#'   and *g* for a rate associated with general transitions (Pernice et al. 2019)  (the user must define a file name coherently with the one used in the  general transitions file);
#'    (2) the name of the transition which is varying (this must correspond to name used in the PN draw in GreatSPN editor), if the complete initial marking is considered
#'    (i.e., with tag *i*) then by default the name *init*  is used; (3) the function used for sampling the value of the variable considered,
#'     it could be either a R function or an user-defined function (in this case it has to be implemented into the R script passed through the *functions_fname* input parameter).
#'      Let us note that the output of this function must have size equal to the length of the varying parameter, that is 1 when tags *m*, *c* or *g* are used,
#'       and the size of the marking (number of places) when *i* is used.  The remaining columns represent the input parameters needed by the functions defined in the third column.
#' @param functions_fname an R file storing: 1) the user defined functions to generate instances of the parameters summarized in the *parameters_fname* file, and
#'  the discrete events which may modify the marking of the net at specific time points (see *event_function*).
#' @param volume The folder to mount within the Docker image providing all the necessary files.
#' @param timeout Maximum execution time allowed to each configuration.
#' @param parallel_processors Integer for the number of available processors to use for parallelizing the simulations.
#' @param event_times Vector representing the time points at which the simulation has to stop in order to
#' simulate a discrete event that modifies the marking of the net given a specific rule defined in *functions_fname*.
#' @param event_function String reporting the function, implemented in *functions_fname*, to exploit for modifying the total marking at a specific time point.
#' Such function takes in input: 1) a vector representing the marking of the net (called *marking*), and 2) the time point at which the simulation has stopped (called *time*).
#' In particular, *time* takes values from *event_times*.
#' @param extend If TRUE the actual configuration is extended including n_config new configurations.
#' @param seed .RData file that can be used to initialize the internal random generator.
#' @param out_fname Prefix to the output file name.
#' @param user_files Vector of user files to copy inside the docker directory
#' @param debug If TRUE enables logging activity.
#' @param fba_fname vector of .txt files encoding different flux balance analysis problems, which as to be included in the general transitions (*transitions_fname*).
#' @param FVA Flag to enable the flux variability analysis
#' It must be the same files vector passed to the function *model_generation* for generating the *solver_fname*. (default is NULL)
#'
#' @details
#'
#' @author Beccuti Marco, Castagno Paolo, Pernice Simone, Baccega Daniele
#'
#'
#' @export

model.analysis <- function(
    # Parameters to control the simulation
    solver_fname, i_time = 0, f_time, s_time, atol = 1e-6, rtol = 1e-6, n_config = 1, n_run = 1, solver_type = "LSODA", taueps = 0.01,
    # User defined simulation's parameters
    parameters_fname = NULL, functions_fname = NULL, ini_v = NULL, ini_vector_mod = FALSE,
    # Parameters to manage the simulations' execution
    volume = getwd(), timeout = '1d', parallel_processors = 1,
    # List of discrete events
    event_times = NULL, event_function = NULL,
    # Mange reproducibility and extend previous experiments
    extend = FALSE, seed = NULL,
    # Directories
    out_fname = NULL,
    #Vector of user files to copy inside the docker directory
    user_files = NULL,
    #Flag to enable logging activity
    debug = FALSE,
    fba_fname = NULL,
    # Flag to enable the flux variability analysis
    FVA  = FALSE
){

    # This function receives all the parameters that will be tested for model_analysis function
    ret = common_test(solver_fname = solver_fname,
                      parameters_fname = parameters_fname,
                      functions_fname = functions_fname,
                      solver_type = solver_type,
                      n_run = n_run,
                      ini_v = ini_v,
    									i_time = i_time,
                      f_time = f_time,
                      s_time = s_time,
                      volume = volume,
    									seed = seed,
    									extend = extend,
    									event_times = event_times,
    									event_function = event_function,
    									user_files = user_files,
                      parallel_processors = parallel_processors,
                      n_config = n_config,
                      caller_function = "analysis")

    if(ret != TRUE && !grepl("WARNING", ret)){
        stop(paste("model_analysis_test error:", ret, sep = "\n"))
    }else{
        if(ret != TRUE)
            warning(paste("model_analysis_test", ret))
    }
    results_dir_name <- paste0(basename(tools::file_path_sans_ext(solver_fname)), "_analysis/")

    chk_dir <- function(path){
        pwd <- basename(path)
        return(paste0(file.path(dirname(path),pwd, fsep = .Platform$file.sep), .Platform$file.sep))
    }
    # Parameters used to set up the runing environment
    files <- list()
    # Fix input parameter out_fname
    if(!is.null(solver_fname)){
        solver_fname <- tools::file_path_as_absolute(solver_fname)
        files[["solver_fname"]] <- solver_fname
    }
    if (is.null(out_fname))
    {
    	out_fname <- paste0(basename(tools::file_path_sans_ext(solver_fname)),"-analysis")
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
    if(!is.null(seed))
    {
    	seed <- tools::file_path_as_absolute(seed)
    	files[["seed"]] <- seed
    }
    if(!is.null(user_files)){
    	for(file in user_files){
    		files[[file]] <- tools::file_path_as_absolute(file)
    	}
    }
    if(!is.null(fba_fname)){
    	fba_fname <- sapply(fba_fname,tools::file_path_as_absolute)
    	files[["fba_fname"]] <- fba_fname
    }

    # Global parameters used to manage the environment within the docker container
    parms_fname <- file.path(paste0("params_",out_fname), fsep = .Platform$file.sep)
    parms <- list(n_run = n_run,
                  n_config = n_config,
                  run_dir = chk_dir("/home/docker/scratch/"),
                  out_dir = chk_dir(paste0("/home/docker/data/", results_dir_name)),
                  out_fname = out_fname,
                  solver_type = solver_type,
                  taueps = taueps,
                  i_time = i_time,
                  f_time = f_time,
                  s_time = s_time,
    							atol = atol,
    							rtol = rtol,
                  parallel_processors = parallel_processors,
                  volume = volume,
                  timeout = timeout,
                  files = files,
                  ini_v = ini_v,
                  ini_vector_mod = ini_vector_mod,
    							extend = extend,event_times = event_times,
    							event_function = event_function,
    							FVA = FVA)
    # Create the folder to store results
    res_dir <- paste0(chk_dir(volume), results_dir_name)
    if(!extend & file.exists(res_dir)){
    	unlink(res_dir, recursive = TRUE)
    }
    dir.create(res_dir, showWarnings = FALSE)
    Sys.chmod(res_dir, mode = "777", use_umask = FALSE)
    # Copy all the files to the directory docker will mount to the image's file system
    experiment.env_setup(files = files, dest_dir = res_dir)
    # Change path to the new files' location
    parms$files <- lapply(files, function(x){
        return(paste0(parms$out_dir,basename(x)))
    })

    # Manage experiments reproducibility
    if(!is.null(seed)){
    	parms$seed <- paste0(parms$out_dir, "seeds-", out_fname, ".RData")
    }

    # Save all the parameters to file, in a location accessible from inside the dockerized environment
    p_fname <- paste0(res_dir, parms_fname,".RDS")
    # Use version = 2 for compatibility issue
    saveRDS(parms,  file = p_fname, version = 2)
    p_fname <- paste0( parms$out_dir, parms_fname,".RDS") # location in the docker image file system
    # Run the docker image
    containers.file=paste(path.package(package="epimod"),"Containers/containersNames.txt",sep="/")
    containers.names=read.table(containers.file,header=T,stringsAsFactors = F)
    id_container=paste(containers.names["analysis", 1],system("id -un", intern = TRUE),sep="_")
    docker.run(params = paste0("--cidfile=dockerID ","--volume ", volume,":", dirname(parms$out_dir), " -d ", id_container," Rscript /usr/local/lib/R/site-library/epimod/R_scripts/model.mngr.R ", p_fname), debug = debug)

}
