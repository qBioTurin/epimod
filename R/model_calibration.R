#' @title Run model calibration
#' @description this functon takes as input a solver and all the required parameters to set up a dockerized running environment to perform model calibration. both for deterministic and stochastic models
#' In order to run the simulations, the user must provide a reference dataset and the definition of a function to compute the distance (or error) between the models' output and the reference dataset itself.
#' The function defining the distance has to be in the following form:
#'
#' FUNCTION_NAME(reference_dataset, simulation_output)
#'
#' Moreover, the function must return a column vector with one entry for each evaluation point (i.e. f_time/s_time entries)
#' in addiction to that, the user is asked to provide a function that, given the output of the solver, returns the releveant measure (one column) used to evalaute the quality of the solution.
#'
#' The sensitivity analysis will be performed through a Monte Carlo sampling throug user defined functions.
#' the parameters involved in the sensitivity analysis have to be listed in a cvs file using the following structure:
#'
#' OUTPUT_FILE_NAME, FUNCTION_NAME, LIST OF PARAMETERS (comma separated)
#'
#' The functions allowed to compute the parameters are either R functions or user defined functions. In the latter case, all the user defined functions must be provided in a single .R file (which will be passed to run_sensitivity through the parameter parameters_fname)
#'
#' Exploiting the same mechanism, user can provide an initial marking to the solver. However, if it is the case the corresponding file name in the parameter list must be set to "init"
#'
#' To drive the optimization, the user has to provide a function to generate a new configuration, starting from a vector of n elements (each one ranging from 0 to 1).
#' Furthermore, the vector init_v defines the initial point of the search.
#'
#' IMPORTANT: the length of the vector init_v defines the number of variables to variate within the search of the optimal configuration.
#'
#' @param solver_fname .solver file (generated in with the function model_generation)
#' @param f_time Final solution time.
#' @param s_time Time step at whicch explicit estimates for the system are desired
#' @param solver_type  \itemize{ \item Deterministic: ODE-E, ODE-RKF, ODE45, LSODA,
#'  \item Stochastic:  SSA or TAUG,
#'  \item Hybrid: HLSODA or (H)SDE or HODE
#'  } Default is LSODA.
#' @param n_run .....
#' @param parameters_fname
#' @param functions_fname File with the user defined functions to generate istances of the parameters
#' @param volume The folder to mount within the Doker image providing all the necessary files
#' @param timeout ....
#' @param parallel_processors Integer for the parallel....
#' @param ini_v Initial values for the parameters to be optimized.
#' @param lb_v,ub_v Vectors with length equal to the number of paramenters which are varying. Lower/Upper bounds for esch paramenter.
#' @param ini_vector_mod Logical value for ... . Default is FALSE.
#' @param threshold.stop,max.call,max.time These are GenSA arguments, which can be used to control the behavior of the algorithm. (see \code{\link{GenSA}})
#' \itemize{
#' \item threshold.stop (Numeric) respresents the threshold for which the program will stop when the expected objective function value will reach it. Default value is NULL.
#' \item max.call (Integer) represents the maximum number of call of the objective function. Default is 1e7.
#' \item max.time (Numeric) is the maximum running time in seconds. Default value is NULL.}
#'
#' @param reference_data Data to compare with the simulations' results
#' @param distance_measure_fname File containing the definition of a distance measure to rank the simulations'. Such function takes 2 arguments: the reference data and a list of data_frames containing simulations' output. It has to return a data.frame with the id of the simulation and its corresponding distance from the reference data.
#' @param extend ...
#' @param seed Value that can be set to initialize the internal random generator.
#' @param out_fname Prefix to the output file name
#'
#' @author Beccuti Marco, Castagno Paolo, Pernice Simone

#'
#' @examples
#'\dontrun{
#' local_dir <- "/some/path/to/the/directory/hosting/the/input/files/"
#' base_dir <- "/root/scratch/"
#' library(epimod)
#' model_calibration(out_fname = "calibration",
#'                   parameters_fname = paste0(local_dir, "Configuration/Functions_list.csv"),
#'                   functions_fname = paste0(local_dir, "Configuration/Functions.R"),
#'                   solver_fname = paste0(local_dir, "Configuration/Solver.solver"),
#'                   init_fname = "init",
#'                   f_time = 365*21,
#'                   s_time = 365,
#'                   volume = volume = "/some/path/to/the/local/output/directory",
#'                   timeout = "1d",
#'                   parallel_processors=4,
#'                   reference_data = paste0(local_dir, "Configuration/reference_data.csv"),
#'                   distance_measure_fname = paste0(local_dir, "Configuration/Measures.R"),
#'                   target_value_fname = paste0(local_dir, "Configuration/Select.R"),
#'                   target_value_f = "infects",
#'                   ini_v = c(0.48264229, 0.17799173, 0.43572218, 0.06540719, 0.49887063, 0.36793130, 0.01818745, 0.18572619, 0.42815506, 0.07962422, 0.35074813, 0.35074813, 0.36386227),
#'                   ub_v = c(1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1),
#'                   lb_v = c(0, 0, 1e-7, 1e-7, 1e-7, 1e-7, 1e-7, 1e-7, 1e-7, 1e-7, 1e-7, 1e-7, 1e-7),
#'                   nb.stop.improvement = 3000000)
#' }
#' @export
model_calibration <-function(
    # Parameters to control the simulation
    solver_fname, f_time, s_time, solver_type = "LSODA", n_run = 1,
    # User defined simulation's parameters
    parameters_fname = NULL, functions_fname = NULL,
    # Parameters to manage the simulations' execution
    volume = getwd(), timeout = '1d', parallel_processors = 1,
    # Vectors to control the optimization
    ini_v, lb_v, ub_v, ini_vector_mod = FALSE,
    # Variables controlling optimization termination
    threshold.stop = NULL, max.call = 1e7, max.time = NULL,
    # Parameters to control the ranking
    reference_data = NULL, distance_measure_fname = NULL,
    # Mange reproducibilty and extend previous experiments
    extend = FALSE, seed = NULL,
    # Directories
    out_fname = NULL,
    #Flag to enable logging activity
    debug = FALSE){

    #common_test function receive all the parameters that will be tested for model_calibration function
    ret = common_test(parameters_fname = parameters_fname,
                      functions_fname = functions_fname,
                      solver_fname = solver_fname,
                      reference_data = reference_data,
                      distance_measure_fname = distance_measure_fname ,
                      solver_type = solver_type,
                      n_run = n_run,
                      f_time = f_time, # weeks
                      s_time = s_time, # days
                      # Vectors to control the optimization
                      ini_v = ini_v,
                      ub_v = ub_v,
                      lb_v = lb_v,
                      volume = volume,
    									seed = seed,
                      parallel_processors = parallel_processors,
                      caller_function = "calibration")
    if(ret != "ok")
        stop(paste("model_calibration_test error:", ret, sep = "\n"))

    results_dir_name <- "results_model_calibration/"

    chk_dir<- function(path){
        pwd <- basename(path)
        return(paste0(file.path(dirname(path),pwd, fsep = .Platform$file.sep), .Platform$file.sep))
    }

    files <- list()
    # Fix input parameter out_fname
    if(!is.null(solver_fname)){
        solver_fname <- tools::file_path_as_absolute(solver_fname)
        files[["solver_fname"]] <- solver_fname
    }
    if(is.null(out_fname))
    {
        out_fname <- paste0(basename(tools::file_path_sans_ext(solver_fname)),"-calibration")
    }
    # Fix input parameters path
    if(!is.null(parameters_fname))
    {
        parameters_fname <- tools::file_path_as_absolute(parameters_fname)
        files[["parameters_fname"]] <- parameters_fname
    }
    if(!is.null(functions_fname))
    {
        functions_fname <- tools::file_path_as_absolute(functions_fname)
        files[["functions_fname"]] <- functions_fname
    }
    if(!is.null(reference_data))
    {
        reference_data <- tools::file_path_as_absolute(reference_data)
        files[["reference_data"]] <- reference_data
    }
    if(!is.null(distance_measure_fname))
    {
        distance_measure_fname <- tools::file_path_as_absolute(distance_measure_fname)
        files[["distance_measure_fname"]] <- distance_measure_fname
    }
    if(!is.null(seed))
    {
    	seed <- tools::file_path_as_absolute(seed)
    	files[["seed"]] <- seed
    }

    params <- list(
                   run_dir = chk_dir("/home/docker/scratch/"),
                   out_dir = chk_dir(paste0("/home/docker/data/", results_dir_name)),
                   out_fname = out_fname,
                   solver_type = solver_type,
                   f_time = f_time,
                   s_time = s_time,
                   n_run = n_run,
                   volume = volume,
                   timeout = timeout,
                   distance_measure = tools::file_path_sans_ext(basename(distance_measure_fname)),
                   ini_v = ini_v,
                   lb_v = lb_v,
                   ub_v = ub_v,
                   ini_vector_mod = ini_vector_mod,
                   threshold.stop = threshold.stop,
                   max.call = max.call,
                   max.time = max.time,
                   files = files,
                   extend = extend,
                   processors = parallel_processors)

    res_dir <- paste0(chk_dir(volume), results_dir_name)
    if(!extend & file.exists(res_dir)){
    	unlink(res_dir, recursive = TRUE)
    }
    dir.create(res_dir, showWarnings = FALSE)
    # Copy all the files to the directory docker will mount to the image's file system
    experiment.env_setup(files = files, dest_dir = res_dir)
    # Change path to the new files' location
    files <- lapply(files, function(x){
        return(paste0(params$out_dir,basename(x)))
    })
    params$files <- files

    # file.copy(from = target_value_fname, to = res_dir)
    # Manage experiments reproducibility
    if(!is.null(seed)){
    	parms$seed <- paste0(parms$out_dir, "seeds-", out_fname, ".RData")
    }

    parms_fname <- paste0(chk_dir(res_dir),"params_",out_fname,".RDS")
    saveRDS(params, file = parms_fname, version = 2)

    parms_fname <- paste0(params$out_dir, basename(parms_fname))
    # Run the docker image
    containers.file=paste(path.package(package="epimod"),"Containers/containersNames.txt",sep="/")
    containers.names=read.table(containers.file,header=T,stringsAsFactors = F)
    docker.run(params = paste0("--cidfile=dockerID ","--volume ", volume,":", dirname(params$out_dir), " -d ", containers.names["calibration",1]," Rscript /usr/local/lib/R/site-library/epimod/R_scripts/calibration.mngr.R ", parms_fname), debug = debug)
}
