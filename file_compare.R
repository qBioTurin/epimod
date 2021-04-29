library(epimod)
library(devtools)
 
#model_generation(net_fname = "Net/SIR.PNPRO", functions_fname = "Cpp/transitions.cpp")

 # model_analysis(out_fname = "model_analysis",
 #                solver_fname = "Net/SIR.solver",
 #               parameters_fname = "Input/Functions_list_ModelAnalysis.csv",
 #                f_time = 7*20, # weeks
 #                solver_type = "SSA",
 #                s_time = 1)

compare_file<-function(furl_st, fname_st,fname_nd){
  if(is.null(furl_st) && is.null(fname_st))
    stop("Missing path of first file to compare! Abort")
  
  if(is.null(fname_nd)){
    warning("WARNING: missing path of second file to compare, 
            using results_reference/deterministic_model/model_analysis-1.trace as default")
    path = "results_reference/deterministic_model/model_analysis-1.trace"
    fname_nd = paste0(getwd(),.Platform$file.sep,path)
  }
  
  
  if(!is.null(furl_st)){
    fst_ext = unlist(strsplit(basename(furl_st),"\\."))[2]
    dest_st = paste0(getwd(),.Platform$file.sep,"file1.",fst_ext)
    download.file(furl_st,dest_st)
  }else{
    if(!file.exists(fname_st))
      stop(paste(fname_st,"file not exists! Abort"))
    
    fst_ext = unlist(strsplit(basename(fname_st),"\\."))[2]
    dest_st = paste0(getwd(),.Platform$file.sep,"file1.",fst_ext)
    file.copy(from = fname_st, to = dest_st)
  }
  
  if(!file.exists(fname_nd)){
    unlink(dest_st)
    stop(paste(fname_nd,"file not exists! Abort"))
  }
  
  fnd_ext = unlist(strsplit(basename(fname_nd),"\\."))[2]
  dest_nd = paste0(getwd(),.Platform$file.sep,"file2.",fnd_ext)
  file.copy(from = fname_nd, to = dest_nd)
  
  if(system(paste("diff",basename(dest_st),basename(dest_nd)),ignore.stdout = FALSE)==1)
    print("The two files are not equals")
  else
    print("The two files are equals")
  
  unlink(dest_st)
  unlink(dest_nd)
}
# Example of running: 
# compare_file(fname_st = "Results/results_model_analysis/SIR.solver", fname_nd = "Results/results_model_analysis/SIR.solver")
# compare_file(fname_st = "bmc.cls", fname_nd = "file_compare.R")
# compare_file(furl_st = "https://raw.githubusercontent.com/qBioTurin/SIR/master/Results/results_sensitivity_analysis/SIR.solver"
#              , fname_nd = "Results/results_model_analysis/SIR.solver")
