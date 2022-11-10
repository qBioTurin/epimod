#' @title Run sensitivity analysis
#' @description The deterministic process is solved several times varying the
#' values of the unknown parameters to identify which are the sensitive ones
#' (i.e., those that have a greater effect on the model behavior), by exploiting
#' the Pearson Ranking Correlation Coefficients (PRCCs). Furthermore, a ranking
#' of simulations is returned in according to the distance of each solution with
#' respect to the reference one.
#'
#' @param folder_trace Folder in which are stored the traces file that are considered to calculate the PRCC analysis.
#' @param solver_fname .solver file (generated with the function *model_generation*).
#' @param i_time Initial solution time.
#' @param f_time Final solution time.
#' @param s_time Time step defining the frequency at which explicit estimates
#'   for the system values are desired.
#' @param atol Absolute error tolerance that determine the error control performed by the LSODA solver.
#' @param rtol Relative error tolerance that determine the error control performed by the LSODA solver.
#' @param n_config Number of configurations to generate, to use only if some
#'   parameters are generated from a stochastic distribution, which has to be
#'   encoded in the functions defined in *functions_fname* or in
#'   *parameters_fname*.
#' @param parameters_fname a textual file in which the  parameters to be studied are listed associated with their range of variability.
#' This file is defined by three mandatory columns (*which must separeted using ;*):
#' (1) a tag representing the parameter type: *i* for the complete initial marking (or condition),
#' *m* for the initial marking of a specific place, *c* for a single constant rate,
#' and *g* for a rate associated with general transitions (Pernice et al. 2019)  (the user must define a file name coherently with the one used in the  general transitions file);
#' (2) the name of the transition which is varying (this must correspond to name used in the PN draw in GreatSPN editor), if the complete initial marking is considered
#' (i.e., with tag *i*) then by default the name *init*  is used; (3) the function used for sampling the value of the variable considered,
#'  it could be either a R function or an user-defined function (in this case it has to be implemented into the R script passed through the *functions_fname* input parameter).
#'  Let us note that the output of this function must have size equal to the length of the varying parameter, that is 1 when tags *m*, *c* or *g* are used,
#'  and the size of the marking (number of places) when *i* is used. The remaining columns represent the input parameters needed by the functions defined in the third column
#' @param functions_fname an R file storing: 1) the user defined functions to generate instances of the parameters summarized in the *parameters_fname* file, and
#'  2) the functions to compute: the distance (or error) between the model output and the reference dataset itself (see *reference_data* and *distance_measure*),
#'  the discrete events which may modify the marking of the net at specific time points (see *event_function*), and
#'  the place or a combination of places from which the PRCCs over the time have to be calculated (see *target_value*).
#' @param volume The folder to mount within the Docker image providing all the
#'   necessary files.
#' @param timeout Maximum execution time allowed to each configuration.
#' @param parallel_processors Integer for the number of available processors to
#'   use.
#' @param target_value_fname String reporting the distance function, implemented
#'   in *functions_fname*, to obtain the place
#'   or a combination of places from which the PRCCs over the time have to be
#'   calculated. In details, the function takes in input a data.frame, namely
#'   output, defined by a number of columns equal to the number of places plus
#'   one corresponding to the time, and number of rows equals to number of time
#'   steps defined previously. Finally, it must return the column (or a
#'   combination of columns) corresponding to the place (or combination of
#'   places) for which the PRCCs have to be calculated for each time step.
#' @param reference_data csv file storing the data to be compared with the
#'   simulations’ result.
#' @param distance_measure String reporting the distance function, implemented in *functions_fname*,
#'  to exploit for ranking the simulations.
#'  Such function takes 2 arguments: the reference data and a list of data_frames containing simulations' output.
#'  It has to return a data.frame with the id of the simulation and its corresponding distance from the reference data.
#' @param event_times Vector representing the time points at which the simulation has to stop in order to
#' simulate a discrete event that modifies the marking of the net given a specific rule defined in *functions_fname*.
#' @param event_function String reporting the function, implemented in *functions_fname*, to exploit for modifying the total marking at a specific time point.
#' Such function takes in input: 1) a vector representing the marking of the net (called *marking*), and 2) the time point at which the simulation has stopped (called *time*).
#' In particular, *time* takes values from *event_times*.
#' @param extend If TRUE the actual configuration is extended including n_config
#'   new configurations.
#' @param seed .RData file that can be used to initialize the internal random
#'   generator.
#' @param out_fname Prefix to the output file name.
#' @param user_files Vector of user files to copy inside the docker directory
#' @param debug If TRUE enables logging activity.
#' @param fba_fname vector of .txt files encoding different flux balance analysis problems, which as to be included in the general transitions (*transitions_fname*).
#' @param FVA Flag to enable the flux variability analysis
#' @param flux_fname vector of fluxes id to compute the FVA
#' @param fva_gamma parameter, which controls whether the analysis is done w.r.t. suboptimal network states (0 $\le$ fva_gamma < 1) or to the optimal state (fva_gamma = 1)
#' It must be the same files vector passed to the function *model_generation* for generating the *solver_fname*. (default is NULL)
#'
#' @details
#' Sensitivity_analysis takes as input a solver and all the required parameters
#' to set up a dockerized running environment to perform the sensitivity
#' analysis of the model. In order to run the simulations, the user must provide
#' a reference dataset and the definition of a function to compute the distance
#' (or error) between the models' output and the reference dataset itself. The
#' function defining the distance has to be in the following form:
#'
#' FUNCTION_NAME(reference_dataset, simulation_output)
#'
#' Moreover, the function must return a column vector with one entry for each
#' evaluation point (i.e. f_time/s_time entries). In addition to that, the user
#' is asked to provide a function that, given the output of the solver, returns
#' the relevant measure (one column) used to evaluate the quality of the
#' solution.
#'
#' The sensitivity analysis will be performed through a Monte Carlo sampling
#' through user defined functions. The parameters involved in the sensitivity
#' analysis have to be listed in a cvs file using the following structure:
#'
#' OUTPUT_FILE_NAME, FUNCTION_NAME, LIST OF PARAMETERS (comma separated)
#'
#' The functions allowed to compute the parameters are either R functions or
#' user defined functions. In the latter case, all the user defined functions
#' must be provided in a single .R file (which will be passed to
#' sensitivity_analysis through the parameter parameters_fname).
#'
#' Exploiting the same mechanism, user can provide an initial marking to the
#' solver. However, if it is the case the corresponding file name in the
#' parameter list must be set to "init". Let us observe that: (i) the distance
#' and target functions must have the same name of the corresponding R file,
#' (ii) sensitivity_analysis exploits also the parallel processing capabilities,
#' and (iii) if the user is not interested on the ranking calculation then the
#' distance_measure and reference_data are not necessary and can be
#' omitted.
#'
#' @seealso model_generation
#'
#' @author Beccuti Marco, Castagno Paolo, Pernice Simone, Baccega Daniele
#' @export

model.sensitivity <- function(# folder storing the trace files
	folder_trace=NULL,
	# Parameters to control the simulation
	solver_fname=NULL,
	i_time = 0, f_time, s_time, atol = 1e-6, rtol = 1e-6,
	# User defined simulation's parameters
	n_config=1, parameters_fname = NULL, functions_fname = NULL,
	# Parameters to manage the simulations' execution
	volume = getwd(), timeout = '1d', parallel_processors = 1,
	# Parameters to control the ranking
	reference_data = NULL, distance_measure = NULL,
	# Parameters to control PRCC
	target_value = NULL,
	# List of discrete events
	event_times = NULL, event_function = NULL,
	# Mange reproducibility and extend previous experiments
	extend = FALSE, seed = NULL,
	# Directories
	out_fname = NULL,
	#Vector of user files to copy inside the docker directory
	user_files = NULL,
	#Flag to enable logging activity
	debug = FALSE,
	# FBA parameters
	fba_fname = NULL,
	# Flag to enable the flux variability analysis
	FVA  = FALSE, flux_fname = NULL, fva_gamma = .9
){

	# This function receives all the parameters that will be tested for sensitivity or model analysis functions

	if(missing(folder_trace)){
		model.analysis(n_config = n_config,
									 parameters_fname = parameters_fname,
									 functions_fname = functions_fname,
									 solver_fname = solver_fname,
									 parallel_processors = parallel_processors,
									 i_time = i_time,
									 f_time = f_time,
									 s_time = s_time,
									 volume = volume,
									 seed = seed,
									 event_times = event_times,
									 n_run = n_run,
									 atol = atol,
									 rtol = rtol,
									 solver_type = solver_type,
									 taueps = taueps,
									 ini_v = ini_v,
									 event_function = event_function,
									 user_files = user_files,
									 fba_fname = fba_fname,
									 FVA = FVA)
		folder_trace = paste0(basename(tools::file_path_sans_ext(solver_fname)), "_analysis")
	}

	ret = common_test(folder_trace,
										n_config = n_config,
										parameters_fname = parameters_fname,
										functions_fname = functions_fname,
										solver_fname = solver_fname,
										target_value = target_value,
										parallel_processors = parallel_processors,
										reference_data = reference_data,
										distance_measure = distance_measure,
										i_time = i_time,
										f_time = f_time,
										s_time = s_time,
										volume = volume,
										seed = seed,
										extend = extend,
										event_times = event_times,
										event_function = event_function,
										user_files = user_files,
										fba_fname = fba_fname,
										FVA = FVA,
										flux_fname = flux_fname,
										fva_gamma = fva_gamma,
										caller_function = "sensitivity")

	if(ret != TRUE)
		stop(paste("sensitivity_analysis_test error:", ret, sep = "\n"))

	params_RDS = list.files(path = folder_trace,
																pattern = "^params_.*\\.RDS")

	if(length(basename(tools::file_path_sans_ext(solver_fname))) == 0 ){
		results_dir_name <- "Model_sensitivity/"
		if(is.null(out_fname))
			out_fname <- "Model_sensitivity"
		}
	else
		results_dir_name <- paste0(basename(tools::file_path_sans_ext(solver_fname)), "_sensitivity/")

	chk_dir <- function(path){
		pwd <- basename(path)
		return(paste0(file.path(dirname(path), pwd, fsep = .Platform$file.sep), .Platform$file.sep))
	}
	files <- list()

	# if(!is.null(solver_fname)){
	# 	solver_fname <- tools::file_path_as_absolute(solver_fname)
	# 	files[["solver_fname"]] <- solver_fname
	# }

	# Fix input parameter out_fname
	if(is.null(out_fname))
	{
		out_fname <- paste0(basename(tools::file_path_sans_ext(solver_fname)), "-sensitivity")
	}
	# Fix input parameters path
	if (!is.null(parameters_fname))
	{
		parameters_fname <- tools::file_path_as_absolute(parameters_fname)
		files[["parameters_fname"]] <- parameters_fname
	}
	if (!is.null(functions_fname))
	{
		functions_fname <- tools::file_path_as_absolute(functions_fname)
		files[["functions_fname"]] <- functions_fname
	}
	if (!is.null(reference_data))
	{
		reference_data <- tools::file_path_as_absolute(reference_data)
		files[["reference_data"]] <- reference_data
	}
	# if(!is.null(fba_fname))
	# {
	# 	fba_fname <- tools::file_path_as_absolute(fba_fname)
	# 	files[["fba_fname"]] <- fba_fname
	# }
	if (!is.null(target_value) && target_value == "targetExtr")
	{
		stop("The target_value must be different from the string: target ")
	}
	if(!is.null(seed))
	{
		seed <- tools::file_path_as_absolute(seed)
		files[["seed"]] <- seed
	}
	if(!is.null(user_files))
	{
		for(file in user_files){
			files[[file]] <- tools::file_path_as_absolute(file)
		}
	}

	#### laod params e updating the one for the sensitivity analysis!!!!
	parms_analysis = readRDS(tools::file_path_as_absolute(paste0(folder_trace,"/",params_RDS)))
	parms_analysis[["out_fname_analysis"]] = parms_analysis$out_fname

	# Global parameters used to manage the dockerized environment
	parms_fname <- file.path(paste0("params_", out_fname), fsep = .Platform$file.sep)
	parms <- list(
								folder_trace = folder_trace,
								run_dir = chk_dir("/home/docker/scratch/"),
								out_dir = chk_dir(paste0("/home/docker/data/", results_dir_name)),
								out_fname = out_fname,
								parallel_processors = parallel_processors,
								volume = volume,
								distance_measure = distance_measure,
								target_value = target_value,
								flux_fname = flux_fname,
								fva_gamma = fva_gamma
								)

	parms_analysis_filtered = parms_analysis[! names(parms_analysis) %in% names(parms) ]
	parms <- c(parms,parms_analysis_filtered)

	volume <- tools::file_path_as_absolute(volume)
	# Create the folder to store results
	res_dir <- paste0(chk_dir(volume), results_dir_name)
	if(!extend & file.exists(res_dir)){
		unlink(res_dir, recursive = TRUE)
	}
	dir.create(res_dir, showWarnings = FALSE, recursive = TRUE)
	# Copy all the files to the directory docker will mount to the image's file system
	experiment.env_setup(files = files, dest_dir = res_dir)
	# Change path to the new files' location
	if (length(files) > 0)
	{
		parms$files <- lapply(files, function(x){
			return(paste0(parms$out_dir, basename(x)))
		})
	}

	# Manage experiments reproducibility
	if(!is.null(seed)){
		parms$seed <- paste0(parms$out_dir, "seeds-", out_fname, ".RData")
	}

	# Save all the parameters to file, in a location accessible from inside the dockerized environment
	p_fname <- paste0(res_dir, parms_fname, ".RDS")
	# Use version = 2 for compatibility issue
	saveRDS(parms, file = p_fname, version = 2)

	# Run the docker image
	containers.file = paste(path.package(package = "epimod"),
													"Containers/containersNames.txt", sep = "/")
	containers.names = read.table(containers.file, header = T, stringsAsFactors = F)

	#  it runs the PRCC or ranking
	if(!is.null(target_value) | (!is.null(reference_data)))
	{
		print("[Running] Model sensitivity")
		docker.run(params = paste0("--cidfile=dockerID ", "--volume ", volume, ":", dirname(parms$out_dir), " -d ", containers.names["sensitivity", 1], " Rscript /usr/local/lib/R/site-library/epimod/R_scripts/sensitivity.mngr.R ", p_fname), debug = debug)
	}

	# Finally it runs the FVA if it is necessary
	if(FVA)
	{
		print("[Running] Flux Variability Analysis")
		docker.run(params = paste0("--cidfile=dockerID ", "--volume ", volume, ":", dirname(parms$out_dir), " -d ", containers.names["generation", 1], " Rscript fva.mngr.R ", p_fname), debug = debug)

	}
	}
