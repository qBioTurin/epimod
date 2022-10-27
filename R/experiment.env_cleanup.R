#' @title Removes unnexessary files and directories
#' @description This is an internal function removing unnecessary files (and the running directory itself) from the running environment
#' @param id, a numeric identifier used to format the output's file name
#' @param run_dir, the directory to cleanup
#' @param out_fname, output filename prefix
#' @param out_dir, output directory specified by the user
#' @author Beccuti Marco, Castagno Paolo, Pernice Simone
#'
#' @export
#' @examples
#'\dontrun{
#' experiment.env_cleanup(id=1, run_dir="/run/directory", out_fname="simulation", out_dir="/out/directory",)
#' }

experiment.env_cleanup <- function(id, run_dir,
                                   out_fname, out_dir){
		print("[experiment.env_clenup] Start removing unneeded files")
    r_dir <- paste0(run_dir, id)
    ## file.copy(from = paste0(r_dir, .Platform$file.sep, out_fname, "-", id,".trace"), to = out_dir)
    print(paste0("[experimen.env_cleanup] Saving file ",
    						 list.files(path = r_dir,
    						 					 pattern = paste0(out_fname, "(-[0-9]+)+(.trace){1}"))))
    file.copy(from = paste0(r_dir,
    						.Platform$file.sep,
    						list.files(path = r_dir,
    								   pattern = paste0(out_fname,
    								   				 "(-[0-9]+)+(.trace){1}")
    								   )
    						),
    		  to = out_dir)
    # If FBA was used
    print(paste0("[experimen.env_cleanup] Saving flux file ",
    						 list.files(path = r_dir,
    						 					 pattern = paste0(out_fname, "(-[0-9]+)+(.flux){1}"))))
    file.copy(from = paste0(r_dir,
    												.Platform$file.sep,
    												list.files(path = r_dir,
    																	 pattern = paste0(out_fname,
    																	 								 "(-[0-9]+)+(.flux){1}")
    												)
    ),
    to = out_dir)
    ##
    print(paste0("[experimen.env_cleanup] Removing directory ", r_dir))
    unlink(r_dir,
           recursive = TRUE,
           force = TRUE)
    print("[experimen.env_cleanup] Done removing unneeded files")
}
