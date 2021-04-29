source("file_compare.R")

det_results_check<-function(furl_st=NULL, fname_st=NULL,fname_nd=NULL){
  print("STARTING RESULTS CHECK FOR DETERMINISTIC MODEL...")
  compare_file(furl_st,fname_st,fname_nd);
}
sto_results_check<-function(furl_st=NULL, fname_st=NULL,fname_nd=NULL){
  print("STARTING RESULTS CHECK FOR STOCHASTIC MODEL...")
  if(is.null(furl_st) && is.null(fname_st))
    stop("Missing path of first file to compare! Abort")
  
  if(is.null(fname_nd))
  {
    warning("WARNING: missing path of second file to compare,
            using results_reference/stochastic_model/model_analysis-1.trace as default")
    path = "results_reference/stochastic_model/model_analysis-1.trace"
    fname_nd = paste0(getwd(),.Platform$file.sep,path)
  }
  
  if(!is.null(furl_st))
  {
    fst_ext = unlist(strsplit(basename(furl_st),"\\."))[2]
    dest_st = paste0(getwd(),.Platform$file.sep,"file1.",fst_ext)
    download.file(furl_st,dest_st)
  }else
  {
    if(!file.exists(fname_st))
      stop(paste(fname_st,"file not exists! Abort"))
  }
  
  if(!file.exists(fname_nd)){
    if(!is.null(furl_st))
      unlink(dest_st)
    stop(paste(fname_nd,"file not exists! Abort"))
  }
  
  #TODO creare data.frame con medie file riferimento, data.frame con intervalli di confidenza, fare confronto e stampare
  
  unlink(dest_st)
}
det_results_check(fname_st = "results_reference/deterministic_model/model_analysis-1 (modified).trace")