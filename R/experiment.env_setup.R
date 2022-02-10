#' @title Sets up the environment (directory and files) required to run a simulartion
#' @description This is an internal function creating the required structure of files and directiry to run a simulation.
#' @param id, a numeric identifier used to format the output's file name (optional, if not provided copy files in dest_dir. Otherwise, create a sub-directory id)
#' @param confg, configuration provided by the function experiment.configurations
#' @author Beccuti Marco, Castagno Paolo, Pernice Simone

#'
#' @examples
#'\dontrun{
#' experiment.env_cleanup(id=1, run_dir="/run/directory", out_fname="simulation", out_dir="/out/directory",)
#' }

experiment.env_setup <- function(id = NULL,
                                 files,
                                 dest_dir,
                                 config = NULL)
{
		print("[experiment.env_setup] Setting up environment")
    # Set the directory
    if(!is.null(id))
        dest_dir <- paste0(dest_dir, id)
    # Create the directory
    #if(file.exists(dest_dir))
    #{
    #    unlink(dest_dir, recursive = TRUE)
    #}
    dir.create(dest_dir, recursive = TRUE, showWarnings = FALSE)
    # Copy files in the new directory
    lapply(files,function(x){
        file.copy(from = x, to = dest_dir)
    })
    w_dir <- getwd()
    setwd(dest_dir)
    if(!is.null(id) && !is.null(config))
    # Write configurations files to the run_directory
    lapply(c(1:length(config)),function(x){
        if(length(config[[x]]) > 1)
            idx <- id
        else
            idx <- 1
        # Check how to handle the parameter
        # if(config[[x]][[idx]][[2]] > 0)
        if(config[[x]][[idx]][[2]] %in% c("i", "g"))
        {
        		print(paste0("[experiment.env_setup] Creating file for parameter ",config[[x]][[idx]][[1]], "(", config[[x]][[idx]][[1]],")"))
            # Write the (set of) parameter(s) to file
            write.table(x = config[[x]][[idx]][[3]],
            			file = config[[x]][[idx]][[1]],
            			col.names = FALSE,
            			row.names = FALSE,
            			sep = ",")
        }
        else
        {
            if(config[[x]][[idx]][[2]] == "c")
            {
            	print(paste0("[experiment.env_setup] Adding parameter to transitions' file ",config[[x]][[idx]][[1]], "(", config[[x]][[idx]][[1]],")"))
            	# Write single parameter to file (cmdln_params) using the format
            	# <parameter name> <parameter value>
            	write.table(x = paste(config[[x]][[idx]][[1]],
            						  config[[x]][[idx]][[3]]),
            				file="cmdln_exp",
            				append = TRUE,
            				quote = FALSE,
            				row.names = FALSE,
            				col.names = FALSE)
            } else {
            	# Write single parameter to file (cmdln_params) using the format
            	# <parameter name> <parameter value>
            	print(paste0("[experiment.env_setup] Adding parameter to places' file ",config[[x]][[idx]][[1]], "(", config[[x]][[idx]][[1]],")"))
            	write.table(x = paste(config[[x]][[idx]][[1]],
            						  config[[x]][[idx]][[3]]),
            				file="cmdln_mrk",
            				append = TRUE,
            				quote = FALSE,
            				row.names = FALSE,
            				col.names = FALSE)
            }
        }
    })
    setwd(w_dir)
    print("[experiment.env_setup] Done setting up environment")
}
