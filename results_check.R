source("file_compare.R")

det_results_check<-function(furl_st=NULL, fname_st=NULL,fname_nd=NULL){
  print("STARTING RESULTS CHECK FOR DETERMINISTIC MODEL...")
  compare_file(furl_st,fname_st,fname_nd);
}
det_results_check(fname_st = "results_reference/deterministic_model/model_analysis-1 (modified).trace")