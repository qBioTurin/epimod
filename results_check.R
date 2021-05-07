source("file_compare.R")
#install.packages("fdatest",dependencies = TRUE)

det_results_check<-function(furl_st=NULL, fname_st=NULL,fname_nd=NULL){
  cat("STARTING RESULTS CHECK FOR DETERMINISTIC MODEL...\n")
  compare_file(furl_st,fname_st,fname_nd);
  cat("\nEND RESULTS CHECK FOR DETERMINISTIC MODEL...")
}
#on the first file are calculated the means, on the second the confidence intervals, then
#it's check if the mean respect the calculated intervals
sto_results_check<-function(furl_st=NULL, fname_st=NULL,fname_nd=NULL,sep=" "){

  cat("STARTING RESULTS CHECK FOR STOCHASTIC MODEL...\n")
  if(is.null(furl_st) && is.null(fname_st))
    stop("Missing path of first file to compare! Abort")

  if(is.null(fname_nd))
  {
    warning("WARNING: missing path of second file to compare,
            using results_reference/stochastic_model/model_analysis-1 (copy).trace as default")
    path = "results_reference/stochastic_model/model_analysis-1 (copy).trace"
    fname_nd = file.path(getwd(),path,fsep= .Platform$file.sep)
  }

  if(!is.null(furl_st))
  {
    fst_ext = unlist(strsplit(basename(furl_st),"\\."))[2]
    dest_st = file.path(getwd(),paste0("file1.",fst_ext),fsep = .Platform$file.sep)
    #dest_st = paste0(getwd(),.Platform$file.sep,"file1.",fst_ext)
    download.file(furl_st,dest_st)
    trace1= read.csv(file = dest_st,header = TRUE,sep = sep,quote="\"", dec=".")
  }else
  {
    if(!file.exists(fname_st))
      stop(paste(fname_st,"file not exists! Abort"))
  	else
  		trace1 = read.csv(file= fname_st,header = TRUE,sep = sep,quote="\"", dec=".")
  }

  if(!file.exists(fname_nd)){
    if(!is.null(furl_st))
      unlink(dest_st)
    stop(paste(fname_nd,"file not exists! Abort"))
  }else
  {
  	trace2 = read.csv(fname_nd,header = TRUE,sep = sep,quote="\"", dec=".")
  }

	if(nrow(trace1)!=nrow(trace2))
		stop("The two files to compare must have the same number of elements!")

	alpha <- 0.01
	n_ex <- length(trace1$Time)/(max(trace1$Time)-min(trace1$Time)+1)

	#create frame1 with the mean of all variables in the referred file
	trace1.nms <- names(trace1)
	trace1.ci <- data.frame()
	#For all unique values of Time column  create an entry with intervals
	for(j in unique(trace1$Time))
	{
		iteration1.ci <- data.frame()
		# Get only the rows relative to the current Time
		trace1.iter <- trace1[trace1$Time == j,]
		#For all columns of observation's j-time construct its interval
		for(n in trace1.nms)
		{
			if(n != "Time")
			{
				#All values of interested column
				values <- trace1.iter[[n]]
				#Correspond to one row
				var1.ci <- data.frame(mean = mean(values))
				#The columns' names of the row just calculated take the values of cname_mean,cname_lower and cname_uppper
				names(var1.ci) <- paste0(n, "_", names(var1.ci))
				#If the "building row" doesn't still have the time column, it's added
				if(ncol(iteration1.ci) != 0)
				{
					iteration1.ci <- cbind(iteration1.ci, var1.ci)
				}
				else
				{
					iteration1.ci <- data.frame(Time = j)
					iteration1.ci <- cbind(iteration1.ci, var1.ci)
				}
			}
		}
		#entry related to a specific time (for example all experiments with Time=0) with all the variables and intervals
		trace1.ci <- rbind(trace1.ci, iteration1.ci)
	}


	#create frame2 with the confidence interval of all variables in the referred file
	trace2.nms <- names(trace2)
	trace2.ci <- data.frame()
	#For all unique values of Time column create an entry with intervals
	for(j in unique(trace2$Time))
	{
		iteration2.ci <- data.frame()
		# Get only the rows relative to the current Time
		trace2.iter <- trace2[trace2$Time == j,]
		#For all columns of observation's j-time construct its interval
		for(n in trace2.nms)
		{
			if(n != "Time")
			{
				#All values of interested column
				values <- trace2.iter[[n]]
				#Correspond to one row
				var2.ci <- data.frame(lower =  mean(values) - qt(1 - alpha/2, n_ex - 1)*sd(values)/sqrt(n_ex),
									  upper =  mean(values) + qt(1 - alpha/2, n_ex - 1)*sd(values)/sqrt(n_ex))
				#The columns' names of the row just calculated take the values of cname_mean,cname_lower and cname_uppper
				names(var2.ci) <- paste0(n, "_", names(var2.ci))
				#If the "building row" doesn't still have the time column, it's added
				if(ncol(iteration2.ci) != 0)
				{
					iteration2.ci <- cbind(iteration2.ci, var2.ci)
				}
				else
				{
					iteration2.ci <- data.frame(Time = j)
					iteration2.ci <- cbind(iteration2.ci, var2.ci)
				}
			}
		}
		#entry related to a specific time (for example all experiments with Time=0) with all the variables and intervals
		trace2.ci <- rbind(trace2.ci, iteration2.ci)
	}

	#View(trace1.ci)
	#View(trace2.ci)

	printed_error = FALSE
	#control if all means calculated in the first dataframe respect their confidence interval
	for(row in c(1:nrow(trace1.ci)))
	{
		referred_row = trace1.ci[trace1.ci$Time == row-1,]
		#index of columns in the second frame
		lb_index = 2
		ub_index = 3
		#for all variables' mean
		for(column in c(2:ncol(trace1.ci)))
		{
			sing_val = referred_row[column]
			lb_value = trace2.ci[trace2.ci$Time==referred_row[[1]],lb_index]
			ub_value = trace2.ci[trace2.ci$Time==referred_row[[1]],ub_index]
			#the mean must be in the interval calculated
			if(!(lb_value<=sing_val & sing_val<=ub_value)){
				print(paste0("Time:",referred_row[[1]],"  ",names(trace1)[column],":",
							 sing_val," not in interval [",lb_value,",",ub_value,"]"));
				printed_error = TRUE
			}

			lb_index = lb_index + 2
			ub_index = ub_index + 2
		}
	}

	if(!is.null(furl_st))
		unlink(dest_st)

	if(!printed_error)
		print("The calculated means respect the confidence intervals!")

	cat("\nEND RESULTS CHECK FOR STOCHASTIC MODEL...")
}
fda_check<-function(furl_st=NULL, fname_st=NULL,fname_nd=NULL,sep=" "){
	cat("STARTING FUNCTION DATA ANALYSIS...\n")
	if(is.null(furl_st) && is.null(fname_st))
		stop("Missing path of first file to compare! Abort")

	if(is.null(fname_nd))
	{
		warning("WARNING: missing path of second file to compare,
            using results_reference/stochastic_model/model_analysis-1 (copy).trace as default")
		path = "results_reference/stochastic_model/model_analysis-1 (copy).trace"
		fname_nd = file.path(getwd(),path,fsep= .Platform$file.sep)
	}

	if(!is.null(furl_st))
	{
		fst_ext = unlist(strsplit(basename(furl_st),"\\."))[2]
		dest_st = file.path(getwd(),paste0("file1.",fst_ext),fsep = .Platform$file.sep)
		download.file(furl_st,dest_st)
		trace1= read.csv(file = dest_st,header = TRUE,sep = sep,quote="\"", dec=".")
	}else
	{
		if(!file.exists(fname_st))
			stop(paste(fname_st,"file not exists! Abort"))
		else
			trace1 = read.csv(file= fname_st,header = TRUE,sep = sep,quote="\"", dec=".")
	}

	if(!file.exists(fname_nd)){
		if(!is.null(furl_st))
			unlink(dest_st)
		stop(paste(fname_nd,"file not exists! Abort"))
	}else
	{
		trace2 = read.csv(fname_nd,header = TRUE,sep = sep,quote="\"", dec=".")
	}

	if(nrow(trace1)!=nrow(trace2) || ncol(trace1)!=ncol(trace2))
		stop("The two files to compare must have the same number of elements!")

	#values of the Time columns will be the names of columns
	n_ex <- length(trace1$Time)/(max(trace1$Time)-min(trace1$Time)+1) # = n_run=1000

	#iteration of all columns excluded the first (Time column)
	for(column_names in names(trace1)[-1])
	{
		trace1.ready <- data.frame()
		#the interested elements of i-run
		base = 1
		#construction of first data frame, which has the number of row equals to the number of run
		for(i in c(1:n_ex-1))
		{
			ref_column_elem = trace1[base:((base+nrow(trace1)/n_ex)-1),column_names]
			trace1.ready <- rbind(trace1.ready , ref_column_elem)
			base = base + nrow(trace1)/n_ex
		}
		cnames = "Time0"
		for(i in c(2:(nrow(trace1)/n_ex)))
			cnames = c(cnames,paste0("Time",i-1))
		names(trace1.ready) = cnames


		if(!dir.exists("./fda_files"))
			dir.create("./fda_files",showWarnings = FALSE)
		write.table(trace1.ready,
					file = file.path(paste0("./fda_files",.Platform$file.sep,"fda_fstfile_",column_names,".trace"))
					,sep=" ",append=FALSE, row.names = FALSE)

		n_ex <- length(trace2$Time)/(max(trace2$Time)-min(trace2$Time)+1) # = n_run=1000
		trace2.ready <- data.frame()
		base = 1
		#construction of second data frame
		for(i in c(1:n_ex-1))
		{
			ref_column_elem = trace2[base:((base+nrow(trace2)/n_ex)-1),column_names]
			trace2.ready <- rbind(trace2.ready , ref_column_elem)
			base = base + nrow(trace2)/n_ex
		}
		cnames = "Time0"
		for(i in c(2:(nrow(trace2)/n_ex)))
			cnames = c(cnames,paste0("Time",i-1))
		names(trace2.ready) = cnames

		write.table(trace2.ready,
					file = file.path(paste0("./fda_files",.Platform$file.sep,"fda_fndfile_",column_names,".trace"))
					,sep=" ",append=FALSE, row.names = FALSE)
	}


	#TODO fdatest e plot

	cat("\nEND DATA ANALYSIS...")
}
# det_results_check(fname_st = "results_reference/deterministic_model/model_analysis-1.trace",
# 				  fname_nd = "results_reference/deterministic_model/model_analysis-1 (copy).trace")
# sto_results_check(fname_st = "results_reference/stochastic_model/model_analysis-1_TAUG_corretto.trace",
# 				  fname_nd = "results_reference/stochastic_model/model_analysis-1_TAUG_corretto_copy.trace")
fda_check(fname_st = "results_reference/stochastic_model/model_analysis-1_SSA.trace",
		  fname_nd = "results_reference/stochastic_model/model_analysis-1_TAUG_corretto.trace")
