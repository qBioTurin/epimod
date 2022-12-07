#' @title Run an experiment, handling the eventual discrete events
#' @description This is an internal function generating the command line to run the solver with the appropriate configuration
#' @param id, a numeric identifier used to format the output's file name
#' @param solver_fname, the name of the solver executable file
#' @param solver_type, a string definig what solver to apply (LSODA, HLSODA, ..)
#' @param s_time, step time at which the sover is forced to output the current configuration of the model (i.e. the number of tocken in each place)
#' @param f_time, simulation's final time
#' @param atol Absolute error tolerance that determine the error control performed by the LSODA solver.
#' @param rtol Relative error tolerance that determine the error control performed by the LSODA solver.
#' @param n_run, when performing stochastic simulations this parameters controls the number of runs per each set of input parameters
#' @param taueps, controls the step of the approximation introduced by the tau-leap algorithm
#' @param event_times, controls the time at which the simulation is stopped to update the marking
#' @param event_function, specifies the rule to update the marking
#' @param timeout, string controlling the available time to run n_run simulations. See TIMEOUT(1) to check the syntax
#' @param out_fname, output filename prefix
#' @param FVA Flag to enable the flux variability analysis
#' @return the name of the trace file
#' @author Paolo Castagno, Simone Pernice
#'
#' @export
#'
#' @examples
#'\dontrun{
#' experiment.cmd(id=1, solver_fname="Solver.solver", s_time=365, f_time=730, timeout="1d", out_fname="simulation")
#'
#' }

experiment.run <- function(id, cmd,
													 i_time, f_time, s_time,
													 atol,rtol,
													 n_run = 1, seed,
													 event_times = NULL, event_function = NULL,
													 out_fname,
													 FVA = F)
{
	# Run's output file name
	fnm <- paste0(out_fname, "-", id, ".trace")

	# Number of iterations due to discrete events
	iterations <- 0
	if (!is.null(event_times) && !is.null(event_function))
	{
		iterations <- length(event_times)

	}
	print(paste0("[experiment.run] Setting up command line ... ", cmd))
	# Substitute the pattern <OUT_FNAME> with the actual file name
	cmd <- gsub(x = cmd, pattern = "<OUT_FNAME>", out_fname)
	for (i in 1:(iterations + 1))
	{
		# Setup initial marking, initial and final time
		if (i == 1)
		{
			init <- paste("init")
			if (file.exists("cmdln_mrk") | file.exists("cmdln_exp"))
			{
				system("touch cmdln_params")
				if (file.exists("cmdln_mrk")){
					print(system("echo '[experiment.run] cmdln_mrk'; cat cmdln_mrk"))
					system("cat cmdln_mrk >> cmdln_params")
				}
				if ( file.exists("cmdln_exp")){
					print(system("echo '[experiment.run] cmdln_exp'; cat cmdln_exp"));
					system("cat cmdln_exp >> cmdln_params")
				}
				print(system("echo '[experiment.run] cmdln_params'; cat cmdln_params"));
			}
		}
		else{
			# Fix command template:
			# 1) Add init file, if not present
			if(length(grep(x = cmd,
										 pattern = "<INIT>")) != 1)
			{
				cmd = paste0(cmd, " -init <INIT>")
			}
			# Disable commandline parameters
			print(system("echo [experiment.run] files in $PWD; ls"));
			if(length(grep(x = cmd,
										 pattern = "cmdln_params")) == 1 && file.exists("cmdln_exp"))
			{
				cmd <- gsub(x = cmd,
										pattern = "cmdln_params",
										replacement = "cmdln_exp")
			} else {
				cmd <- gsub(x = cmd,
										pattern = "-parm cmdln_params",
										replacement = "")
			}
			# Generate the init filename for the current iteration
			init <- paste0("init_iter-", i)

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

			write.table(x = format(new_m,digits = 16,scientific = F),
									file = "init" ,
									col.names = FALSE,
									row.names = FALSE,
									sep = " ",
									quote = F)

		}
		# Set the final time to either the next event's time or to the simulation's end time
		if (i <= iterations)
			final_time <- event_times[i]
		else
			final_time <- f_time

		# Generate the command to execute the current iteration simulation's configuration
		print(paste0("[experiment.run] replacement <ID> ", paste0(id, "-", i)))
		cmd.iter <- gsub(x = cmd, pattern = "<ID>", replacement = paste0(id, "-", i))
		print(paste0("[experiment.run] replacement <S_TIME> ", s_time))
		cmd.iter <- gsub(x = cmd.iter, pattern = "<S_TIME>", replacement = s_time)
		print(paste0("[experiment.run] replacement <I_TIME> ", i_time))
		cmd.iter <- gsub(x = cmd.iter, pattern = "<I_TIME>", replacement = i_time)
		print(paste0("[experiment.run] replacement <F_TIME> ", final_time))
		cmd.iter <- gsub(x = cmd.iter, pattern = "<F_TIME>", replacement = final_time)
		print(paste0("[experiment.run] replacement <N_RUN> ", n_run))
		cmd.iter <- gsub(x = cmd.iter, pattern = "<N_RUN>", replacement = n_run)
		print(paste0("[experiment.run] replacement <SEED> ", n_run))
		cmd.iter <- gsub(x = cmd.iter, pattern = "<SEED>", replacement = seed+i)

		print(paste0("[experiment.run] replacement <ATOL> ", atol))
		cmd.iter <- gsub(x = cmd.iter, pattern = "<ATOL>", replacement = atol)
		print(paste0("[experiment.run] replacement <RTOL> ", rtol))
		cmd.iter <- gsub(x = cmd.iter, pattern = "<RTOL>", replacement = rtol)

		if (file.exists(init))
		{
			print(paste0("[experiment.run] replacement <INIT> ", init))
			cmd.iter <- gsub(x = cmd.iter, pattern = "<INIT>", replacement = init)
			### DEBUG ###
			#print(paste0("[experiment.run] cat ", init, "..."))
			#system(paste("cat", init))
			### DEBUG ###
		}
		# Enabled the FVA
		if(FVA) cmd.iter = paste0(cmd.iter, " -var")
		#
		### DEBUG ###
		print(paste0("[experiment.run] launching\n\t", cmd.iter))
		### DEBUG ###
		# Run the solver with all necessary parameters
		system(cmd.iter, wait = TRUE)
		#############################
		curr_fnm <- paste0(out_fname, "-", id, "-", i, ".trace")
		# DEBUG
		# write(x = paste(cmd.iter,curr_fnm), file = "~/data/commands.txt", append = TRUE)
		####### PATCH ########
		system(paste0("sed -i 's/  / /g' ", curr_fnm))
		system(paste0("sed -i 's/ $//g' ", curr_fnm))
		##### END PATCH ######
		# DEBUG
		# write(x = system(paste0("head -n 2 ", curr_fnm, " | tail -n 1"), intern = TRUE), file = "~/data/commands.txt", append = TRUE)
		## Append the current .trace file to the simulation's one
		if (!file.exists(fnm))
		{
			file.rename(from = curr_fnm, to = fnm)
			### DEBUG ###
			# system(paste0("cp ", fnm, " ~/data/", fnm))
			### DEBUG ###
		}
		else{
			### DEBUG ###
			# system(paste0("cp ", curr_fnm, " ~/data/", curr_fnm))
			### DEBUG ###
			# Remove last line from the output file
			### DEBUG ###
			#print(paste0("head -n-1 ", fnm))
			#system(paste0("head -n-1 ", fnm))
			### DEBUG ###
			system(paste0("head -n-1 ", fnm, " > ", paste0(fnm,"_tmp"),"; mv ", paste0(fnm,"_tmp")," ", fnm))

			# Remove first line from the current output file and append to the output file
			### DEBUG ###
			#print(paste0("tail -n-$(($(wc -l ", curr_fnm, " | cut -f1 -d' ') - 1)) ", curr_fnm))
			#system(paste0("tail -n-$(($(wc -l ", curr_fnm, " | cut -f1 -d' ') - 1)) ", curr_fnm))
			### DEBUG ###
			#system(paste0("tail -n-$(($(wc -l ", curr_fnm, " | cut -f1 -d' ') - 1)) ", curr_fnm, " >> ", fnm))
			#print(paste0("tail -n-$(($(wc -l ", curr_fnm, " | cut -f1 -d' ') )) ", curr_fnm))
			#system(paste0("tail -n-$(($(wc -l ", curr_fnm, " | cut -f1 -d' ') )) ", curr_fnm))
			### DEBUG ###
			system(paste0("tail -n-$(($(wc -l ", curr_fnm, " | cut -f1 -d' ') )) ", curr_fnm, " >> ", fnm))
			file.remove(curr_fnm)
		}

		if (init != "init")
		{
			file.remove(init)
		}

		##  MERGING FBA FILES
		fbafiles = list.files(
			pattern = paste0(out_fname, "-", id, "-", i, "(-[0-9]+)+(.flux){1}")
		)
		if(length(fbafiles)>0){
			fbafiles = unique(gsub(fbafiles,
														 pattern = paste0("(",out_fname, "-", id, "-", i,"-)|(.flux)"),
														 replacement = ""))
			for(f in fbafiles){
				fbanm <- paste0(out_fname, "-", id,"-", f, ".flux")
				curr_fbanm <- paste0(out_fname, "-", id, "-", i, "-", f, ".flux")
				####### PATCH ########
				system(paste0("sed -i 's/  / /g' ", curr_fbanm))
				system(paste0("sed -i 's/ $//g' ", curr_fbanm))
				##### END PATCH ######
				## Append the current .flux file to the simulation's one
				if (!file.exists(fbanm))
				{
					file.rename(from = curr_fbanm, to = fbanm)
				}
				else{
					# Remove last line from the previous and already merged output file
					### DEBUG ###
					#print(paste0("head -n-1 ", fbanm))
					#system(paste0("head -n-1 ", fbanm))
					### DEBUG ###
					# system(paste0("head -n-1 ", fbanm, " > ", paste0(fbanm,"_tmp"),"; mv ", paste0(fbanm,"_tmp")," ", fbanm))

					# Remove first line from the current output file and append to the output file
					### DEBUG ###
					# print(paste0("tail -n-$(($(wc -l ", curr_fbanm, " | cut -f1 -d' ') - 1)) ", curr_fbanm))
					# system(paste0("tail -n-$(($(wc -l ", curr_fbanm, " | cut -f1 -d' ') - 1)) ", curr_fbanm))
					# ### DEBUG ###
					# system(paste0("tail -n-$(($(wc -l ", curr_fbanm, " | cut -f1 -d' ') - 1)) ", curr_fbanm, " >> ", fbanm))
					#print(paste0("tail -n-$(($(wc -l ", curr_fbanm, " | cut -f1 -d' ') )) ", curr_fbanm))
					#system(paste0("tail -n-$(($(wc -l ", curr_fbanm, " | cut -f1 -d' ') )) ", curr_fbanm))
					### DEBUG ###
					system(paste0("tail -n-$(($(wc -l ", curr_fbanm, " | cut -f1 -d' ') )) ", curr_fbanm, " >> ", fbanm))
					file.remove(curr_fbanm)
				}
			}
		}
	}
	return(fnm)
}
