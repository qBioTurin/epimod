#' @title Run model calibration
#' @description this functon takes as input a solver and all the required parameters to set up a dockerized running environment to perform model calibration. both for deterministic and stochastic models
#' In order to run the simulations, the user must provide a reference dataset and the definition of a function to compute the distance (or error) between the models' output and the reference dataset itself.
#' The function defining the distance has to be in the following form:
#'
#' FUNCTION_NAME(reference_dataset, siulation_output)
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
#' @param config_fname File collecting all the configurations generated in the sensitivity analysis
#' @param functions_fname File with the user defined functions to generate istances of the parameters
#' @param solver_fname .solver file (generated in with the function model_generation)
#' @param int_fname File containing the initial marking, if required
#' @param f_time Final solution time
#' @param s_time Time step at whicch explicit estimates for the system are desired
#' @param out_fname Prefix to the output file name
#' @param volume The folder to mount within the Doker image providing all the necessary files
#' @param reference_data Data to compare with the simulations' results
#' @param distance_measure_fname File containing the definition of a distance measure to rank the simulations'. Such function takes 2 arguments: the reference data and a list of data_frames containing simulations' output. It has to return a data.frame with the id of the simulation and its corresponding distance from the reference data
#' @param distance_measure The name of the function defining the distance measure
#' @param out_dir Directory where to store all the output generated
#' @author Paolo Castagno
#'
#' @examples
#'\dontrun{
#' local_dir <- "/some/path/to/the/directory/hosting/the/input/files/"
#' base_dir <- "/root/scratch/"
#' library(EpiTCM)
#' model_calibration(out_dir = paste0(base_dir, "Res/"),
#'                   out_fname = "calibration",
#'                   parameters_fname = paste0(local_dir, "Configuration/Functions_list.csv"),
#'                   functions_fname = paste0(local_dir, "Configuration/Functions.R"),
#'                   solver_fname = paste0(local_dir, "Configuration/Solver.solver"),
#'                   init_fname = "init",
#'                   f_time = 365*21,
#'                   s_time = 365,
#'                   volume = volume = "/some/path/to/the/local/output/directory",
#'                   timeout = "1d",
#'                   processors=4,
#'                   reference_data = paste0(local_dir, "Configuration/reference_data.csv"),
#'                   distance_measure_fname = paste0(local_dir, "Configuration/Measures.R"),
#'                   distance_measure = "msqd",
#'                   target_value_fname = paste0(local_dir, "Configuration/Select.R"),
#'                   target_value_f = "infects",
#'                   # Vectors to control the optimization
#'                   ini_v = c(0.48264229, 0.17799173, 0.43572218, 0.06540719, 0.49887063, 0.36793130, 0.01818745, 0.18572619, 0.42815506, 0.07962422, 0.35074813, 0.35074813, 0.36386227),
#'                   ub_v = c(1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1),
#'                   lb_v = c(0, 0, 1e-7, 1e-7, 1e-7, 1e-7, 1e-7, 1e-7, 1e-7, 1e-7, 1e-7, 1e-7, 1e-7),
#'                   nb.stop.improvement = 3000000)
#'
#' @export
model_calibration <-function(
    # Directories
    out_dir, out_fname,
    # User defined simulation's parameters
    parameters_fname = "", functions_fname = "",
    # Parameters to control the simulation
    solver_fname, solver_type = "LSODA", init_fname = NULL, f_time, s_time, n_run=1,
    # Parameters to manage the simulations' execution
    volume = "", timeout = '1d', processors,
    # Vectors to control the optimization
    ini_v, lb_v, ub_v, nb.stop.improvement,
    # Parameters to control the ranking
    reference_data, distance_measure_fname, distance_measure,
    target_value_fname, target_value_f,
    seed = NULL, extend = NULL){

    chk_dir<- function(path){
        pwd <- basename(path)
        return(paste0(file.path(dirname(path),pwd, fsep = .Platform$file.sep), .Platform$file.sep))
    }

    files <- list(
        parameters_fname = parameters_fname,
        functions_fname = functions_fname,
        solver_fname = solver_fname,
        distance_measure_fname = distance_measure_fname,
        reference_data = reference_data
    )
    params <- list(out_dir = "/root/scratch/Res/",
                   out_fname = out_fname,
                   run_dir = "/root/scratch/Run/",
                   solver_type = solver_type,
                   init_fname = init_fname,
                   f_time = f_time,
                   s_time = s_time,
                   n_run = n_run,
                   volume = volume,
                   timeout = timeout,
                   distance_measure = distance_measure,
                   ini_v = ini_v,
                   lb_v = lb_v,
                   ub_v = ub_v,
                   nb.stop.improvement = nb.stop.improvement,
                   files = files,
                   extend = extend,
                   seed = seed,
                   processors = processors)

    # Copy all the files to the directory docker will mount to the image's file system
    experiment.env_setup(files = files, dest_dir = volume)
    # Change path to the new files' location
    files <- lapply(files, function(x){
        return(paste0(out_dir,basename(x)))
    })
    params$files <- files
    parms_fname <- paste0(chk_dir(volume),"params_",out_fname,".RDS")
    saveRDS(params, file = parms_fname, version = 2)
    file.copy(from = target_value_fname, to = volume)
    # Manage experiments reproducibility
    if(!is.null(seed)){
        params$seed <- paste0(params$out_dir,basename(seed))
        file.copy(from = seed, to = volume )
        if(!is.null(extend)){
            params$extend <- paste0(params$out_dir,basename(extend))
            file.copy(from = extend, to = volume )
        }
    }
    parms_fname <- paste0(params$out_dir, basename(parms_fname))
    cat(paste0("docker run -cidfile=dockerID ","--volume ", volume,":",out_dir," -d epip_calibration Rscript /root/scratch/R_scripts/calibration.mngr.R ", parms_fname))
    docker.run(params = paste0("--cidfile=dockerID ","--volume ", volume,":",out_dir," -d epip_calibration Rscript /root/scratch/R_scripts/calibration.mngr.R ", parms_fname))

}
