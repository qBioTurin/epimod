#' @title Run docker container
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

docker.run <- function( params=NULL, changeUID=TRUE, debug=FALSE){

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
    if(changeUID)
    {
        userid=system("id -u", intern = TRUE)
        groupid=system("id -g", intern = TRUE)
        cat(paste("docker run   --user=",userid,":",groupid," ",params,"\n\n", sep=""))
        system(paste("docker run   --user=",userid,":",groupid," ",params, sep=""))
    } else {
        cat(paste("docker run  ",params,"\n\n", sep=""))
    		system(paste("docker run  ",params, sep=""))
    }

    ## Get the Docker ID from file
    dockerid=readLines("dockerID", warn = FALSE)
    cat("\nDocker ID is:\n",substr(dockerid,1, 12),"\n")

    ## Check the Docker container status
    dockerStatus=system(paste("docker inspect -f {{.State.Running}}",dockerid),intern= T)
    while(dockerStatus=="true"){
        Sys.sleep(10);
        dockerStatus=system(paste("docker inspect -f {{.State.Running}}",dockerid),intern= T)
        cat(".")
    }
    cat(".\n\n")
    ## Check the Docker container exit status
    dockerExit <- system(paste("docker inspect -f {{.State.ExitCode}}",dockerid),intern= T)

    if(as.numeric(dockerExit)!=0){
    	cat("\nExecution is interrupted\n")
	    cat(paste("\nDocker container ", substr(dockerid,1,12), " had exit different from 0\n", sep=""))
    	system(paste("docker logs ", substr(dockerid,1,12), " &> ", substr(dockerid,1,12),"_error.log", sep=""))
	    # cat("The container's log is saved at: ")
	    # system(paste0("docker inspect --format=","'{{.LogPath}}' ",dockerid))
	    cat(paste("Please send to beccuti@unito.it this error: Docker failed exit 0,\n the description of the function you were using and the following error log file,\n which is saved in your working folder:\n", substr(dockerid,1,12),"_error.log\n", sep=""))
	    system("echo 3 > ExitStatusFile 2>&1")
	    return(3)
    }else{
    	cat("\nDocker exit status:",dockerExit,"\n\n")
    	file.remove("dockerID")
    	if(debug==TRUE){
    		system(paste("docker logs ", substr(dockerid,1,12), " &> ", substr(dockerid,1,12),".log", sep=""))
    		cat("The container's log is saved at: ")
    		system(paste0("docker inspect --format=","'{{.LogPath}}' ",dockerid))
    	}
    	system(paste("docker rm -f ",dockerid),intern= T)
    	#Normal Docker execution
    	system("echo 0 > ExitStatusFile 2>&1")
    	return(0)
    }
}
