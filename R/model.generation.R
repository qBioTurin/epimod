#' @title Run model generation
#' @description
#'   Having constructed the model exploiting the graphical editor, namely GreatSPN, the automatic generation of both the stochastic (the Continuous Time Markov Chain) and
#'   deterministic (ODEs) processes underlying the model is implemented by the model_generation() function.
#'
#' @param out_fname Prefix to the output file name.
#' @param net_fname .PNPRO file storing the Petri Net (and all its generalizations) model. In case there are multiple nets defined within the PNPRO file, the first one in the list is the will be automatically selected.
#' @param transitions_fname C++ file defining the functions managing the behaviour of general transitions, mandatory if Extended versions of Petri Nets (i.e., ESPN or ESSN) are used.
#' @param fba_fname vector of .txt files encoding different flux balance analysis problems, which as to be included in the general transitions (*transitions_fname*). (default is NULL)
#' @param volume The folder to mount within the Docker image providing all the necessary files.
#' @param debug If TRUE enables logging activity.

#' @author Beccuti Marco, Castagno Paolo, Pernice Simone, Baccega Daniele

#' @return model.generation returns the binary file SIR.solver in which the underlying processes (both deterministic and stochastic) of the Petri Net model and the library used for their simulation are packaged.
#'
#' @examples
#' \dontrun{
#' local_dir <- "/some/path/to/the/directory/hosting/the/input/files/"
#' model.generation(out_fname = "Solver",
#'                  net_fname = paste0(local_dir, "Configuration/Pertussis"),
#'                  transitions_fname = "transitions.cpp")
#' }
#'
#' @details
#' GreatSPN GUI, the graphical editor for drawing Petri Nets formalism, is available online: http://www.di.unito.it/~amparore/mc4cslta/editor.html
#'
#' @export

model.generation <-function(out_fname = NULL,
                            net_fname,
                            transitions_fname = NULL,
														fba_fname = NULL,
                            volume = getwd(),
														#Flag to enable logging activity
														debug = FALSE){


    # This function receives all the parameters that will be tested for model_generation function
    ret = common_test(net_fname = net_fname,
    									functions_fname = transitions_fname,
    									volume = volume,
                      caller_function = "generation")

    if(ret != TRUE)
        stop(paste("model_generation_test error:", ret, sep = "\n"))

    chk_dir<- function(path){
        pwd <- basename(path)
        return(paste0(file.path(dirname(path),pwd, fsep = .Platform$file.sep), .Platform$file.sep))
    }

    volume <- tools::file_path_as_absolute(volume)
    # Create temp files and directories
    out_dir <- file.path(volume, "generation", fsep = .Platform$file.sep)
    if(file.exists(out_dir))
    {
        unlink(out_dir, recursive = TRUE)
    }
    dir.create(path = out_dir, showWarnings = FALSE)
    if(!is.null(out_fname)){
        # Rename the .PNPRO file so that the generated output files will match the out_fname specified by the user
        netname <- file.path(out_dir, paste0(out_fname, ".PNPRO"), fsep = .Platform$file.sep)
        file.copy(from = net_fname, to = netname)
        netname <- tools::file_path_sans_ext(netname)
    } else {
        file.copy(from = net_fname, to = out_dir)
        netname <- tools::file_path_sans_ext(basename(net_fname))

    }
    file.copy(from = transitions_fname, to = out_dir)
    # Set command line to unfold the PN

    # Reading docker image names
    containers.file=paste(path.package(package = "epimod"), "Containers/containersNames.txt", sep = "/")
    containers.names=read.table(containers.file, header=T, stringsAsFactors = F)

    pwd <- getwd()
    setwd(out_dir)

    cmd = paste0("unfolding2 /home/", basename(netname), " -long-names")
    err_code = docker.run(params = paste0("--cidfile=dockerID ", "--env PATH=\"$PATH:/usr/local/GreatSPN/scripts\" --volume ", out_dir, ":/home/ -d ", containers.names["generation", 1], " ", cmd), debug = debug, changeUID=FALSE)

    if ( err_code != 0 )
    {
        log_file <- list.files(pattern = "\\.log$")[1]
        setwd(pwd)
        file.copy(file.path(out_dir, log_file, fsep = .Platform$file.sep), pwd)
        cat("Scratch folder:", out_dir, "\n")
        stop()
    }

    cmd = paste0("PN2ODE.sh /home/", basename(netname), " -M")
    if (!is.null(transitions_fname)){
        cmd= paste0(cmd, " -C ", paste0("/home/", basename(transitions_fname)))
    }

    if(!is.null(fba_fname)){
    	fba_fname <- paste0(sapply(fba_fname,basename),collapse = " ")
    	cmd= paste0(cmd,paste0(" -H ",fba_fname,collapse = "") )
    }

    err_code <- docker.run(params = paste0("--cidfile=dockerID ", "--env PATH=\"$PATH:/usr/local/GreatSPN/scripts\" --volume ", out_dir, ":/home/ -d ", containers.names["generation", 1], " ", cmd), debug = debug, changeUID=FALSE)
    if ( err_code != 0 )
    {
        log_file <- list.files(pattern = "\\.log$")[1]
        setwd(pwd)
        file.copy(file.path(out_dir, log_file, fsep = .Platform$file.sep), chk_dir(dirname(tools::file_path_as_absolute(net_fname))))
        cat("Check ", out_dir, " for logs\n")
        stop()
    } else {
        setwd(pwd)
        file.copy(file.path(out_dir, paste0(basename(netname), ".solver"), fsep = .Platform$file.sep), chk_dir(volume), overwrite = TRUE)
        file.copy(file.path(out_dir, paste0(basename(netname), ".net"), fsep = .Platform$file.sep), chk_dir(volume), overwrite = TRUE)
        file.copy(file.path(out_dir, paste0(basename(netname), ".def"), fsep = .Platform$file.sep), chk_dir(volume), overwrite = TRUE)
        file.copy(file.path(out_dir, paste0(basename(netname), ".PlaceTransition"), fsep = .Platform$file.sep), chk_dir(volume), overwrite = TRUE)
        #file.copy(file.path(out_dir, paste0(basename(netname), ".cpp"), fsep = .Platform$file.sep), chk_dir(volume), overwrite = TRUE)
        unlink(out_dir, recursive = TRUE)
    }
}
