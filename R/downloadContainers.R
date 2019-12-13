#' @title Download for the first time all containers embedded in the workflows
#' @description This is a functin that preapre the docker environment to be used for the first time the docker4seq is installed.
#' @param group, a character string. Two options: \code{"sudo"} or \code{"docker"}, depending to which group the user belongs
#' @param containers.file, a character string with the name of the file which indicate which are the initial set of containers to be downloaded. Initally the set is given by a file located in the folder containers of docker4seq package: "all", "rnaseq", "ncrnaseq", "chipseq"
#' @author Raffaele Calogero
#'
#' @examples
#'\dontrun{
##'     #running runDocker
#'      downloadContainers(group="docker", containers.file)
#'
#' }
#' @export
downloadContainers <- function(containers.file=NULL){
    if(is.null(containers.file)){
        containers.file=paste(path.package(package="epimod"),"Containers/containersNames.txt",sep="/")
        containers <-read.table(containers.file,header=TRUE,row.names = 1)
    }
    else{
        containers <-read.table(containers.file,header=TRUE,row.names = 1)
    }


    for(i in 1:dim(containers)[1]){
        system(paste("docker pull ",containers[i,1], sep=""))
    }
    #writeLines(containers, paste(path.package(package="epimod"),"Containers/containersNames.txt",sep="/"))
}
