#' @title Removes unnexessary files and directories
#' @description This is an internal function removing unnecessary files (and the running directory itself) from the running environment
#' @param id, a numeric identifier used to format the output's file name
#' @param run_dir, the directory to cleanup
#' @param out_fname, output filename prefix
#' @param out_dir, output directory specified by the user
#' @author Beccuti Marco, Castagno Paolo, Pernice Simone
#'
#' @examples
#'\dontrun{
#' experiment.env_cleanup(id=1, run_dir="/run/directory", out_fname="simulation", out_dir="/out/directory",)
#' }
#' @keywords internal

experiment.env_cleanup <- function(id, run_dir,
                                   out_fname, out_dir){
    r_dir <- paste0(run_dir, id)
    file.copy(from = paste0(r_dir, .Platform$file.sep, out_fname, "-", id,".trace"), to = out_dir)
    unlink(r_dir, recursive = TRUE)
}
