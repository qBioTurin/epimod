#' @title Test correctness of the parameters before execute a function
#' @description Check if the passed parameters are well defined to execute the specified function, verifying
#' the existence of the resource path, the length of the array, the value of solver type etc...
#' @param net_fname .PNPRO file storing the model as ESPN. In case there are multiple nets defined within the PNPRO file, the first one in the list is the will be automatically selected.
#' @param functions_fname  C++ file defining the functions managing the behaviour of general transitions.
#' @param reference_data Data to compare with the simulations' results
#' @param ini_v Initial values for the parameters to be optimized.
#' @param lb_v,ub_v Vectors with length equal to the number of paramenters which are varying. Lower/Upper bounds for esch paramenter.
#' @param solver_fname .solver file (generated in with the function model_generation)
#' @param f_time Final solution time.
#' @param s_time Time step at which explicit estimates for the system are desired
#' @param parameters_fname file with the definition of user defined functions
#' @param volume The folder to mount within the Docker image providing all the necessary files
#' @param parallel_processors Integer for the number of available processors to use
#' @param solver_type  \itemize{ \item Deterministic: ODE-E, ODE-RKF, ODE45, LSODA,
#'  \item Stochastic:  SSA or TAUG,
#'  \item Hybrid: HLSODA or (H)SDE or HODE
#'  } Default is LSODA.
#' @param distance_measure_fname File containing the definition of a distance measure to rank the simulations'.
#' Such function takes 2 arguments: the reference data and a list of data_frames containing simulations' output.
#' It has to return a data.frame with the id of the simulation and its corresponding distance from the reference data.
#' @param n_config, number of configuratons to generate
#' @param out_fname Prefix to the output file name
#' @param timeout Maximum execution time allowed to each configuration
#' @param extend TO BE DONE
#' @param seed Value that can be set to initialize the internal random generator.
#' @param ini_vector_mod Logical value for ... . Default is FALSE.
#' @param threshold.stop,max.call,max.time These are GenSA arguments, which can be used to control the behavior of the algorithm. (see \code{\link{GenSA}})
#' \itemize{
#' \item threshold.stop (Numeric) respresents the threshold for which the program will stop when the expected objective function value will reach it. Default value is NULL.
#' \item max.call (Integer) represents the maximum number of call of the objective function. Default is 1e7.
#' \item max.time (Numeric) is the maximum running time in seconds. Default value is NULL.}
#' @param caller_function a string defining which function will be executed with the specified parameters (generation, sensitivity, calibration, analysis)
#' @author Luca Rosso
#' @export

common_test<-function(net_fname, functions_fname = NULL, reference_data = NULL, target_value_fname = NULL, ini_v, lb_v, ub_v,
                      solver_fname, f_time, s_time, parameters_fname = NULL, volume = getwd(), parallel_processors = 1,
                      solver_type = "LSODA", n_run = 1, distance_measure_fname = NULL, n_config = 1, out_fname = NULL,
                      timeout = "1d", extend = FALSE, seed = NULL, ini_vector_mod = FALSE, threshold.stop = NULL,
                      max.call = 1e+07, max.time = NULL, taueps = 0.01, caller_function)
{

  if(!missing(functions_fname) && !is.null(functions_fname)){
    if(!file.exists(functions_fname)){
      suggested_files = list.files(path = getwd(),
                                   pattern = ifelse(caller_function == "generation", "*.cpp$", "*.R$"),
                                   recursive = TRUE)
      return(paste("File", functions_fname, "of functions_fname parameter not exists, list of",
                   ifelse(caller_function == "generation", ".cpp", ".R"), "files found:\n\t",
                   paste(unlist(suggested_files), collapse = "\n\t")))
    }else{
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
  }



  if(caller_function %in% c("sensitivity", "calibration")){
    if((missing(reference_data) || is.null(reference_data)) && (!missing(distance_measure_fname) && !is.null(distance_measure_fname)))
      return("distance_measure_fname need the reference_data parameter!")

  	#Maybe it's necessary to use a default distance_measure_fname.
  	if((!missing(reference_data) && !is.null(reference_data)) && (missing(distance_measure_fname) || is.null(distance_measure_fname)))
  		return("reference_data need the distance_measure_fname parameter!")

    if(!missing(reference_data) && !is.null(reference_data)){
      if(!file.exists(reference_data)){
        R_files = list.files(path = getwd(), pattern = "*.csv$", recursive = TRUE)
        return(paste("File",reference_data,"of reference_data parameter not exists,",
                     "list of .csv files found:\n\t",paste(unlist(R_files),collapse = "\n\t")))
      }else{
        if(!missing(distance_measure_fname) && !is.null(distance_measure_fname)){
          if(!file.exists(distance_measure_fname)){
            R_files = list.files(path = getwd(), pattern = "*.R$", recursive = TRUE)
            return(paste("File", distance_measure_fname,"of distance_measure_fname parameter not exists,",
                         "list of .R files found:\n\t", paste(unlist(R_files), collapse = "\n\t")))
          }
          else{
            fname_without_ext = unlist(strsplit(basename(distance_measure_fname), "\\."))[1]
            source(distance_measure_fname)
            if(!exists(fname_without_ext))
              return(paste("The name of the function in distance_measure_fname is not the same as the file name",
                           basename(distance_measure_fname), "!"))
          }
        }
      }
    }
  }



  if(caller_function == "sensitivity"){
    if((missing(reference_data) || is.null(reference_data)) && (!missing(target_value_fname) && !is.null(target_value_fname)))
      return("target_value_fname need the reference_data parameter!")


    if(!missing(target_value_fname) && !is.null(target_value_fname)){
      if(!file.exists(target_value_fname)){
        R_files = list.files(path = getwd(), pattern = "*.R$", recursive = TRUE)
        return(paste("File", target_value_fname, "of target_value_fname parameter not exists,",
                   "list of .R files found:\n\t", paste(unlist(R_files), collapse = "\n\t")))
      }
      else{
        fname_without_ext = unlist(strsplit(basename(target_value_fname), "\\."))[1]
        source(target_value_fname)
        if(!exists(fname_without_ext))
          return(paste("The name of the function in target_value_fname is not the same as the file name",
                     basename(target_value_fname), "!"))
      }
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
      	return("ini_v , lb_v and ub_v must be numbers")

      if(length(ini_v) != length(lb_v) || length(ini_v) != length(ub_v) || length(lb_v) != length(ub_v)){
        return("ini_v , lb_v and ub_v must have the same number of elements")
      }else{
        if(!all(ini_v > lb_v, TRUE))
          return("Some element of ini_v is less than or equal to the corresponding element of lb_v")
        if(!all(ini_v < ub_v, TRUE))
          return("Some element of ini_v is greather than or equal to the corresponding element of ub_v")
      }
    }
  }



  if(caller_function == "analysis"){
    if(missing(ini_v))
      return("WARNING: ini_v parameter is missing!")
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

	#if not specified, a runtime error is generated
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
        if(length(line) != 0){
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
    #mandatory for sensitivity analysis ?
    if(!missing(n_config)){
      if(n_config <= 0)
      	return("n_config must be greater than zero!")
  	  if(!is.numeric(n_config))
  			return("n_config must be a number!")
    }
  }



	path_to_seed <- paste0("results_", caller_function, "_analysis")
	if(extend){
		if(caller_function %in% c("sensitivity"))
			if(!file.exists(paste0("results_", caller_function, "_analysis/")))
				return(paste0("results_", caller_function, "_analysis directory not found!"))

		if(caller_function %in% c("calibration", "analysis")){
			path_to_seed <- paste0("results_model_", caller_function)
			if(!file.exists(paste0("results_model_", caller_function, "/")))
				return(paste0("results_model_", caller_function, " directory not found!"))
		}
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

  return("ok")
}
