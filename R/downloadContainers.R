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

downloadContainers <- function(containers.file=NULL, tag = "latest"){
	if (is.null(containers.file))
	{
		containers.file = paste(path.package(package="epimod"),"Containers/containersNames.txt",sep="/")
		containers <- read.table(containers.file,
														 header = TRUE,
														 row.names = 1)
	} else {
		containers <- read.table(containers.file,
														 header = TRUE,
														 row.names = 1)
	}

	if(is.null(tag))
	{

		tag <- packageVersion("epimod")
		curr.tag <- gsub(pattern = "([[:alpha:]]+){1}(/epimod){1}(-[[:alpha:]]+:){1}",
										 replacement = "",
										 x = containers$names)
		curr.tag <- unique(curr.tag)
		containers$names <- gsub(pattern = curr.tag,
														 replacement = tag,
														 x = containers$names)
	} else {
		curr.tag <- gsub(pattern = "([[:alpha:]]+){1}(/epimod){1}(-[[:alpha:]]+:){1}",
										 replacement = "",
										 x = containers$names)
		curr.tag <- unique(curr.tag)
		containers$names <- gsub(pattern = curr.tag,
														 replacement = tag,
														 x = containers$names)
	}
	userid=system("id -u", intern = TRUE)
	username=system("id -un", intern = TRUE)
	for (i in dim(containers)[1]:1)
	{
		status <- system(paste("docker pull ",containers[i,1],
													 sep = ""))
		if (status)
		{
			containers <- containers[-i]
		}
		else
		{
			command=NULL
			if (grepl("generation",containers[i,1],fixed=TRUE)==1)
				command=c(paste("FROM", containers[i,1]),"RUN sudo groupmod -g 2005 docker &&vsudo usermod -u 2005 docker ", paste("RUN sudo /usr/sbin/adduser -u", userid, username))
			else
				command=c(paste("FROM", containers[i,1]),"RUN sudo groupmod -g 2005 docker && sudo usermod -u 2005 docker ",paste("RUN /usr/sbin/adduser -u", userid, username), "WORKDIR /home" )
			writeLines(command,"./dockerfile")
			status <- system(paste("docker build -f ./dockerfile -t ",containers[i,1], "_",username," .",
														 sep = ""))
			if (status){
				print("Error in building container", paste(containers[i,1], "_",userid,sep = ""))
			}
		}
	}
	write.table(containers,
							paste(path.package(package = "epimod"),"Containers/containersNames.txt",
										sep = "/"))
	system("rm ./dockerfile")
}
