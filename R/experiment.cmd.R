#' @title Generate the command template to configure and run a simulation
#' @description Function generating the command line used to run the solver with the appropriate configuration
#' @param solver_fname, the solver executable file
#' @param solver_type, the type of solver (LSODA, HLSODA, ..)
#' @param taueps, controls the time step for tau-leap algorithm
#' @param event_times, times at which the marking is updated through the event_function
#' @param event_function, specifies the rule to update the marking
#' @param timeout, available time to run n_run simulations (See TIMEOUT(1) to check the syntax)
#' @param out_fname, output filename prefix
#' @return a string
#' @author Paolo Castagno, Simone Pernice
#'
#' @examples
#'\dontrun{
#' experiment.cmd(id=1, solver_fname="Solver.solver", s_time=365, f_time=730, timeout="1d", out_fname="simulation")
#'
#' }

experiment.cmd <- function(solver_fname, solver_type = "LSODA", taueps = 0.01, seed,
                           timeout){
    if (solver_type == "TAUG")
    {
        solver_type <- paste(solver_type, "-taueps", taueps)
    }
    cmd <- paste0("timeout ", timeout,
                  " .", .Platform$file.sep, basename(solver_fname),
                  " <OUT_FNAME>-<ID>",
                  " -stime <S_TIME>",
                  " -itime <I_TIME>",
                  " -ftime <F_TIME>",
                  " -type ", solver_type,
                  " -seed ", "<SEED>",
                  " -runs <N_RUN>")
    if (file.exists("init"))
        cmd <- paste0(cmd, " -init <INIT>")
    if (file.exists("cmdln_mrk") | file.exists("cmdln_exp"))
        cmd <- paste0(cmd, " -parm cmdln_params")
    return(cmd)
}
