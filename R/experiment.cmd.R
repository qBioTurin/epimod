#' @title Generate the commandline to configure and run a simulation
#' @description This is an internal function generating the command line to run the solver with the appropriate configuration
#' @param id, a numeric identifier used to format the output's file name
#' @param solver_fname, the name of the solver executable file
#' @param solver_type, a string definig what solver to apply (LSODA, HLSODA, ..)
#' @param s_time, step time at which the sover is forced to output the current configuration of the model (i.e. the number of tocken in each place)
#' @param f_time, simulation's final time
#' @param n_run, when performing stochastic simulations this parameters controls the number of runs per each set of input parameters
#' @param taueps, controls the step of the approximation introduced by the tau-leap algorithm
#' @param event_times, controls the time at which the simulation is stopped to update the marking
#' @param event_function, specifies the rule to update the marking
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
                   event_times = NULL, event_function = NULL,
                   timeout, out_fname)
{
    # stop and start the simulation changing the marking:
    fnm <- paste0(out_fname,"-", id,".trace")
    iterations <- 1
    if (!is.null(event_times))
    {
        iterations <- length(event_times)
    }
    for (i in 1:(iterations + 1))
    {
        cmd = ""
        # Setup initial marking, initial and final time
        if ( i == 1)
        {
            i_time <- 0
            init <- paste("init")
        }
        else{
            init <- paste0("init_iter-", id,"-",i - 1)
            # set the event's time as the new initial time
            i_time <- event_times[i - 1]
            # Read the last line of the trace file, which is the marking at the last time point
            last_m <- read.table(text = system(paste("sed -n -e '1p;$p'", 'WNV4-analysys-1-1.trace-1.trace'),
                                               intern = TRUE),
                                 header = TRUE)
            # The first column of the file is the time and we remove it
            last_m <- last_m[,-1]
            # Generate the new marking by invoking the provided function
            new_m <- do.call(event_function,
                             list(marking = last_m,
                                  time = i_time))
            #################
            new_m[new_m < 0] <- 0
            write.table(x = as.matrix(new_m,nrow = 1),
                        file = init ,
                        col.names = FALSE,
                        row.names = FALSE,
                        sep = " ")
        }
        if(i <= iterations)
            final_time <- event_times[i]
        else
            final_time <- f_time
        cmd <- paste0(cmd,
                      "timeout ", timeout,
                      " .", .Platform$file.sep, basename(solver_fname), " ",
                      fnm,"-",i,
                      " -stime ", s_time,
                      " -itime ", i_time,
                      " -ftime ", final_time,
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
        #############################
        ## Append the current .trace file to the simulation's one
        if (!file.exists(fnm))
        {
            write.table(trace,
                        file = fnm,
                        sep = " ",
                        col.names = TRUE,
                        row.names = FALSE)
        }
        else{
            write.table(trace[-1,],
                        file = fnm,
                        append = TRUE,
                        sep = " ",
                        col.names = FALSE,
                        row.names = FALSE)

        }
        if (init != "init")
        {
            file.remove(init)
        }
        # file.remove(paste0(out_fname,"-", id,"-",i - 1,".trace"))
    }
}

experiment.cmd <- function(id,
                           solver_fname, solver_type = "LSODA",
                           s_time, f_time, n_run = 1, taueps = 0.01,
                           event_times = NULL, event_function = NULL ,
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
           event_times = event_times,
           event_function = event_function,
           n_run = 1)
}
