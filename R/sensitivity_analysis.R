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
#'                      f_time = 365*21,
#'                      s_time = 365,
#'                      volume = "/some/path/to/the/local/output/directory",
#'                      timeout = "1d",
#'                      parallel_processors=4,
#'                      reference_data = paste0(local_dir, "Configuration/reference_data.csv"),
#'                      distance_measure_fname = paste0(local_dir, "Configuration/Measures.R"),
#'                      target_value_fname = paste0(local_dir, "Configuration/Select.R"))
#' }
#' @export
sensitivity_analysis <-function(# Parameters to control the simulation
                                solver_fname, f_time, s_time,
                                # User defined simulation's parameters
                                n_config, parameters_fname = NULL, functions_fname = NULL,
                                # Parameters to manage the simulations' execution
                                volume = getwd(), timeout = '1d', parallel_processors = 1,
                                # Parameters to control the ranking
                                reference_data = NULL, distance_measure_fname = NULL,
                                # Parameters to control PRCC
                                target_value_fname = NULL,
                                # Mange reproducibilty and extend previous experiments
                                extend = NULL, seed = NULL,
                                # Directories
                                out_fname = NULL
                                ){

    chk_dir<- function(path){
        pwd <- basename(path)
        return(paste0(file.path(dirname(path), pwd, fsep = .Platform$file.sep), .Platform$file.sep))
    }
    files <- list()
    # Fix input parameter out_fname
    if(is.null(solver_fname))
    {
        stop("Missing solver file! Abort")
    }
    else
    {
        solver_fname <- tools::file_path_as_absolute(solver_fname)
        files[["solver_fname"]] <- solver_fname
    }
    if(is.null(out_fname))
    {
        out_fname <- paste0(basename(tools::file_path_sans_ext(solver_fname)),"-sensitivity")
    }
    # Fix input parameters path
    if(is.null(volume))
    {
        volume <- tools::file_path_sans_ext(basename(solver_fname))
    }

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
    if(!is.null(target_value_fname))
    {
        target_value_fname <- tools::file_path_as_absolute(target_value_fname)
        files[["target_value_fname"]] <- target_value_fname
    }

    # Global parameters used to manage the dockerized environment
    parms_fname <- file.path(paste0("params_",out_fname), fsep = .Platform$file.sep)
    parms <- list(n_config = n_config,
                  run_dir = chk_dir("/root/scratch/"),
                  out_dir = chk_dir("/root/data/results_sensitivity_analysis/"),
                  out_fname = out_fname,
                  solver_fname = solver_fname,
                  f_time = f_time,
                  s_time = s_time,
                  parallel_processors = parallel_processors,
                  volume = volume,
                  timeout = timeout,
                  files = files)

    # Create the folder to store results
    res_dir <- paste0(chk_dir(volume),"results_sensitivity_analysis/")
    dir.create(res_dir, showWarnings = FALSE,recursive = TRUE)
    volume <- tools::file_path_as_absolute(volume)
    # Copy all the files to the directory docker will mount to the image's file system
    experiment.env_setup(files = files, dest_dir = res_dir)
    # Change path to the new files' location
    if(length(files) > 0)
    {
        parms$files <- lapply(files, function(x){
            return(paste0(parms$out_dir,basename(x)))
        })
    }
    # removed parms$target_value_fname and inserted in files -> check if it works
    # file.copy(target_value_fname, to = paste0(res_dir, basename(target_value_fname)))
    # parms$target_value_fname <- paste0(parms$out_dir, basename(target_value_fname))
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
    containers.file=paste(path.package(package="epimod"),"Containers/containersNames.txt",sep="/")
    containers.names=read.table(containers.file,header=T,stringsAsFactors = F)
    docker.run(params = paste0("--cidfile=dockerID ","--volume ", volume,":/root/data -d ", containers.names["sensitivity",1]," Rscript /usr/local/lib/R/site-library/epimod/R_scripts/sensitivity.mngr.R ", p_fname))
}
