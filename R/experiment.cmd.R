#' @title Generate the commandline to configure and run a simulation
#' @description This is an internal function generating the command line to run the solver with the appropriate configuration
#' @param id, a numeric identifier used to format the output's file name
#' @param solver_fname, the name of the solver executable file
#' @param solver_type, a string definig what solver to apply (LSODA, HLSODA, ..)
#' @param s_time, step time at which the sover is forced to output the current configuration of the model (i.e. the number of tocken in each place)
#' @param f_time, simulation's final time
#' @param n_run, when performing stochastic simulations this parameters controls the number of runs per each set of input parameters
#' @param taueps, controls the step of the approximation introduced by the tau-leap algorithm
#' @param time_events, controls the time at which the simulation is stopped to update the marking
#' @param function_events, specifies the rule to update the marking
#' @param timeout, string controlling the available time to run n_run simulations. See TIMEOUT(1) to check the syntax
#' @param out_fname, output filename prefix
#' @return a string
#' @author Paolo Castagno, Simone Pernice
#'
#' @examples
#'\dontrun{
#' experiment.cmd(id=1, solver_fname="Solver.solver", s_time=365, f_time=730, timeout="1d", out_fname="simulation")
#'
#' }
#' @export

worker <- function(id,
                   solver_fname, solver_type,
                   s_time, f_time, n_run = 1, taueps,
<<<<<<< HEAD
                   time_events = NULL, function_events = NULL,
                   timeout, out_fname)
=======
                   timeout, out_fname,
                   time_events = NULL, function_events = NULL)
>>>>>>> cbcb36dd9e32aba83b07be6d13c06fd6ff07dd7b
{
    # stop and start the simulation changing the marking:
    fnm <- paste0(out_fname,"-", id,".trace")
    iterations <- 1
    if (!is.null(time_events))
    {
        iterations <- length(time_events)
    }
    for (i in 1:iterations)
    {
        cmd = ""
        if ( i == 1)
        {
            i_time <- 0
            init <- paste("init")
        }
        else{
            init <- paste0("initNew-", id,"-",i - 1)
            # set the event's time as the new initial time
            i_time <- time_events[i - 1]
            # read the trace file of the previous iteration
            trace <- read.csv( paste0(out_fname,"-", id,"-",i - 1,".trace"), sep = "")
            # The last line of the trace file is the marking at the final time of the previous step
            # The first column of the file is the time and we remove it
            last_m <- trace[length(trace[,1]),-1]
            # Generate the new marking by invoking the provided function
            new_m <- do.call(function_events, list(marking = last_m))
            ############ writing the .trace with all the simulating windows
            if (!file.exists(fnm))
            {
                write.table(trace[-length(trace[,1]),],
                            file = fnm,
                            sep = " ",
                            col.names = TRUE,
                            row.names = FALSE)
            }
            else{
                write.table(trace[-length(trace[,1]),],
                            file = fnm, append = TRUE,
                            sep = " ",
                            col.names = FALSE,
                            row.names = FALSE)
            }
            file.remove(paste0(out_fname,"-", id,"-",i - 1,".trace"))
            #################
            new_m[new_m < 0] <- 0
            write.table(x = as.matrix(new_m,nrow = 1),
                        file = init ,
                        col.names = FALSE,
                        row.names = FALSE,
                        sep = " ")
        }
        f_time <- time_events[i]
        cmd <- paste0(cmd,
                      "timeout ", timeout,
                      " .", .Platform$file.sep, basename(solver_fname), " ",
                      out_fname,"-", id,"-",i,
                      " -stime ", s_time,
                      " -itime ", i_time,
                      " -ftime ", f_time,
                      " -type ", solver_type,
                      " -runs ", n_run)
        if (file.exists(paste(init)))
        {
            # the initial marking
            cmd <- paste0(cmd, " -init ", init)
        }
        if (file.exists("cmdln_params"))
        {
            # command line parameters
            cmd <- paste0(cmd, " -parm ", "cmdln_params")
        }
        # run the solver with all necessary parameters
        system(cmd, wait = TRUE)
        if (init != "init")
        {
            file.remove(init)
        }
    }
    ############ writing the .trace with the last simulating windows
    trace = read.csv( paste0(out_fname,"-", id,"-",length(time.events),".trace"), sep = "")
    if (!file.exists(fnm))
    {
        write.table(trace, file = fnm, sep = " ", col.names = TRUE, row.names = FALSE)
    }
    else{
        write.table(trace, file = fnm, append = TRUE, sep = " ", col.names = FALSE, row.names = FALSE)
    }
    file.remove(paste0(out_fname,"-", id,"-",length(time.events),".trace"))
    #################
}

# experiment.cmd <- function(id,
#                            solver_fname, solver_type = "LSODA",
#                            s_time, f_time, n_run = 1, taueps = 0.01,
#                            timeout, out_fname){
#     if(solver_type == "TAUG")
#     {
#         solver_type <- paste(solver_type, "-taueps", taueps)
#     }
#     cmd <- paste0("timeout ", timeout,
#                  " .", .Platform$file.sep, basename(solver_fname), " ",
#                  out_fname,"-", id,
#                  " -stime ", s_time,
#                  " -ftime ", f_time,
#                  " -type ", solver_type,
#                  " -runs ", n_run)
#     if(file.exists("init"))
#         cmd <- paste0(cmd, " -init init")
#     if(file.exists("cmdln_params"))
#         cmd <- paste0(cmd, " -parm ", "cmdln_params")
#     return(cmd)
# }

experiment.event.cmd <- function(id,
                                 solver_fname, solver_type = "LSODA",
                                 s_time, f_time, n_run = 1, taueps = 0.01,
                                 time_events = NULL, function_events = NULL ,
                                 timeout, out_fname){
    if (solver_type == "TAUG")
    {
        solver_type <- paste(solver_type, "-taueps", taueps)
    }
    worker(id = id,
           solver_fname = solver_fname,
           solver_type = solver_type,
           taueps = taueps,
           s_time = s_time,
           f_time = f_time,
           timeout = timeout,
           out_fname = out_fname,
           time_events = time_events,
           function_events = function_events,
           n_run = 1)
}