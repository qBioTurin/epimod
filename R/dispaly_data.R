#' @title Run display data
#' @description Launches the EpiMod Plot Viewer Shiny app in a Docker container.
#' The app supports two modes: "Local" (mount a results folder from the host)
#' and "Cloud" (upload a ZIP archive directly in the browser).
#' If a display container is already running it is automatically stopped before
#' starting the new one.
#'
#' @param volume The host folder to mount as the data directory inside the container.
#'   Accessible via the "Local" tab in the app. If NULL, no volume is mounted and
#'   only the "Cloud (ZIP)" upload mode will be available.
#' @param port The host port the Shiny app will listen on. Defaults to 3838.
#'
#' @author Beccuti Marco, Castagno Paolo, Pernice Simone
#'
#' @examples
#'\dontrun{
#' # With a local results folder
#' display_data(volume = "/some/path/to/the/local/output/directory", port = 3838)
#'
#' # ZIP-upload only (no local folder needed)
#' display_data(port = 3838)
#' }
#'
#' @export

display_data <- function(
	volume = NULL,
	port = 3838)
{
	chk_dir <- function(path){
		pwd <- basename(path)
		return(paste0(file.path(dirname(path), pwd, fsep = .Platform$file.sep), .Platform$file.sep))
	}

	# display image is amd64-only (rocker/shiny has no arm64 manifest)
	# always specify the platform so Docker does not try to match the host arch
	platform_flag <- "--platform linux/amd64 "

	# Stop any previously running display container before starting a new one
	stop_display(silent = TRUE)

	containers.file <- paste(path.package(package = "epimod"), "Containers/containersNames.txt", sep = "/")
	containers.names <- read.table(containers.file, header = TRUE, stringsAsFactors = FALSE)

	username <- Sys.info()["user"]
	id_container <- paste(containers.names["display", 1], username, sep = "_")

	volume_params <- ""
	if (!is.null(volume)) {
		volume <- tools::file_path_as_absolute(volume)
		log_dir <- paste0(chk_dir(volume), "displaydata_log")
		if (!dir.exists(log_dir)) dir.create(log_dir, recursive = TRUE)
		volume_params <- paste0(
			"--volume ", volume, ":/srv/shiny-server/display/data ",
			"--volume ", log_dir, ":/var/log/shiny-server/ "
		)
		# Write a marker file so the shiny app reliably detects the mounted volume
		writeLines(as.character(Sys.time()), file.path(volume, ".epimod_mounted"))
	}

	system(paste0("docker pull ", platform_flag, containers.names["display", 1]))

	system(paste0(
		"docker run -d ",
		platform_flag,
		"--name epimod-display ",
		volume_params,
		"-p ", port, ":3838 ",
		id_container
	))

	url <- paste0("http://localhost:", port, "/display")

	cat(paste0("\nEpiMod Plot Viewer is running at: ", url, "\n"))
	cat("Call stop_display() to stop the container.\n\n")

	# Wait briefly for shiny-server to start, then open the browser
	Sys.sleep(3)
	utils::browseURL(url)
}

#' @title Stop the display container
#' @description Stops and removes the running EpiMod Plot Viewer Docker container.
#'
#' @param silent If TRUE suppresses messages when no container is running. Defaults to FALSE.
#'
#' @author Beccuti Marco, Castagno Paolo, Pernice Simone
#'
#' @examples
#'\dontrun{
#' stop_display()
#' }
#' @export

stop_display <- function(silent = FALSE)
{
	# Use docker inspect via JSON output — avoids shell quoting differences across OS
	running <- tryCatch({
		system2("docker", c("inspect", "--format", "{{.State.Running}}", "epimod-display"),
				stdout = TRUE, stderr = FALSE)
	}, error = function(e) character(0))

	if (length(running) == 0 || running != "true") {
		if (!silent)
			cat("No running epimod-display container found.\n")
		# Clean up stopped container if it exists
		system2("docker", c("rm", "-f", "epimod-display"), stdout = FALSE, stderr = FALSE)
		return(invisible(NULL))
	}

	ret <- system2("docker", c("rm", "-f", "epimod-display"), stdout = FALSE, stderr = FALSE)
	if (ret == 0) {
		if (!silent) cat("EpiMod display container stopped.\n")
	} else {
		cat("Failed to stop the epimod-display container.\n")
	}
	invisible(ret)
}
