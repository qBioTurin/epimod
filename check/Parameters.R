library(devtools)
library(epimod)

model_generation_test <- function(out_fname = NULL, net_fname, functions_fname = NULL, 
                             volume = getwd()) {
  
  # b. net_fname (mandatory): Name of the input file with the model representation
  # ■ Check if the file exists
  if(missing(net_fname))
    stop("net_fname parameter is missing! Abort")
  else{
    if(!file.exists(net_fname))
      stop(paste("File ", net_fname, " does not exist!"))
  }
  
  # c. functions_fname (optional): C++ file with general transition’s definition
  # ■ Check if the file exists
  if(!missing(functions_fname)){
    if(!file.exists(functions_fname)){
      cpp_files = list.files(path = getwd(), pattern = "*.cpp",recursive = TRUE) 
      stop("File ", functions_fname, " not exists, list of cpp files found: ", 
                                    paste(unlist(cpp_files),collapse = "\n"))
    }
  }
}

sensitivity_analysis_test <- function (solver_fname, f_time, s_time, n_config, parameters_fname = NULL, 
          functions_fname = NULL, volume = getwd(), timeout = "1d", 
          parallel_processors = 1, reference_data = NULL, distance_measure_fname = NULL, 
          target_value_fname = NULL, extend = NULL, seed = NULL, out_fname = NULL) 
{
  #a. solver_fname (mandatory): Name of the solver executable file
  #■ Check if the file exists
  if(missing(solver_fname))
    stop("solver_fname parameter is missing! Abort")
  else{
    if(!file.exists(solver_fname))
      stop(paste("File ", solver_fname, " does not exist!"))
  }
  
  #b. f_time (mandatory): simulation’s end time
  #■ Check if it is greater than zero
  if(missing(f_time))
    stop("f_time parameter is missing! Abort")
  else
    if(f_time<=0)
      stop("f_time must be greater than zero!")
  
  
  #c. s_time (mandatory): simulation’s time step
  #■ Check if it is greater than zero
  if(missing(s_time))
    stop("s_time parameter is missing! Abort")
  else
    if(s_time<=0)
      stop("s_time must be greater than zero!")
  
  #d. n_config (optional): number of simulation’s configurations to generate   
  #■ Check if it is greater than zero       ????? (per sensitivity_analysis è obbligatorio)
  if(!missing(n_config))
    if(n_config<=0)
      stop("n_config must be greater than zero!")
  
  #e. parameters_fname (optional): file listing how to generate parameters     
  #■ Check if the file exists               ???? (bug del # se non specificato?)
  if(!missing(parameters_fname))
    if(!file.exists(parameters_fname))
      stop(paste("File ", parameters_fname, " does not exist!"))
  
  #f. functions_fname (optional): R file with the implementation of the functions
  #required to generate parameters provided in parameters_fname
  #■ Check if the file exists     ???? (controllare che ci siano tutte le funzioni definite in parameters_fname?)
  if(!missing(functions_fname))
    if(!file.exists(functions_fname))
      stop(paste("File ", functions_fname, " does not exist!"))
  
  
  #g. volume (optional): folder to be mounted as Docker volume
  #■ Check if the folder exists
  if(!missing(volume))
    if(!dir.exists(volume))
      stop("The specified folder does not exist!")
  
  
  #i. parallel_processors (optional): number of available processors
  #■ Check if it is greater than zero
  if(!missing(parallel_processors))
    if(parallel_processors<=0)
      stop("parallel_processors must be greater than zero!")
  
  
  #j. reference_data (optional): reference data series
  #■ Check if the file exists
  #k. distance_measure_fname (optional): distance measure used to compare the
  #reference data series with the output of the model (used to rank the outputs of
  #                                                    the model)
  #■ Check if the file exists
  #■ Check if reference_data parameter is present
  #■ Check if the name of the function is the same as the file name (without
  #extension)
  #l. target_value_fname (optional): R function to extract the values to compare
  #with the reference data series (used to compute the Partial Rank Correlation
  #                                Coefficients)
  #■ Check if the file exists
  #■ Check if reference_data parameter is present
  #■ Check if the name of the function is the same as the file name (without
  #extension)
  if(!missing(reference_data)){
    if(!file.exists(reference_data))
      stop(paste("File ", reference_data, " does not exist!"))
    else{
      if(!missing(distance_measure_fname)){
        if(!file.exists(distance_measure_fname))
          stop(paste("File ", distance_measure_fname, " does not exist!"))
        else{
          fname_without_ext = unlist(strsplit(basename(distance_measure_fname),"\\."))[1]
          function_signature = paste(fname_without_ext,"<-function\\(([ a-zA-Z]*,)*[ a-zA-Z]*\\)[ ]*(\\n)*\\{",sep="")
          if(!any(grepl(function_signature,paste(readLines(distance_measure_fname),collapse = " "))))
            stop("The name of the function is not the same as the file name or you could have miss a '{' 
            after function definition!")
        }
      }
      if(!missing(target_value_fname)){
        if(!file.exists(target_value_fname))
          stop(paste("File ", target_value_fname, " does not exist!"))
        else{
          fname_without_ext = unlist(strsplit(basename(target_value_fname),"\\."))[1]
          function_signature = paste(fname_without_ext,"<-function\\(([ a-zA-Z]*,)*[ a-zA-Z]*\\)[ ]*(\\n)*\\{",sep="")
          if(!any(grepl(function_signature,paste(readLines(target_value_fname),collapse = " "))))
            stop("The name of the function is not the same as the file name or you could have miss a '{' 
            after function definition!")
        }
      }
    }
  }
  else{
    if(!missing(distance_measure_fname))
      stop("distance_measure_fname need the reference_data attribute!")
    if(!missing(target_value_fname))
      stop("target_value_fname need the reference_data attribute!")
  }
}