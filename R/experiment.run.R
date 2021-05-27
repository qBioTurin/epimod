#' @title Run an experiment, handling the eventual discrete events
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

library(parallel)

worker <- function(worker_id,
				   cmd, n_run = 1,
				   i_time, s_time, f_time,
				   event_times = NULL, event_function = NULL,
				   out_fname)
{
	# Run's output file name
	fnm <- paste0(out_fname,"-", worker_id,".trace")

	# Number of iterations due to discrete events
	iterations <- 0
	if (!is.null(event_times) && !is.null(event_function))
	{
		iterations <- length(event_times)
	}

	# Substitue the pattern <OUT_FNAME> with the actual file name
	cmd <- gsub(x = cmd, pattern = "<OUT_FNAME>", out_fname)
	# Define the identifier for the iterations
	iter.id <- worker_id
	for (i in 1:(iterations + 1))
	{
		# Setup initial marking, initial and final time
		if ( i == 1)
		{
			init <- paste("init")
		}
		else{
			iter.id <- paste0(iter.id, "-", i)
			# Generate the init filename for the current iteration
			init <- paste0("init_iter-", iter.id)

			# Set the event's time as the new initial time
			i_time <- event_times[i - 1]

			# Read the last line of the trace file, which is the marking at the last time point
			last_m <- read.table(text = system(paste0("sed -n -e '1p;$p' ",fnm),
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
		# Set the final time to either the next event's time or to the simulation's end time
		if (i <= iterations)
			final_time <- event_times[i]
		else
			final_time <- f_time

		# Generate the command to execute the current iteration simulation's configuration
		cmd.iter <- gsub(x = cmd, pattern = "<ID>", replacement = iter.id)
		cmd.iter <- gsub(x = cmd.iter, pattern = "<S_TIME>", replacement = s_time)
		cmd.iter <- gsub(x = cmd.iter, pattern = "<I_TIME>", replacement = i_time)
		cmd.iter <- gsub(x = cmd.iter, pattern = "<F_TIME>", replacement = final_time)
		cmd.iter <- gsub(x = cmd.iter, pattern = "<N_RUN>", replacement = 1)

		if (file.exists(paste(init)))
		{
			# the initial marking
			cmd.iter <- paste0(cmd.iter, " -init ", init)
		}
		if (file.exists("cmdln_params"))
		{
			# command line parameters
			cmd.iter <- paste0(cmd.iter, " -parm ", "cmdln_params")
		}

		# Run the solver with all necessary parameters
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
		if (file.exists(paste0(out_fname,"-", worker_id,"-", i,".trace")))
		{
			file.remove(paste0(out_fname,"-", worker_id,"-", i,".trace"))
		}
	}
}

experiment.run <- function(base_id, cmd,
						   i_time, f_time, s_time,
						   n_run = 1,
						   event_times = NULL, event_function = NULL,
						   parallel_processors, out_fname)
{
	# Compute the base_id
	base_id <- 1 + (base_id - 1) * parallel_processors
	# Create a cluster
	cl <- makeCluster(parallel_processors,
					  type = "FORK")
	# number of run assigned to each thread
	jobs <- floor(n_run/parallel_processors)
	spare <- n_run - parallel_processors * jobs
	T1 <- Sys.time()
	# ret <- parLapply(cl = cl,
	# 		  X = c(1:parallel_processors),
	# 		  fun = worker,
	# 		  cmd,
	# 		  i_time = i_time,
	# 		  f_time = f_time,
	# 		  s_time = s_time,
	# 		  event_times = event_times,
	# 		  event_function = event_function,
	# 		  out_fname = out_fname)
	ret <- lapply(X = c(1:parallel_processors),
				  FUN = worker,
				  cmd = cmd,
				  i_time = i_time,
				  f_time = f_time,
				  s_time = s_time,
				  event_times = event_times,
				  event_function = event_function,
				  out_fname = out_fname)
	if(spare != 0)
	{
		parLapply(cl = cl,
				  X = c((n_run-spare):n_run),
				  fun = worker,
				  cmd = cmd,
				  i_time = i_time,
				  f_time = f_time,
				  s_time = s_time,
				  event_times = event_times,
				  event_function = event_function,
				  out_fname = out_fname)
	}
	T2 <- difftime(Sys.time(), T1, unit = "secs")
	stopCluster(cl)
	return(T2)
}
