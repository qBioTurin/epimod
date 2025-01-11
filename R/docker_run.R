#'
#' @title Run docker container
#'
#' @description This is an internal function executing a docker container. Not to be used by users.
#' @param params, a character string containing all parameters needed to run the docker container.
#' @return 0 if success, 1 if parameters are missing, 2 if dockerid file is present, 3 if docker execution fails.
#' @author Beccuti Marco, Castagno Paolo, Pernice Simone
#'
#' @examples
#'\dontrun{
##'     #running runDocker
#'      docker.run(params=NULL, changeUID=TRUE, debug=FALSE)
#'
#' }

docker.run <- function(params = NULL, changeUID = TRUE, debug = FALSE) {

    if (is.null(params)) {
        cat("\nNo parameters were provided!\n")
        system("echo 1 > ExitStatusFile 2>&1")
        return(1)
    }

    # Controlla se esiste un container già in esecuzione
    if (file.exists("dockerID")) {
        cat("\n\nDocker does not start, there is already a docker container running with the dockerID file!!!\n\n")
        system("echo 2 > ExitStatusFile 2>&1")
        return(2)
    }

    ## Comando per eseguire il container
    if (changeUID) {
        userid <- system("id -u", intern = TRUE)
        groupid <- system("id -g", intern = TRUE)
        cat(paste("docker run --privileged  --user=", userid, ":", groupid, " ", params, "\n\n", sep = ""))
        system(paste("docker run --privileged --user=", userid, ":", groupid, " ", params, sep = ""))
    } else {
        cat(paste("docker run --privileged ", params, "\n\n", sep = ""))
        system(paste("docker run --privileged ", params, sep = ""))
    }

    # Recupera il Docker ID dal file
    dockerid <- readLines("dockerID", warn = FALSE)
    cat("\nDocker ID is:\n", substr(dockerid, 1, 12), "\n")

    ## Controlla lo stato del container
    dockerStatus <- system(paste("docker inspect -f {{.State.Running}}", dockerid), intern = TRUE)
    while (dockerStatus == "true") {
        Sys.sleep(10)
        dockerStatus <- system(paste("docker inspect -f {{.State.Running}}", dockerid), intern = TRUE)
        cat(".")
    }
    cat(".\n\n")

    ## Controlla lo stato di uscita del container
    dockerExit <- system(paste("docker inspect -f {{.State.ExitCode}}", dockerid), intern = TRUE)

    if (as.numeric(dockerExit) != 0) {
        cat("\nExecution is interrupted\n")
        system(paste("docker logs ", substr(dockerid, 1, 12), " &> ", substr(dockerid, 1, 12), "_error.log", sep = ""))
        cat(paste("Please send to beccuti@unito.it this error: Docker failed exit 0,\n the description of the function you were using and the following error log file,\n which is saved in your working folder:\n", substr(dockerid, 1, 12), "_error.log\n", sep = ""))
        system("echo 3 > ExitStatusFile 2>&1")
        return(3)
    } else {
        cat("\nDocker exit status:", dockerExit, "\n\n")
        file.remove("dockerID")
        if (debug == TRUE) {
            system(paste("docker logs ", substr(dockerid, 1, 12), " &> ", substr(dockerid, 1, 12), ".log", sep = ""))
            cat("The container's log is saved at: ")
            system(paste0("docker inspect --format=", "'{{.LogPath}}' ", dockerid))
        }
        system(paste("docker rm -f ", dockerid), intern = TRUE)
        # Normale esecuzione Docker
        system("echo 0 > ExitStatusFile 2>&1")
        return(0)
    }
}

