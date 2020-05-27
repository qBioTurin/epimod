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
#' Example of events list:
#' event.list<-list(e1=list(time = 4 , update = c(+1,0,0,-1)),
#'                  e2=list(time = 8 , update = c(+2,0,0,-1)))
#'
#' @export

event.worker <-function(id,
                        solver_fname, solver_type,
                        s_time, f_time, n_run = 1, taueps,
                        timeout, out_fname,
                        times.events,marking.delta)
{
  # stop and start the simulation changing the marking:
	fnm<-paste0(out_fname,"-", id,".trace")
  for( i in 1:length(times.events) )
  {

  	cmd = ""

    if ( i == 1)
    {
      i_time = 0
    }else{
      i_time = times.events[i-1]
      trace = read.csv( paste0(out_fname,"-", id,"-",i-1,".trace"), sep = "")
      last_m = trace[length(trace[,1]),-1] # the first col is the time so I have to remove it
      new_m = last_m + marking.delta[i-1,]

      ############ writing the .trace with all the simulating windows
      if(!file.exists(fnm)){
      	write.table(trace[-length(trace[,1]),], file = fnm, sep = " ", col.names = TRUE, row.names = FALSE)
      }
      else{
      	write.table(trace[-length(trace[,1]),], file = fnm, append = TRUE, sep = " ", col.names = FALSE, row.names = FALSE)
      }

      file.remove(paste0(out_fname,"-", id,"-",i-1,".trace"))
      #################
      new_m[new_m < 0] = 0

      write.table(x = as.matrix(new_m,nrow=1), file = "init", col.names = FALSE, row.names = FALSE, sep = " ")
    }

    f_time = times.events[i]

    cmd <- paste0(cmd,
    			  "timeout ", timeout,
                  " .", .Platform$file.sep, basename(solver_fname), " ",
                  out_fname,"-", id,"-",i,
                  " -stime ", s_time,
                  " -itime ", i_time,
                  " -ftime ", f_time,
                  " -type ", solver_type,
                  " -runs ", n_run)

    if(file.exists("init")) # the initial marking
    	cmd <- paste0(cmd, " -init init")
    if(file.exists("cmdln_params"))
      cmd <- paste0(cmd, " -parm ", "cmdln_params")

    system(cmd, wait = TRUE)

  }

  ############ writing the .trace with the last simulating windows
  trace = read.csv( paste0(out_fname,"-", id,"-",length(times.events),".trace"), sep = "")
  if(!file.exists(fnm)){
  	write.table(trace, file = fnm, sep = " ", col.names = TRUE, row.names = FALSE)
  }
  else{
  	write.table(trace, file = fnm, append = TRUE, sep = " ", col.names = FALSE, row.names = FALSE)
  }

  file.remove(paste0(out_fname,"-", id,"-",length(times.events),".trace"))
  #################

}


experiment.event.cmd <- function(id,
                           solver_fname, solver_type = "LSODA",
                           s_time, f_time, n_run = 1, taueps = 0.01,
                           timeout, out_fname,
                           event.list){
    if(solver_type == "TAUG")
    {
        solver_type <- paste(solver_type, "-taueps", taueps)
    }

  times.events = c( sapply(event.list, `[[`, 1), f_time)
  marking.delta = t( sapply(event.list, `[[`, 2) ) # rows = times, col = places update

  event.worker(id=id,
  			 	solver_fname=solver_fname,
                solver_type=solver_type,
                taueps=taueps,
                s_time=s_time,
                f_time=f_time,
                timeout=timeout,
                out_fname=out_fname,
                times.events=times.events,
                marking.delta=marking.delta,
                n_run=1)


}
