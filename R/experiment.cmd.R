#' @title Generate the commandline to configure and run a simulation
#' @description This is an internal function generating the command line to run the solver with the appropriate configuration
#' @param id, a numeric identifier used to format the output's file name
#' @param solver_fname, the name of the solver executable file
#' @param solver_type, a string definig what solver to apply (LSODA, HLSODA, ..)
#' @param s_time, step time at which the sover is forced to output the current configuration of the model (i.e. the number of tocken in each place)
#' @param f_time, simulation's final time
#' @param n_run, when performing stochastic simulations this parameters controls the number of runs per each set of input parameters
#' @param timeout, string controlling the available time to run n_run simulations. See TIMEOUT(1) to check the syntax
#' @param out_fname, output filename prefix
#' @return a string
#' @author Paolo Castagno
#'
#' @examples
#'\dontrun{
#' experiment.cmd(id=1, solver_fname="Solver.solver", s_time=365, f_time=730, timeout="1d", out_fname="simulation")
#'
#' }
#' @export

experiment.cmd <- function(id,
                           solver_fname, solver_type = "LSODA",
                           init_fname = NULL, s_time, f_time, n_run = 1,
                           timeout, out_fname){
    if(solver_type == "TAUG")
        solver_type <- paste(solver_type, "-taueps 0.01")
    cmd <- paste0("timeout ", timeout,
                 " .", .Platform$file.sep, basename(solver_fname), " ",
                 out_fname,"-", id,
                 " -stime ", s_time,
                 " -ftime ", f_time,
                 " -type ", solver_type,
                 " -runs ", n_run)
    if(file.exists("init"))
        cmd <- paste0(cmd, " -init init")
    if(file.exists("cmdln_params"))
        cmd <- paste0(cmd, " -parm ", "cmdln_params")
    return(cmd)
}
