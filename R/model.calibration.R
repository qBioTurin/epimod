#' @title Run model calibration
#' @description
#'   This function takes as input a solver and all the required parameters to set up a dockerized running environment to perform model calibration, both for deterministic and stochastic models.
#'
#' @param solver_fname .solver file (generated in with the function model_generation).
#' @param i_time Initial solution time.
#' @param f_time Final solution time.
#' @param s_time Time step defining the frequency at which explicit estimates for the system values are desired.
#' @param solver_type
#'  \itemize{
#'    \item Deterministic: three explicit methods which can be efficiently used  for systems without stiffness: Runge-Kutta 5th order integration, Dormand-Prince method, and Kutta-Merson method (ODE-E, ODE-RKF, ODE45). Instead for systems with stiffness we provided a Backward Differentiation Formula (LSODA);
#'    \item Stochastic: the Gillespie algorithm,which is an exact stochastic method widely used to simulate chemical systems whose behaviour can be described by the Master equations (SSA); or an approximation method of the SSA called tau-leaping method (TAUG), which provides a good compromise between the solution execution time  and its quality.
#'    \item Hybrid: Stochastic  Hybrid  Simulation, based on the co-simulation of discrete and continuous events (HLSODA).
#'  } Default is LSODA.
#' @param taueps The error control parameter from the tau-leaping approach.
#' @param n_run Integer for the number of stochastic simulations to run. If n_run is greater than 1 when the deterministic process is analyzed (solver_type is *Deterministic*), then n_run identical simulation are generated.
#' @param parameters_fname Textual file in which the parameters to be studied are listed associated with their range of variability. This file is defined by three mandatory columns: (1) a tag representing the parameter type: i for the complete initial marking (or condition), p for a single parameter (either a single rate or initial marking), and g for a rate associated with general transitions (Pernice et al. 2019) (the user must define a file name coherently with the one used in the general transitions file); (2) the name of the transition which is varying (this must correspond to name used in the PN draw in GreatSPN editor), if the complete initial marking is considered (i.e., with tag i) then by default the name init is used; (3) the function used for sampling the value of the variable considered, it could be either a R function or an user-defined function (in this case it has to be implemented into the R script passed through the functions_fname input parameter). Let us note that the output of this function must have size equal to the length of the varying parameter, that is 1 when tags p or g are used, and the size of the marking (number of places) when i is used. The remaining columns represent the input parameters needed by the functions defined in the third column.
#' @param functions_fname an R file storing: 1) the user defined functions to generate instances of the parameters summarized in the *parameters_fname* file, and
#'  2) the functions to compute: the distance (or error) between the model output and the reference dataset itself (see *reference_data* and *distance_measure_fname*), and
#'  the discrete events which may modify the marking of the net at specific time points (see *event_function*).
#' @param volume The folder to mount within the Docker image providing all the necessary files.
#' @param timeout Maximum execution time allowed to each configuration.
#' @param parallel_processors Integer for the number of available processors to use for parallelizing the simulations.
#' @param ini_v Initial values for the parameters to be optimized.
#' @param lb_v,ub_v Vectors with length equal to the number of parameters which are varying. Lower/Upper bounds for each parameter.
#' @param threshold.stop,max.call,max.time These are GenSA arguments, which can be used to control the behavior of the algorithm. (see \code{\link{GenSA}})
#'  \itemize{
#'    \item threshold.stop (Numeric) represents the threshold for which the program will stop when the expected objective function value will reach it. Default value is NULL.
#'    \item max.call (Integer) represents the maximum number of call of the objective function. Default is 1e7.
#'    \item max.time (Numeric) is the maximum running time in seconds. Default value is NULL.
#'  } These arguments not always work, actually.
#' @param reference_data csv file storing the data to be compared with the simulations’ result.
#' @param distance_measure String reporting the distance function, implemented in *functions_fname*, to exploit for ranking the simulations.
#'  Such function takes 2 arguments: the reference data and a list of data_frames containing simulations' output.
#'  It has to return a data.frame with the id of the simulation and its corresponding distance from the reference data.
#' @param event_times Vector representing the time points at which the simulation has to stop in order to
#' simulate a discrete event that modifies the marking of the net given a specific rule defined in *functions_fname*.
#' @param event_function String reporting the function, implemented in *functions_fname*, to exploit for modifying the total marking at a specific time point.
#' Such function takes in input: 1) a vector representing the marking of the net (called *marking*), and 2) the time point at which the simulation has stopped (called *time*).
#' In particular, *time* takes values from *event_times*.
#' @param extend If TRUE the actual configuration is extended including n_config new configurations.
#' @param seed .RData file that can be used to initialize the internal random generator.
#' @param out_fname Prefix to the output file name
#' @param debug If TRUE enables logging activity.
#'
#' @details
#' In order to run the simulations, the user must provide a reference dataset and the definition of a function to compute the distance (or error) between the models' output and the reference dataset itself.
#' The function defining the distance has to be in the following form:
#'
#' FUNCTION_NAME(reference_dataset, simulation_output)
#'
#' Moreover, the function must return a column vector with one entry for each evaluation point (i.e. f_time/s_time entries).
#' In addition to that, the user is asked to provide a function that, given the output of the solver, returns the relevant measure (one column) used to evaluate the quality of the solution.
#'
#' The sensitivity analysis will be performed through a Monte Carlo sampling through user defined functions.
#' The parameters involved in the sensitivity analysis have to be listed in a cvs file using the following structure:
#'
#' OUTPUT_FILE_NAME, FUNCTION_NAME, LIST OF PARAMETERS (comma separated)
#'
#' The functions allowed to compute the parameters are either R functions or user defined functions. In the latter case, all the user defined functions must be provided in a single .R file (which will be passed to model_calibration through the parameter parameters_fname)
#'
#' Exploiting the same mechanism, user can provide an initial marking to the solver. However, if it is the case the corresponding file name in the parameter list must be set to "init"
#'
#' To drive the optimization, the user has to provide a function to generate a new configuration, starting from a vector of n elements (each one ranging from 0 to 1).
#' Furthermore, the vector ini_v defines the initial point of the search.
#'
#' IMPORTANT: the length of the vector init_v defines the number of variables to variate within the search of the optimal configuration.
#' @author Beccuti Marco, Castagno Paolo, Pernice Simone, Baccega Daniele
#'
#' @example SIR
#'
#' @export

model.calibration <- function(# Parameters to control the simulation
															solver_fname,
															i_time = 0, f_time, s_time,
															solver_type = "LSODA", taueps = 0.01, n_run = 1,
													    # User defined simulation's parameters
													    parameters_fname = NULL, functions_fname = NULL,
													    # Parameters to manage the simulations' execution
													    volume = getwd(), timeout = '1d', parallel_processors = 1,
													    # Vectors to control the optimization
													    ini_v, lb_v, ub_v, ini_vector_mod = FALSE,
													    # Variables controlling optimization termination
													    threshold.stop = NULL, max.call = 1e7, max.time = NULL,
													    # Parameters to control the ranking
													    # reference_data = NULL, distance_measure_fname = NULL,
															reference_data = NULL, distance_measure = NULL,
															# List of discrete events
															event_times = NULL, event_function = NULL,
													    # Mange reproducibility
													    seed = NULL,
													    # Directories
													    out_fname = NULL,
													    #Flag to enable logging activity
													    debug = FALSE
														 ){

    # This function receives all the parameters that will be tested for model_calibration function
    ret = common_test(parameters_fname = parameters_fname,
                      functions_fname = functions_fname,
                      solver_fname = solver_fname,
                      reference_data = reference_data,
                      # distance_measure_fname = distance_measure_fname ,
                      solver_type = solver_type,
                      n_run = n_run,
    									i_time = i_time,
                      f_time = f_time,
                      s_time = s_time,
                      ini_v = ini_v,
                      ub_v = ub_v,
                      lb_v = lb_v,
                      volume = volume,
    									seed = seed,
                      parallel_processors = parallel_processors,
                      caller_function = "calibration")
    if(ret != TRUE)
        stop(paste("model_calibration_test error:", ret, sep = "\n"))

    results_dir_name <- paste0(basename(tools::file_path_sans_ext(solver_fname)), "_calibration/")
    chk_dir <- function(path){
        pwd <- basename(path)
        return(paste0(file.path(dirname(path), pwd, fsep = .Platform$file.sep), .Platform$file.sep))
    }

    files <- list()
    # Fix input parameter out_fname
    if(!is.null(solver_fname)){
        solver_fname <- tools::file_path_as_absolute(solver_fname)
        files[["solver_fname"]] <- solver_fname
    }
    if (is.null(out_fname))
    {
        out_fname <- paste0(basename(tools::file_path_sans_ext(solver_fname)), "-calibration")
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
    if  (!is.null(reference_data))
    {
        reference_data <- tools::file_path_as_absolute(reference_data)
        files[["reference_data"]] <- reference_data
    }
    # if(!is.null(distance_measure_fname))
    # {
    #     distance_measure_fname <- tools::file_path_as_absolute(distance_measure_fname)
    #     files[["distance_measure_fname"]] <- distance_measure_fname
    # }
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
                   taueps = taueps,
                   i_time = i_time,
                   f_time = f_time,
                   s_time = s_time,
                   n_run = n_run,
                   volume = volume,
                   timeout = timeout,
                   # distance_measure = tools::file_path_sans_ext(basename(distance_measure_fname)),
                   distance_measure = distance_measure,
                   ini_v = ini_v,
                   lb_v = lb_v,
                   ub_v = ub_v,
                   ini_vector_mod = ini_vector_mod,
                   threshold.stop = threshold.stop,
                   max.call = max.call,
                   max.time = max.time,
                   files = files,
                   parallel_processors = parallel_processors,
                   event_times = event_times,
                   event_function = event_function)
    res_dir <- paste0(chk_dir(volume), results_dir_name)
    if(file.exists(res_dir)){
    	unlink(res_dir, recursive = TRUE)
    }
    dir.create(res_dir, showWarnings = FALSE)
    # Copy all the files to the directory docker will mount to the image's file system
    experiment.env_setup(files = files, dest_dir = res_dir)
    # Change path to the new files' location
    files <- lapply(files, function(x){
        return(paste0(params$out_dir, basename(x)))
    })
    params$files <- files

    # file.copy(from = target_value_fname, to = res_dir)
    # Manage experiments reproducibility
    if(!is.null(seed)){
    	params$seed <- paste0(params$out_dir, "seeds-", out_fname, ".RData")
    }

    parms_fname <- paste0(chk_dir(res_dir), "params_", out_fname, ".RDS")
    saveRDS(params, file = parms_fname, version = 2)

    parms_fname <- paste0(params$out_dir, basename(parms_fname))
    # Run the docker image
    containers.file=paste(path.package(package = "epimod"), "Containers/containersNames.txt", sep = "/")
    containers.names=read.table(containers.file, header=T, stringsAsFactors = F)
    docker.run(params = paste0("--cidfile=dockerID ", "--volume ", volume, ":", dirname(params$out_dir), " -d ", containers.names["calibration", 1], " Rscript /usr/local/lib/R/site-library/epimod/R_scripts/calibration.mngr.R ", parms_fname), debug = debug)
}
