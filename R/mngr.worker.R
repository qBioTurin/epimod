mngr.worker <- function(id,
												solver_fname, cmd,
												i_time, f_time, s_time, n_run,
												timeout, run_dir, out_fname, out_dir, seed,
												event_times, event_function,
												files, config = NULL,
												parallel_processors)
{
	print("[mngr.worker] Starts with parameters:")
	print(paste0("[mngr.worker] - id ", id))
	print(paste0("[mngr.worker] - solver_fname ", solver_fname))
	print(paste0("[mngr.worker] - cmd ", cmd))
	print(paste0("[mngr.worker] - i_time ", i_time))
	print(paste0("[mngr.worker] - f_time ", f_time))
	print(paste0("[mngr.worker] - s_time ", s_time))
	print(paste0("[mngr.worker] - parallel_processors ", parallel_processors))
	if (!is.null(config))
	{
		print(paste0("[mngr.worker] - config ", config))
		# Setup the environment
		experiment.env_setup(id = id, files = files, config = config, dest_dir = run_dir)
	}
	else
	{
		# Handle simulations without parameters
		dir.create(paste0(run_dir, id), recursive = TRUE, showWarnings = FALSE)
		file.copy(from = solver_fname, to = paste0(run_dir, id))
	}
	print(paste0("[mngr.worker] - seed ", seed))

	# Change working directory to the one corresponding at the current id
	pwd <- getwd()
	setwd(paste0(run_dir,id))

	print("[mngr.worker] Starting simulations..")
	if(n_run != 1)
	{
		print("[mngr.worker] Creating subdirectories...")
		# setup the environment for each run
		fns <- list.files(recursive = FALSE)
		print(paste0("[mngr.worker] ", fns))
		lapply(X = c(1:n_run),
					 FUN = function(X, fns){
					 	dir.create(paste0(X))
					 	file.copy(from = fns,
					 						to = paste0(X, .Platform$file.sep, fns))
					 },
					 fns = fns)
		print("[mngr.worker] Done creating subdirectories")
		# Create a cluster
		library(parallel)
		cs <- makeCluster(parallel_processors,
											type = "FORK",
											outfile = paste0(out_fname,".worker.log"))
		# Launch simulations
		res <- parLapply(cl = cs,
							fun = function(X, cmd, i_time, f_time, s_time, event_times, event_function, out_fname, id){
								pwd <- getwd()
								setwd(paste0(X))
								print(paste0("[mngr.worker] Running simulation ", id, "-", X, "..."))
								fn <- experiment.run(id = X,
																		 cmd = cmd,
																		 i_time = i_time,
																		 f_time = f_time,
																		 s_time = s_time,
																		 n_run = 1,
																		 seed = seed + (id-1)*n_run+X,
																		 event_times = event_times,
																		 event_function = event_function,
																		 out_fname = paste0(out_fname,"-", id))
								print(paste0("[mngr.worker] Simulation ", id, "-", X, " done!"))
								setwd(pwd)
								return(file.path(X,fn))
							},
							X = c(1:n_run),
							id = id,
							cmd = cmd,
							i_time = i_time,
							f_time = f_time,
							s_time = s_time,
							event_times = event_times,
							event_function = event_function,
							out_fname = out_fname)
		# Print all the output to the stdout
		system(paste0("cat ", out_fname,".worker.log >&2"))
		unlink(x = paste0(out_fname,".worker.log"), force = TRUE)
		stopCluster(cs)
		res <- unlist(res)
		print("[mngr.worker] Merging files..")
		# Merge all trace files in one
		fnm <- paste0(out_dir, out_fname,"-", id, ".trace")
		lapply(X = res, function(X, outname)
		{
			# tr <- read.csv(paste0(run_dir, id, .Platform$file.sep, out_fname, "-", basename(X), ".trace"), sep = "")
			tr <- read.csv(X,
										 sep = "")
			if (!file.exists(outname)) {
				write.table(tr, file = outname, sep = " ", col.names = TRUE, row.names = FALSE)
			} else {
				write.table(tr, file = outname, append = TRUE, sep = " ", col.names = FALSE, row.names = FALSE)
			}
			unlink(x = basename(dirname(X)),
						 recursive = TRUE,
						 force = TRUE)
		},
		outname = fnm)
		print("[mngr.worker] Done merging files")
	} else {
		print(paste0("[mngr.worker] Running simulation ", id, "..."))
		fnm <- experiment.run(id = id,
															cmd = cmd,
															i_time = i_time,
															f_time = f_time,
															s_time = s_time,
															n_run = n_run,
															seed = seed + id,
															event_times = event_times,
															event_function = event_function,
															out_fname = out_fname)
		print(paste0("[mngr.worker] Simulation ", id, " done!"))
	}
	# cat("\n\n",id,": Execution time ODEs:",elapsed, "sec.\n")
	# Change the working directory back to the original one
	setwd(pwd)
	# Move relevant files to their final location and remove all the temporary files
	experiment.env_cleanup(id = id, run_dir = run_dir, out_fname = out_fname, out_dir = out_dir)
	return(basename(fnm))
}
