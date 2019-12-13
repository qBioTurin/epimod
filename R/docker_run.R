#' @title Run docker container
#' @description This is an internal function executing a docker container. Not to be used by users.
#' @param params, a character string containing all parameters needed to run the docker container
#' @param DockerSwarm, a bolean value used to enable docker execution in swarm mode.
#' @return 0 if success, 1 if parameters are missing, 2 if dockerid file is present, 3 if docker execution fails.
#' @author Marco Beccuti
#'
#' @examples
#'\dontrun{
##'     #running runDocker
#'      docker.run(params=NULL)
#'
#' }
#' @export
docker.run <- function( params=NULL){

    if(is.null(params)){
        cat("\nNo parameters where provided!\n")
        system("echo 1 > ExitStatusFile 2>&1")
        return(1)
    }

    # to check the Docker ID by file
    if (file.exists("dockerID")){
        cat("\n\nDocker does not start, there is already a docker container running che dockerID file!!!\n\n")
        system("echo 2 > ExitStatusFile 2>&1")
        return(2)
    }

    ## to execute docker
    cat(paste("docker run --privileged=true ",params,"\n\n", sep=""))
    system(paste("docker run --privileged=true ",params, sep=""))

    ## to obtain the Docker ID by file
    dockerid=readLines("dockerID", warn = FALSE)
    cat("\nDocker ID is:\n",substr(dockerid,1, 12),"\n")

    ## to check the Docker container status
    dockerStatus=system(paste("docker inspect -f {{.State.Running}}",dockerid),intern= T)
    while(dockerStatus=="true"){
        Sys.sleep(10);
        dockerStatus=system(paste("docker inspect -f {{.State.Running}}",dockerid),intern= T)
        cat(".")
    }
    cat(".\n\n")
    ## to check the Docker container status
    dockerExit <- system(paste("docker inspect -f {{.State.ExitCode}}",dockerid),intern= T)
    cat("\nDocker exit status:",dockerExit,"\n\n")
    if(as.numeric(dockerExit)!=0){
        system(paste("docker logs ", substr(dockerid,1,12), " &> ", substr(dockerid,1,12),"_error.log", sep=""))
        cat(paste("\nDocker container ", substr(dockerid,1,12), " had exit different from 0\n", sep=""))
        cat("\nExecution is interrupted\n")
        cat(paste("Please send to beccuti@unito.it this error: Docker failed exit 0,\n the description of the function you were using and the following error log file,\n which is saved in your working folder:\n", substr(dockerid,1,12),"_error.log\n", sep=""))
        system("echo 3 > ExitStatusFile 2>&1")
        return(3)
    }


    file.remove("dockerID")
    system(paste("docker rm -f ",dockerid),intern= T)

    #Normal Docker execution
    system("echo 0 > ExitStatusFile 2>&1")
    return(0)
}
