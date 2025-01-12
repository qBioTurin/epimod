#' @title Download for the first time all containers embedded in the workflows
#' @description This is a function that prepares the docker environment to be used for the first time the epimod is installed.
#' @param containers.file, a character string with the name of the file which indicate which are the initial set of containers to be downloaded. If NULL then the set is given by a file called "containersNames.txt" located in the folder inst/Containers of epimod package.
#' @author Beccuti Marco, Castagno Paolo, Pernice Simone
#'
#' @examples
#'\dontrun{
##'     #running runDocker
#'      downloadContainers()
#'
#' }
#' @export


# OLD VERSION
#downloadContainers <- function(containers.file=NULL, tag = "latest"){
#	if (is.null(containers.file))
#	{
#		containers.file = paste(path.package(package="epimod"),"Containers/containersNames.txt",sep="/")
#		containers <- read.table(containers.file,
#														 header = TRUE,
#														 row.names = 1)
#	} else {
#		containers <- read.table(containers.file,
#														 header = TRUE,
#														 row.names = 1)
#	}
#
#	if(is.null(tag))
#	{

#		tag <- packageVersion("epimod")
#		curr.tag <- gsub(pattern = "([[:alpha:]]+){1}(/epimod){1}(-[[:alpha:]]+:){1}",
#										 replacement = "",
#										 x = containers$names)
#		curr.tag <- unique(curr.tag)
#		containers$names <- gsub(pattern = curr.tag,
#														 replacement = tag,
#														 x = containers$names)
#	} else {
#		curr.tag <- gsub(pattern = "([[:alpha:]]+){1}(/epimod){1}(-[[:alpha:]]+:){1}",
#										 replacement = "",
#										 x = containers$names)
#		curr.tag <- unique(curr.tag)
#		containers$names <- gsub(pattern = curr.tag,
#														 replacement = tag,
#														 x = containers$names)
#	}
#	userid=system("id -u", intern = TRUE)
#	username=system("id -un", intern = TRUE)
#	for (i in dim(containers)[1]:1)
#	{
#		status <- system(paste("docker pull ",containers[i,1],
#													 sep = ""))
#		if (status)
#		{
#			containers <- containers[-i]
#		}
#		else
#		{
#			command=NULL
#			if (grepl("generation",containers[i,1],fixed=TRUE)==1)
#				command=c(paste("FROM", containers[i,1]),"RUN sudo groupmod -g 2005 docker && sudo usermod -u 2005 docker ", paste("RUN sudo /usr/sbin/adduser --allow-bad-names -u", userid, username), "  WORKDIR /home")
#			else
#				command=c(paste("FROM", containers[i,1]),"RUN sudo groupmod -g 2005 docker && sudo usermod -u 2005 docker ",paste("RUN /usr/sbin/adduser --allow-bad-names -u", userid, username), "  WORKDIR /home" )
#			writeLines(command,"./dockerfile")
#			status <- system(paste("docker build -f ./dockerfile -t ",containers[i,1], "_",username," .",
#														 sep = ""))
#			if (status){
#				print("Error in building container", paste(containers[i,1], "_",userid,sep = ""))
#			}
#		}
#	}
#	write.table(containers,
#							paste(path.package(package = "epimod"),"Containers/containersNames.txt",
#										sep = "/"))
#	system("rm ./dockerfile")
#}


# TEST

#downloadContainers <- function(containers.file = NULL, tag = "latest") {
#  if (is.null(containers.file)) {
#    containers.file <- paste(path.package(package = "epimod"), "Containers/containersNames.txt", sep = "/")
#  }
#  containers <- read.table(containers.file, header = TRUE, row.names = 1)
  
  # Forza il tag corretto
#  containers$names <- gsub("latest", tag, containers$names, ignore.case = TRUE)
  
#  userid <- system("id -u", intern = TRUE)
#  username <- system("id -un", intern = TRUE)
  
#  for (i in seq_len(nrow(containers))) {
#    container_name <- containers[i, "names"]
#    if (grepl("generation", container_name, fixed = TRUE)) {
#      command <- c(
#        paste("FROM", container_name),
#        "RUN sudo groupmod -g 2005 docker && sudo usermod -u 2005 docker",
#        paste("RUN sudo /usr/sbin/adduser --allow-bad-names -u", userid, username),
#        "WORKDIR /home"
#      )
#    } else {
#      command <- c(
#        paste("FROM", container_name),
#        "RUN sudo groupmod -g 2005 docker && sudo usermod -u 2005 docker",
#        paste("RUN sudo /usr/sbin/adduser --allow-bad-names -u", userid, username),
#        "WORKDIR /home"
#      )
#    }
#    writeLines(command, "./dockerfile")
    
    # Usa build invece di pull
#    status <- system(paste("docker build -f ./dockerfile -t ", container_name, "_", username, " .", sep = ""))
#    if (status != 0) {
#      print(paste("Error in building container", container_name, sep = " "))
#    }
#  }
  
  
  
  # Salva il file aggiornato
#  write.table(containers, paste(path.package(package = "epimod"), "Containers/containersNames.txt", sep = "/"))
#  system("rm ./dockerfile")
#}


# TMP downloadContainers().

downloadContainers <- function(containers.file = NULL, tag = "latest") {
  if (is.null(containers.file)) {
    containers.file <- paste(path.package(package = "epimod"), "Containers/containersNames.txt", sep = "/")
  }
  
  username <- system("id -un", intern = TRUE)

  containers <- read.table(containers.file, header = TRUE, row.names = 1)
  
  for (i in seq_len(nrow(containers))) {
    original_container_name <- containers[i, "names"]
    modified_container_name <- gsub("latest", paste0(tag, "_", username), original_container_name, ignore.case = TRUE)
    
    message(paste("Pulling container:", original_container_name))
    status_pull <- system(paste("docker pull", original_container_name))
    
    if (status_pull != 0) {
      warning(paste("Failed to pull container:", original_container_name))
    } else {
      message(paste("Successfully pulled:", original_container_name))
      
      message(paste("Renaming container from", original_container_name, "to", modified_container_name))
      status_tag <- system(paste("docker tag", original_container_name, modified_container_name))
      if (status_tag != 0) {
        warning(paste("Failed to tag container:", original_container_name, "as", modified_container_name))
      } else {
        message(paste("Successfully renamed:", modified_container_name))
      }
    }
  }
  
  write.table(
    containers,
    paste(path.package(package = "epimod"), "Containers/containersNames.txt", sep = "/"),
    row.names = TRUE,
    col.names = TRUE,
    quote = FALSE
  )
}


