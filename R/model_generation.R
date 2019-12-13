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
#' @param out_fname Prefix to the output file name
#' @param net_fname .PNPRO file storing  the model as ESPN. In case there are multiple nets defined within the PNPRO file, the first one in the list is the will be automatically selected;
#' @param functions_fname  C++ file defining the functions managing the behaviour of general transitions.
#' @author Beccuti Marco, Castagno Paolo, Pernice Simone

#'
#' @examples
#'\dontrun{
#' local_dir <- "/some/path/to/the/directory/hosting/the/input/files/"
#' model_generation(out_fname = "Solver",
#'                  net_fname = paste0(local_dir, "Configuration/Pertussis"),
#'                  functions_fname = "transitions.cpp")
#'
#' @export
model_generation <-function( out_fname = NULL,
                             net_fname,
                             functions_fname=NULL ){

    chk_dir<- function(path){
        pwd <- basename(path)
        return(paste0(file.path(dirname(path),pwd, fsep = .Platform$file.sep), .Platform$file.sep))
    }



    # Create temp files and dirs
    tmp_dir <- paste0(chk_dir(tempdir()),"generation_tmp/")
    dir.create(path = tmp_dir,showWarnings = FALSE)
    if(!is.null(out_fname)){
        # Rename the .PNPRO file so that the generated output files will match the out_fname specified by the user
        netname <- paste0(tmp_dir,out_fname,".PNPRO")
        file.copy(from = net_fname, to = netname)
        netname <- tools::file_path_sans_ext(netname)
    }else{
        file.copy(from = net_fname, to = tmp_dir)
        netname <- tools::file_path_sans_ext(basename(net_fname))

    }
    file.copy(from = functions_fname, to = tmp_dir)
    # Set commandline to unfold the PN

    #reading docker image names
    containers.file=paste(path.package(package="epimod"),"Containers/containersNames.txt",sep="/")
    containers.names=read.table(containers.file,header=T,stringsAsFactors = F)

    pwd <- getwd()
    setwd(tmp_dir)
    cmd = paste0("unfolding2 /home/", basename(netname), " -long-names")
    docker.run(params = paste0("--cidfile=dockerID ","--volume ", tmp_dir,":/home/ -d ", containers.names["generation",1]," ", cmd))
    cmd = paste0("PN2ODE.sh /home/", basename(netname), " -M")
    if (!is.null(functions_fname)){
     cmd= paste0(cmd," -C ", paste0("/home/",basename(functions_fname)))
    }


    docker.run(params = paste0("--cidfile=dockerID ","--volume ", tmp_dir,":/home/ -d ", containers.names["generation",1]," ", cmd))
    setwd(pwd)
    file.copy(paste0(tmp_dir, netname, ".solver"), chk_dir(dirname(net_fname)))


    unlink(tmp_dir, recursive = TRUE)
}
