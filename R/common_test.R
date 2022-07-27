#' @title Test correctness of the parameters before execute a function
#' @description
#'   Check if the passed parameters are well defined to execute the specified function, verifying
#'   the existence of the resource path, the length of the array, the value of solver type etc.
#'
#' @param net_fname .PNPRO file storing the Petri Net (and all its generalizations) model. In case there are multiple nets defined within the PNPRO file, the first one in the list is the will be automatically selected.
#' @param solver_fname .solver file (generated in with the function model_generation).
#' @param i_time Initial solution time.
#' @param f_time Final solution time.
#' @param s_time Time step defining the frequency at which explicit estimates for the system values are desired.
#' @param solver_type
#'  \itemize{
#'    \item Deterministic: three explicit methods which can be efficiently used  for systems without stiffness: Runge-Kutta 5th order integration, Dormand-Prince method, and Kutta-Merson method (ODE-E, ODE-RKF, ODE45). Instead for systems with stiffness we provided a Backward Differentiation Formula (LSODA);
#'    \item Stochastic: the Gillespie algorithm,which is an exact stochastic method widely used to simulate chemical systems whose behaviour can be described by the Master equations (SSA); or an approximation method of the SSA called tau-leaping method (TAUG), which provides a good compromise between the solution execution time  and its quality.
#'    \item Hybrid: Stochastic  Hybrid  Simulation, based on the co-simulation of discrete and continuous events (HLSODA).
#'  } Default is LSODA.
#' @param n_config Number of configurations to generate, to use only if some parameters are generated from a stochastic distribution, which has to be encoded in the functions defined in *functions_fname* or in *parameters_fname*.
#' @param n_run Integer for the number of stochastic simulations to run. If n_run is greater than 1 when the deterministic process is analyzed (solver_type is *Deterministic*), then n_run identical simulation are generated.
#' @param parameters_fname Textual file in which the parameters to be studied are listed associated with their range of variability. This file is defined by three mandatory columns: (1) a tag representing the parameter type: i for the complete initial marking (or condition), p for a single parameter (either a single rate or initial marking), and g for a rate associated with general transitions (Pernice et al. 2019) (the user must define a file name coherently with the one used in the general transitions file); (2) the name of the transition which is varying (this must correspond to name used in the PN draw in GreatSPN editor), if the complete initial marking is considered (i.e., with tag i) then by default the name init is used; (3) the function used for sampling the value of the variable considered, it could be either a R function or an user-defined function (in this case it has to be implemented into the R script passed through the functions_fname input parameter). Let us note that the output of this function must have size equal to the length of the varying parameter, that is 1 when tags p or g are used, and the size of the marking (number of places) when i is used. The remaining columns represent the input parameters needed by the functions defined in the third column.
#' @param functions_fname R file storing the user defined functions to generate instances of the parameters summarized in the parameters_fname file.
#' @param volume The folder to mount within the Docker image providing all the necessary files.
#' @param timeout Maximum execution time allowed to each configuration.
#' @param parallel_processors Integer for the number of available processors to use for parallelizing the simulations.
#' @param ini_v Initial values for the parameters to be optimized.
#' @param lb_v,ub_v Vectors with length equal to the number of parameters which are varying. Lower/Upper bounds for each parameter.
#' @param ini_vector_mod Logical value for ... . Default is FALSE.
#' @param threshold.stop,max.call,max.time These are GenSA arguments, which can be used to control the behavior of the algorithm. (see \code{\link{GenSA}})
#'  \itemize{
#'    \item threshold.stop (Numeric) represents the threshold for which the program will stop when the expected objective function value will reach it. Default value is NULL.
#'    \item max.call (Integer) represents the maximum number of call of the objective function. Default is 1e7.
#'    \item max.time (Numeric) is the maximum running time in seconds. Default value is NULL.
#'  } These arguments not always work, actually.
#' @param taueps The error control parameter from the tau-leaping approach.
#' @param target_value String reporting the target function, implemented in *functions_fname*, to obtain the place or a combination of places from which the PRCCs over the time have to be calculated. In details, the function takes in input a data.frame, namely output, defined by a number of columns equal to the number of places plus one corresponding to the time, and number of rows equals to number of time steps defined previously. Finally, it must return the column (or a combination of columns) corresponding to the place (or combination of places) for which the PRCCs have to be calculated for each time step.
#' @param reference_data csv file storing the data to be compared with the simulations’ result.
#' @param distance_measure String reporting the distance function, implemented in *functions_fname*, to exploit for ranking the simulations. Such function takes 2 arguments: the reference data and a list of data_frames containing simulations' output. It has to return a data.frame with the id of the simulation and its corresponding distance from the reference data.
#' @param event_times Vector representing the time points at which the simulation has to stop in order to
#' simulate a discrete event that modifies the marking of the net given a specific rule defined in *functions_fname*.
#' @param event_function String reporting the function, implemented in *functions_fname*, to exploit for modifying the total marking at a specific time point.
#' Such function takes in input: 1) a vector representing the marking of the net (called *marking*), and 2) the time point at which the simulation has stopped (called *time*).
#' In particular, *time* takes values from *event_times*.
#' @param extend If TRUE the actual configuration is extended including n_config new configurations.
#' @param seed .RData file that can be used to initialize the internal random generator.
#' @param out_fname Prefix to the output file name
#' @param user_files Vector of user files to copy inside the docker directory
#' @param caller_function a string defining which function will be executed with the specified parameters (generation, sensitivity, calibration, analysis)
#'
#' @author Paolo Castagno, Daniele Baccega, Luca Rosso

common_test <- function(net_fname, functions_fname = NULL, reference_data = NULL, target_value = NULL, ini_v, lb_v, ub_v,
                        solver_fname, i_time, f_time, s_time, parameters_fname = NULL, volume = getwd(), parallel_processors = 1,
                        solver_type = "LSODA", n_run = 1, distance_measure = NULL, n_config = 1, out_fname = NULL,
                        timeout = "1d", extend = FALSE, seed = NULL, ini_vector_mod = FALSE, threshold.stop = NULL,
                        max.call = 1e+07, max.time = NULL, taueps = 0.01, user_files = NULL, event_times = NULL, event_function = NULL,
												caller_function){

  if(!missing(functions_fname) && !is.null(functions_fname)){
    if(!file.exists(functions_fname)){
      suggested_files = list.files(path = getwd(),
                                   pattern = ifelse(caller_function == "generation", "*.cpp$", "*.R$"),
                                   recursive = TRUE)
      return(paste("File", functions_fname, "of functions_fname parameter not exists, list of",
                   ifelse(caller_function == "generation", ".cpp", ".R"), "files found:\n\t",
                   paste(unlist(suggested_files), collapse = "\n\t")))
    }
  	else{
      if(caller_function != "generation")
        source(functions_fname)
    }
  }


  if(caller_function == "generation"){
    if(missing(net_fname) || is.null(net_fname))
      return("net_fname parameter is missing! Abort")
    else{
      if(!file.exists(net_fname)){
        pnpro_files = list.files(path = getwd(), pattern = "*.PNPRO$", recursive = TRUE)
        return(paste("File", net_fname, "of net_fname parameter not exists, list of .PNPRO files found:\n\t",
                   paste(unlist(pnpro_files), collapse = "\n\t")))
      }
    }

  	if(length(Filter(function(file) any(grepl("type=\"GEN\"", readLines(file, warn = FALSE))), net_fname)) != 0 &&
  		 is.null(functions_fname)){
  		return(paste0("There is at least one generic transition in ", net_fname, ". Provide a function_fame! Abort"))
  	}
  }



	# if(caller_function == "sensitivity"){
	#   # if((missing(reference_data) || is.null(reference_data)) && (!missing(target_value) && !is.null(target_value)))
	#   #   return("target_value need the reference_data parameter!")
	# }

	# if(caller_function %in% c("sensitivity", "calibration")){
	#   if((missing(reference_data) || is.null(reference_data)) && (!missing(distance_measure) && !is.null(distance_measure)))
	#     return("distance_measure need the reference_data parameter!")
	#
	# 	# Maybe it's necessary to use a default distance_measure.
	# 	if((!missing(reference_data) && !is.null(reference_data)) && (missing(distance_measure) || is.null(distance_measure)))
	# 		return("reference_data need the distance_measure parameter!")
	# }



	if(caller_function %in% c("sensitivity", "calibration")){
		if(!missing(reference_data) && !is.null(reference_data)){
	    if(!file.exists(reference_data)){
	      R_files = list.files(path = getwd(), pattern = "*.csv$", recursive = TRUE)
	      return(paste("File",reference_data,"of reference_data parameter not exists,",
	                   "list of .csv files found:\n\t",paste(unlist(R_files),collapse = "\n\t")))
	    }
		}

    if(!missing(distance_measure) && !is.null(distance_measure)){
    	if(length(grep(distance_measure, readLines(functions_fname), value = FALSE)) == 0)
    		return(paste("File", functions_fname, "must contain a function named", distance_measure))
    }
	}

	if(caller_function == "sensitivity"){
		if(!missing(target_value) && !is.null(target_value)){
			if(length(grep(target_value, readLines(functions_fname), value = FALSE)) == 0)
				return(paste("File", functions_fname, "must contain a function named", target_value))
		}
	}



  if(caller_function %in% c("calibration", "analysis")){
      possibilities = c('ODE-E','ODE-RKF', 'ODE45', 'LSODA', 'SSA', 'TAUG', 'HLSODA', '(H)SDE', 'HODE')
      if(!solver_type %in% possibilities)
        return("Value of solver_type must be one of the following: ODE-E, ODE-RKF, ODE45,
           LSODA, SSA, TAUG, HLSODA, (H)SDE, HODE")


    if(!missing(n_run)){
      if(n_run <= 0)
        return("n_run must be greater than zero!")
      if(!is.numeric(n_run))
      	return("n_run must be a number!")
    }
  }



  if(caller_function == "calibration"){
    if(missing(ini_v) || missing(lb_v) || missing(ub_v))
      return("One or more of these parameters ini_v , lb_v or ub_v was not specified! Abort")
    else{
      if(!is.numeric(ini_v) || !is.numeric(lb_v) || !is.numeric(ub_v))
      	return("ini_v, lb_v and ub_v must be numbers")

      if(length(ini_v) != length(lb_v) || length(ini_v) != length(ub_v) || length(lb_v) != length(ub_v)){
        return("ini_v , lb_v and ub_v must have the same number of elements")
      }else{
        if(!all(ini_v >= lb_v, TRUE))
          return("Some element of ini_v is less than the corresponding element of lb_v")
        if(!all(ini_v <= ub_v, TRUE))
          return("Some element of ini_v is greather than the corresponding element of ub_v")
      }
    }
  }



  if(caller_function == "analysis"){
    if(missing(ini_v))
      return("WARNING: ini_v parameter is missing!")

  	if(!is.null(ini_v) & !is.numeric(ini_v))
  		return("ini_v must be numeric")

  	if(taueps < 0 || taueps > 1)
  		return("taueps must be in range [0, 1]! Abort")
  }



  if(caller_function %in% c("sensitivity", "calibration", "analysis")){
    if(missing(solver_fname) || is.null(solver_fname))
      return("solver_fname parameter is missing! Abort")
    else{
      if(!file.exists(solver_fname)){
        solver_files = list.files(path = getwd(), pattern = "*.solver$", recursive = TRUE)
        return(paste("File", solver_fname, "of solver_fname parameter not exists, list of .solver files found:\n\t",
                     paste(unlist(solver_files), collapse = "\n\t")))
      }
    }

    if(missing(f_time))
      return("f_time parameter is missing! Abort")
    else{
      if(f_time <= 0)
        return("f_time must be greater than zero!")
      if(!is.numeric(f_time))
      	return("f_time must be a number!")
    }

    if(missing(s_time))
      return("s_time parameter is missing! Abort")
    else{
      if(s_time <= 0)
        return("s_time must be greater than zero!")
  	  if(!is.numeric(s_time))
  			return("s_time must be a number!")
    }

  	if(missing(i_time))
  		return("i_time parameter is missing! Abort")
  	else{
  		if(i_time < 0)
  			return("i_time must be greater than or equal to zero!")
  		if(!is.numeric(i_time))
  			return("i_time must be a number!")
  	}

		if(i_time >= f_time)
			return("f_time must be greater than i_time!")

  	if(s_time >= f_time - i_time)
  		return("s_time is too large! It must be smaller than f_time - i_time!")

  	# if((f_time - i_time) %% s_time != 0)
  	# 	return("f_time - i_time must be divisible by s_time!")

		# If not specified, a runtime error is generated
	  if(!missing(parameters_fname) && !is.null(parameters_fname)){
	    if(!file.exists(parameters_fname)){
	      return(paste("File", parameters_fname, "of parameters_fname parameter does not exist!"))
	    }
	    else{
	      if(grepl("unix", .Platform$OS.type))
	        if(!grepl("ASCII text", system(paste("file", parameters_fname), intern = TRUE)))
	          return("parameters_fname must be a textual file! Abort")

	      file = file(parameters_fname, "r")
	      while(TRUE){
	        line = readLines(file, n=1)
	        if(length(line) != 0 && length(grep(pattern = "(^#){1}", x = gsub(pattern = " ", replacement = "", line))) == 0){
	          fname = unlist(strsplit(gsub(" ", "", line), ";"))[3]
	          if(!(exists(fname) || length(find(fname, numeric = TRUE)) >= 1 ||
	               !suppressWarnings(is.na(as.numeric(fname))))){
	            close(file)
	            return(paste(fname, "defined in", basename(parameters_fname), "does not exist! Abort"))
	          }
	        }
	        else
	          break
	      }
	      close(file)
	    }
	  }

		if(!missing(parallel_processors)){
	    if(parallel_processors <= 0)
	      return("parallel_processors must be greater than zero!")
		  if(!is.numeric(parallel_processors))
		  	return("parallel_processors must be a number!")
		}
  }


  if(!missing(volume))
		if(!dir.exists(volume))
	  	return(paste("The folder", volume, "of volume parameter does not exist!"))

  if(caller_function %in% c("sensitivity", "analysis")){
    #Mandatory for sensitivity analysis?
    if(!missing(n_config)){
      if(n_config <= 0)
      	return("n_config must be greater than zero!")
  	  if(!is.numeric(n_config))
  			return("n_config must be a number!")
    }
  }



  if(((missing(event_times) || is.null(event_times)) && (!missing(event_function) && !is.null(event_function))) ||
  	 ((missing(event_function) || is.null(event_function)) && (!missing(event_times) && !is.null(event_times))))
  	return("event_times and event_function must both be specified!")

	if(!missing(event_times) && !is.null(event_times)){
		if(!is.vector(event_times))
			return(paste0("The event_times argument must be a vector!"))

		if(!all(is.numeric(event_times), TRUE))
			return("The event_times argument must be a vector of numbers!")

		if(!all(event_times >= i_time, event_times <= f_time, TRUE))
			return("The event_times argument must be a vector of numbers in [i_time, f_time]!")
	}

	if(!missing(event_function) && !is.null(event_function)){
		if(length(grep(event_function, readLines(functions_fname), value = FALSE)) == 0)
			return(paste("File", functions_fname, "must contain a function named", event_function))
	}



	if(extend){
		if(caller_function %in% c("sensitivity"))
			if(!file.exists(paste0(basename(tools::file_path_sans_ext(solver_fname)), "_sensitivity/")))
				return(paste0(basename(tools::file_path_sans_ext(solver_fname)), "_sensitivity/", "directory not found!"))

		if(caller_function %in% c("analysis"))
			if(!file.exists(paste0(basename(tools::file_path_sans_ext(solver_fname)), "_analysis/")))
				return(paste0(basename(tools::file_path_sans_ext(solver_fname)), "_analysis/", "directory not found!"))
	}

	if(!is.null(seed)){
		if(!grepl("\\.RData$", seed))
			return("seed must have the .RData extension!")

		if(!file.exists(seed))
			return(paste0("The specified seed file (", seed, ") does not exist!"))

		load(seed)
		if(!exists("init_seed") || (!(caller_function %in% c("calibration")) && !exists("extend_seed")) || (!(caller_function %in% c("calibration")) && !exists("n")))
			return(paste0("The seed file (", seed, ") must contain three variables named init_seed, extend_seed and n!"))

		if(!is.numeric(init_seed) || (!(caller_function %in% c("calibration")) && !is.numeric(extend_seed)) || (!(caller_function %in% c("calibration")) && !is.numeric(n)))
			return(paste0("The three variables init_seed, extend_seed and n into the seed file (", seed, ") must be a number!"))
	}

	if(!is.null(user_files)){
		if(!is.vector(user_files))
			return(paste0("The user_files argument must be a vector of strings (file names)!"))

		if(!all(is.character(user_files), TRUE))
			return(paste0("The user_files argument must be a vector of strings (file names)!"))

		if(!all(file.exists(user_files), TRUE))
			return(paste0("There is at least one file in user_files that does not exist!"))
	}

	## Removing the functions sourced at the beginning
	if(!missing(functions_fname) && !is.null(functions_fname))
		rm(list=lsf.str(envir = .GlobalEnv), envir = .GlobalEnv)

  return(TRUE)
}
