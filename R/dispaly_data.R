#' @title Run display data
#' @description
#'
#' @param volume The folder to mount within the Doker image providing all the necessary files
#' @param port The port shyiny app will listen for requests
#'
#'
#' @author Beccuti Marco, Castagno Paolo, Pernice Simone

#'
#' @examples
#'\dontrun{
#' display_data(volume = "/some/path/to/the/local/output/directory",
#'               port = getOption("shiny.port"))
#' }
#' @export
sensitivity_analysis <-function(
	volume = getwd(),
	port = getOption("shiny.port"))
{
	volume <- tools::file_path_as_absolute(volume)
	parmas <- list(port = port,
				   dir = "/home/docker/data/")
	# Save all the parameters to file, in a location accessible from inside the dockerized environment
	p_fname <- paste0(res_dir, parms_fname,".RDS")
	# Use version = 2 for compatibility issue
	saveRDS(parms,  file = p_fname, version = 2)
	p_fname <- paste0( parms$out_dir, parms_fname,".RDS") # location on the docker image file system
	# Run the docker image
	containers.file=paste(path.package(package="epimod"),"Containers/containersNames.txt",sep="/")
	containers.names=read.table(containers.file,header=T,stringsAsFactors = F)
	docker.run(params = paste0("--cidfile=dockerID ","--volume ", volume,":", dirname(parms$dir), " -d ", containers.names["display",1]," Rscript /usr/local/lib/R/site-library/epimod/R_scripts/display.mngr.R ", p_fname))
}
