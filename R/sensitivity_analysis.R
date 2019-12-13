#' @title Run sensitivity analisys
#' @description this functon takes as input a solver and all the required parameters to set up a dockerized running environment to perform the sensitivity analysis of the model.
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
#' @param n_config, number of configuratons to generate
#' @param parm_fname, file with the definition of user defined functions
#' @param parm_list, file listing the name of the functions, the parameters and the name under which the parameters have to be saved
#' @author Beccuti Marco, Castagno Paolo, Pernice Simone

#'
#' @examples
#'\dontrun{
#' local_dir <- "/some/path/to/the/directory/hosting/the/input/files/"
#' sensitivity_analysis(n_config = 2^4,
#'                      out_fname = "sensitivity",
#'                      parameters_fname = paste0(local_dir, "Configuration/Functions_list.csv"),
#'                      functions_fname = paste0(local_dir, "Configuration/Functions.R"),
#'                      solver_fname = paste0(local_dir, "Configuration/Solver.solver"),
#'                      init_fname = "init",
#'                      f_time = 365*21,
#'                      s_time = 365,
#'                      volume = "/some/path/to/the/local/output/directory",
#'                      timeout = "1d",
#'                      processors=4,
#'                      reference_data = paste0(local_dir, "Configuration/reference_data.csv"),
#'                      distance_measure_fname = paste0(local_dir, "Configuration/Measures.R"),
#'                      distance_measure = "msqd",
#'                      target_value_fname = paste0(local_dir, "Configuration/Select.R"),
#'                      target_value_f = "infects")
#' @export
sensitivity_analysis <-function(
                                n_config,
                                # Directories
                                out_fname,
                                # User defined simulation's parameters
                                parameters_fname = "", functions_fname = "",
                                # Parameters to control the simulation
                                solver_fname = "", init_fname = NULL, f_time, s_time,
                                # Parameters to manage the simulations' execution
                                volume = "", timeout = '1d', processors,
                                # Parameters to control the ranking
                                reference_data, distance_measure_fname, distance_measure,
                                # Parameters to control PRCC
                                target_value_fname, target_value_f,
                                # Mange reproducibilty and extend previous experiments
                                extend = NULL, seed = NULL
                                ){

    chk_dir<- function(path){
        pwd <- basename(path)
        return(paste0(file.path(dirname(path),pwd, fsep = .Platform$file.sep), .Platform$file.sep))
    }
    # Parameters used to set up the runing environment
    files <- list(
        parameters_fname = parameters_fname,
        functions_fname = functions_fname,
        solver_fname = solver_fname,
        distance_measure_fname = distance_measure_fname,
        reference_data = reference_data
    )
    # Global parameters used to manage the dockerized environment
    parms_fname <- file.path(paste0("params_",out_fname), fsep = .Platform$file.sep)
    parms <- list(n_config = n_config,
                  run_dir = chk_dir("/root/scratch/"),
                  out_dir = chk_dir("/root/data/results/"),
                  out_fname = out_fname,
                  solver_fname = solver_fname,
                  init_fname = init_fname,
                  f_time = f_time,
                  s_time = s_time,
                  processors = processors,
                  volume = volume,
                  timeout = timeout,
                  target_value_fname = target_value_fname,
                  target_value_f = target_value_f,
                  distance_measure = distance_measure,
                  files = files)
    # Create the folder to store results
    res_dir <- paste0(chk_dir(volume),"results/")
    dir.create(res_dir, showWarnings = FALSE)
    # Copy all the files to the directory docker will mount to the image's file system
    experiment.env_setup(files = files, dest_dir = res_dir)
    # Change path to the new files' location
    parms$files <- lapply(files, function(x){
        return(paste0(parms$out_dir,basename(x)))
    })
    file.copy(target_value_fname, to = paste0(res_dir, basename(target_value_fname)))
    parms$target_value_fname <- paste0(parms$out_dir, basename(target_value_fname))
    # Manage experiments reproducibility
    if(!is.null(seed)){
        parms$seed <- paste0(parms$out_dir,basename(seed))
        file.copy(from = seed, to = res_dir )
        if(!is.null(extend)){
            parms$extend <- paste0(parms$out_dir,basename(extend))
            file.copy(from = extend, to = res_dir )
        }
    }
    # Save all the parameters to file, in a location accessible from inside the dockerized environment
    p_fname <- paste0(res_dir, parms_fname,".RDS")
    # Use version = 2 for compatibility issue
    saveRDS(parms,  file = p_fname, version = 2)
    p_fname <- paste0( parms$out_dir, parms_fname,".RDS") # location on the docker image file system
    # Run the docker image
    docker.run(params = paste0("--cidfile=dockerID ","--volume ", volume,":/root/data -d epimod_sensitivity Rscript /usr/local/lib/R/site-library/epimod/R_scripts/sensitivity.mngr.R ", p_fname))
    file.remove("./dockerID")
}
