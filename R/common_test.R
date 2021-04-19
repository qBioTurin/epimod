common_test<-function(net_fname,functions_fname = NULL,reference_data = NULL,target_value_fname = NULL,ini_v, lb_v, ub_v,
                      solver_fname,f_time,s_time,parameters_fname = NULL, volume = getwd(), parallel_processors = 1,
                      solver_type = "LSODA",  n_run = 1, distance_measure_fname = NULL, n_config = 1,out_fname = NULL,
                      timeout = "1d", extend = NULL, seed = NULL, ini_vector_mod = FALSE, threshold.stop = NULL,
                      max.call = 1e+07, max.time = NULL, taueps = 0.01,caller_function)
{


  if(!missing(functions_fname)){
    if(!is.null(functions_fname) & !file.exists(functions_fname)){
      suggested_files = list.files(path = getwd(),
                                   pattern = ifelse(caller_function=="generation","*.cpp$","*.R$"),
                                   recursive = TRUE)
      return(paste("File",functions_fname,"of functions_fname parameter not exists, list of",
                   ifelse(caller_function=="generation",".cpp",".R"),"files found:\n\t",
                   paste(unlist(suggested_files),collapse = "\n\t")))
    }else{
      if(caller_function!="generation")
        source(functions_fname)
    }
  }


  if(caller_function == "generation"){
    if(missing(net_fname))
      return("net_fname parameter is missing! Abort")
    else{
      if(!is.null(net_fname) & !file.exists(net_fname)){
        pnpro_files = list.files(path = getwd(), pattern = "*.PNPRO$",recursive = TRUE)
        return(paste("File",net_fname,"of net_fname parameter not exists, list of .PNPRO files found:\n\t",
                   paste(unlist(pnpro_files),collapse = "\n\t")))
      }
    }
  }



  if(caller_function %in% c("sensitivity","calibration")){
    if(missing(reference_data) & caller_function=="calibration")
      return("reference_data parameter is missing! Abort")

    if(missing(distance_measure_fname) & caller_function=="calibration")
      return("distance_measure_fname parameter is missing! Abort")

    if(missing(reference_data) & !missing(distance_measure_fname) & caller_function=="sensitivity")
      return("distance_measure_fname need the reference_data parameter!")


    if(!missing(reference_data)){
      if(!is.null(reference_data) & !file.exists(reference_data)){
        R_files = list.files(path = getwd(), pattern = "*.csv$",recursive = TRUE)
        return(paste("File",reference_data,"of reference_data parameter not exists,",
                     "list of .csv files found:\n\t",paste(unlist(R_files),collapse = "\n\t")))
      }else{
        if(!missing(distance_measure_fname)){
          if(!is.null(distance_measure_fname) & !file.exists(distance_measure_fname)){
            R_files = list.files(path = getwd(), pattern = "*.R$",recursive = TRUE)
            return(paste("File",distance_measure_fname,"of distance_measure_fname parameter not exists,",
                         "list of .R files found:\n\t",paste(unlist(R_files),collapse = "\n\t")))
          }
          else{
            fname_without_ext = unlist(strsplit(basename(distance_measure_fname),"\\."))[1]
            source(distance_measure_fname)
            if(!exists(fname_without_ext))
              return(paste("The name of the function in distance_measure_fname is not the same as the file name",
                           basename(distance_measure_fname),"!"))
          }
        }
      }
    }

  }



  if(caller_function == "sensitivity"){
    if(missing(reference_data) && !missing(target_value_fname))
      return("target_value_fname need the reference_data parameter!")


    if(!missing(target_value_fname)){
      if(!is.null(target_value_fname) & !file.exists(target_value_fname)){
        R_files = list.files(path = getwd(), pattern = "*.R$",recursive = TRUE)
        return(paste("File",target_value_fname,"of target_value_fname parameter not exists,",
                   "list of .R files found:\n\t",paste(unlist(R_files),collapse = "\n\t")))
      }
      else{
        fname_without_ext = unlist(strsplit(basename(target_value_fname),"\\."))[1]
        source(target_value_fname)
        if(!exists(fname_without_ext))
          return(paste("The name of the function in target_value_fname is not the same as the file name",
                     basename(target_value_fname),"!"))
      }
    }

  }



  if(caller_function %in% c("calibration","analysis")){
    # not mandatory in README examples ?
    if(missing(solver_type))
      return("solver_type parameter is missing! Abort")
    else{
      possibilities = c('ODE-E','ODE-RKF', 'ODE45', 'LSODA', 'SSA', 'TAUG', 'HLSODA', '(H)SDE', 'HODE')
      if(!solver_type %in% possibilities)
        return("Value of solver_type must be one of the following: ODE-E, ODE-RKF, ODE45,
           LSODA, SSA, TAUG, HLSODA, (H)SDE, HODE")
    }


    if(!missing(n_run))
      if(n_run<=0)
        return("n_run must be greater than zero!")
  }



  if(caller_function == "calibration"){
    if(missing(ini_v) | missing(lb_v) | missing(ub_v))
      return("One or more of these parameters ini_v , lb_v or ub_v was not specified! Abort")
    else
      if(length(ini_v) != length(lb_v) | length(ini_v) != length(ub_v)){
        return("ini_v , lb_v and ub_v must have the same number of elements")
      }else{
        if(!all(ini_v>lb_v,TRUE))
          return("Some element of ini_v is less than or equal to the corresponding element of lb_v")
        if(!all(ini_v<ub_v,TRUE))
          return("Some element of ini_v is greather than or equal to the corresponding element of ub_v")
      }
  }



  if(caller_function == "analysis"){
    if(missing(ini_v))
      return("WARNING: ini_v parameter is missing!")
  }



  if(caller_function %in% c("sensitivity","calibration","analysis")){
    if(missing(solver_fname))
      return("solver_fname parameter is missing! Abort")
    else{
      if(!is.null(solver_fname) & !file.exists(solver_fname)){
        solver_files = list.files(path = getwd(), pattern = "*.solver$",recursive = TRUE)
        return(paste("File",solver_fname,"of solver_fname parameter not exists, list of .solver files found:\n\t",
                     paste(unlist(solver_files),collapse = "\n\t")))
      }
    }

    if(missing(f_time))
      return("f_time parameter is missing! Abort")
    else
      if(f_time<=0)
        return("f_time must be greater than zero!")


    if(missing(s_time))
      return("s_time parameter is missing! Abort")
    else
      if(s_time<=0)
        return("s_time must be greater than zero!")

    #if not specified, a runtime error is generated
    if(!missing(parameters_fname)){
      if(!is.null(parameters_fname) & !file.exists(parameters_fname)){
        return(paste("File", parameters_fname, "of parameters_fname parameter does not exist!"))
      }
      else{
        if(grepl("unix",.Platform$OS.type))
          if(!grepl("ASCII text",system(paste("file",parameters_fname),intern=TRUE)))
            return("parameters_fname must be a textual file! Abort")

        file = file(parameters_fname,"r")
        while(TRUE){
          line = readLines(file,n=1)
          if(length(line)!=0){
            fname = unlist(strsplit(gsub(" ","",line),";"))[3]
            if(!(exists(fname) | length(find(fname,numeric=TRUE))>=1  |
                 !suppressWarnings(is.na(as.numeric(fname))))){
              close(file)
              return(paste(fname,"defined in",basename(parameters_fname),"does not exist! Abort"))
            }
          }
          else
            break
        }
        close(file)
      }
    }


    if(!missing(volume))
      if(!dir.exists(volume))
        return(paste("The folder",volume,"of volume parameter does not exist!"))

    if(!missing(parallel_processors))
      if(parallel_processors<=0)
        return("parallel_processors must be greater than zero!")
  }



  if(caller_function %in% c("sensitivity","analysis")){
    #mandatory for sensitivity analysis ?
    if(!missing(n_config))
      if(n_config<=0)
        return("n_config must be greater than zero!")
  }

  return("ok")

}
