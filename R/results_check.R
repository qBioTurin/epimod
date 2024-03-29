#' @title Check the results files
#' @description This function can compare the results obtained by a deterministic model, in this case
#' the files are compared using the diff unix command, obtained by two different stochastic model
#' calculating the confidence intervals and do a simple form of functional data analysis using
#' the fdatest package. Produce a file log with the output of the used functions.
#' @param fname_st Path to the first file to compare
#' @param fname_nd Path to the second file to compare
#' @param fun A string that defines which control algorithm apply (det_check, sto_check, fda_test)
#' @param furl_st Url of the first file to compare
#' @param threshold A threshold used to compare the p-values generated in functional data analysis
#'
#' @export
#'
#' @author Daniele Baccega, Luca Rosso

library(fdatest)

log_it <- function(msg, fun){
	write(msg,
				file = file.path(paste0("./results_check/", fun, .Platform$file.sep, "results.log")),
				append = TRUE)
}

compare_file <- function(furl_st, fname_st, fname_nd, fun){
	if(is.null(furl_st) && is.null(fname_st)){
		log_it("ERROR: Missing path of first file to compare! Abort", fun)
		stop("Missing path of first file to compare! Abort")
	}


	if(is.null(fname_nd)){
		log_it(paste("WARNING: missing path of second file to compare,
								 using results_reference/deterministic_model/model_analysis-1.trace
								 as default"), fun)
		warning("WARNING: missing path of second file to compare,
            using results_reference/deterministic_model/model_analysis-1.trace
						as default")
		path = "results_reference/deterministic_model/model_analysis-1.trace"
		fname_nd = paste0(getwd(), .Platform$file.sep, path)
	}


	if(!is.null(furl_st)){
		fst_ext = unlist(strsplit(basename(furl_st), "\\."))[2]
		dest_st = paste0(getwd(), .Platform$file.sep, "file1.", fst_ext)
		download.file(furl_st, dest_st)
	}else{
		if(!file.exists(fname_st)){
			log_it(paste("ERROR:", fname_st, "file not exists! Abort"), fun)
			stop(paste("ERROR:", fname_st, "file not exists! Abort"))
		}

		fst_ext = unlist(strsplit(basename(fname_st), "\\."))[2]
		dest_st = paste0(getwd(), .Platform$file.sep, "file1.", fst_ext)
		file.copy(from = fname_st, to = dest_st)
	}

	if(!file.exists(fname_nd)){
		unlink(dest_st)
		log_it(paste("ERROR:", fname_nd, "file not exists! Abort"), fun)
		stop(paste(fname_nd, "file not exists! Abort"))
	}

	fnd_ext = unlist(strsplit(basename(fname_nd), "\\."))[2]
	dest_nd = paste0(getwd(), .Platform$file.sep, "file2.", fnd_ext)
	file.copy(from = fname_nd, to = dest_nd)

	if(.Platform$OS.type == "unix")
	{
		if(system(paste("diff", basename(dest_st), basename(dest_nd)), ignore.stdout = FALSE) == 1){
			log_it("The two files are not equal", fun)
			suppressWarnings(out <- system(paste("diff", basename(dest_st), basename(dest_nd)), intern = TRUE))
			log_it(out, fun)
		}
		else{
			log_it("The two files are equal", fun)
		}

	}
	unlink(dest_st)
	unlink(dest_nd)
}

det_results_check <- function(fname_st, fname_nd, furl_st){
  if(dir.exists("./results_check/det_check"))
  	unlink("./results_check/det_check", recursive = TRUE)

  	dir.create("./results_check/det_check")

  	log_it("STARTING RESULTS CHECK FOR DETERMINISTIC MODEL...", "det_check")
		compare_file(furl_st, fname_st, fname_nd, "det_check");
    log_it("END RESULTS CHECK FOR DETERMINISTIC MODEL...", "det_check")
}

#Here we compute the mean of the different columns for each time step on the first file and
#the confidence intervals on the second file, then we check if the calculated means respect the calculated intervals.
sto_results_check <- function(fname_st = NULL, fname_nd = NULL, furl_st = NULL, sep = " "){
	fun = "sto_check"

	if(dir.exists("./results_check/sto_check"))
		unlink("./results_check/sto_check", recursive = TRUE)

	dir.create("./results_check/sto_check")

  log_it("STARTING RESULTS CHECK FOR STOCHASTIC MODEL...", fun)
  if(is.null(furl_st) && is.null(fname_st)){
  	log_it("ERROR: Missing path of first file to compare! Abort", fun)
  	stop("Missing path of first file to compare! Abort")
  }


  if(is.null(fname_nd))
  {
  	log_it(paste("WARNING: missing path of second file to compare,
  							 using results_reference/stochastic_model/model_analysis-1.trace
  							 as default"), fun)
    warning("WARNING: missing path of second file to compare,
            using results_reference/stochastic_model/model_analysis-1.trace
    				as default")
    path = "results_reference/stochastic_model/model_analysis-1.trace"
    fname_nd = file.path(getwd(), path, fsep = .Platform$file.sep)
  }

  if(!is.null(furl_st))
  {
    fst_ext = unlist(strsplit(basename(furl_st), "\\."))[2]
    dest_st = file.path(getwd(), paste0("file1.", fst_ext), fsep = .Platform$file.sep)
    #dest_st = paste0(getwd(),.Platform$file.sep,"file1.",fst_ext)
    download.file(furl_st, dest_st)
    trace1 = read.csv(file = dest_st, header = TRUE, sep = sep, quote = "\"", dec = ".", row.names = NULL)
  }else{
    if(!file.exists(fname_st))
    {
    	log_it(paste("ERROR:", fname_st, "file not exists! Abort"), fun)
    	stop(paste(fname_st, "file not exists! Abort"))
    }else{
    	trace1 = read.csv(file = fname_st, header = TRUE, sep = sep, quote = "\"", dec = ".", row.names = NULL)
    }
  }

  if(!file.exists(fname_nd)){
    if(!is.null(furl_st))
      unlink(dest_st)
  	log_it(paste("ERROR:", fname_nd, "file not exists! Abort"), fun)
    stop(paste(fname_nd, "file not exists! Abort"))
  }else{
  	trace2 = read.csv(fname_nd, header = TRUE, sep = sep, quote = "\"", dec = ".", row.names = NULL)
  }

	if(nrow(trace1) != nrow(trace2)){
		log_it("ERROR: The two files to compare must have the same number of elements!", fun)
		stop("The two files to compare must have the same number of elements!")
	}

	alpha <- 0.01
	n_ex <- length(trace1$Time) / length(unique(trace1$Time))

	#Create frame1 with the mean of all variables in the referred file
	trace1.nms <- names(trace1)
	trace1.ci <- data.frame()
	#For all unique values of Time column create an entry with intervals
	for(j in unique(trace1$Time))
	{
		iteration1.ci <- data.frame()
		# Get only the rows relative to the current Time
		trace1.iter <- trace1[trace1$Time == j,]
		#For all columns of observation's j-time compute the mean
		for(n in trace1.nms)
		{
			if(n != "Time")
			{
				#All values of interested column
				values <- trace1.iter[[n]]
				#Correspond to one row
				var1.ci <- data.frame(mean = mean(values))
				#The columns' names of the row just calculated take the values of S_mean, I_mean and R_mean
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


	#Create frame2 with the confidence interval of all variables in the referred file
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
				var2.ci <- data.frame(lower =  mean(values) - qt(1 - alpha / 2, n_ex - 1) * sd(values) / sqrt(n_ex),
									  					upper =  mean(values) + qt(1 - alpha / 2, n_ex - 1) * sd(values) / sqrt(n_ex))
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
		#Entry related to a specific time (for example all experiments with Time=0) with all the variables and intervals
		trace2.ci <- rbind(trace2.ci, iteration2.ci)
	}

	printed_error = FALSE
	#Control if all means calculated in the first dataframe respect their confidence interval
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
			lb_value = trace2.ci[trace2.ci$Time == referred_row[[1]], lb_index]
			ub_value = trace2.ci[trace2.ci$Time == referred_row[[1]], ub_index]
			#the mean must be in the interval calculated
			if(!(lb_value <= sing_val & sing_val <= ub_value)){
				log_it(paste0("Time:", referred_row[[1]], "  ", names(trace1)[column], ":",
							 sing_val, " not in interval [", lb_value, ",", ub_value, "]"), fun)
				printed_error = TRUE
			}

			lb_index = lb_index + 2
			ub_index = ub_index + 2
		}
	}

	if(!is.null(furl_st))
		unlink(dest_st)

	if(!printed_error)
		log_it("The calculated means respect the confidence intervals!", fun)

	log_it("END RESULTS CHECK FOR STOCHASTIC MODEL...", fun)
}

fda_check <- function(fname_st = NULL, fname_nd = NULL, furl_st = NULL, sep = " ", threshold){
	fun = "fda_check"

	if(dir.exists("./results_check/fda_check"))
		unlink("./results_check/fda_check", recursive = TRUE)

	dir.create("./results_check/fda_check")

	log_it("STARTING FUNCTION DATA ANALYSIS...", fun)
	if(is.null(furl_st) && is.null(fname_st))
	{
		log_it("ERROR: Missing path of first file to compare! Abort", fun)
		stop("Missing path of first file to compare! Abort")
	}


	if(is.null(fname_nd))
	{
		log_it(paste("WARNING: missing path of second file to compare,
								 using results_reference/stochastic_model/model_analysis-1_SSA_copy.trace
								 as default"), fun)
		warning("WARNING: missing path of second file to compare,
            using results_reference/stochastic_model/model_analysis-1_SSA_copy.trace
						as default")
		path = "results_reference/stochastic_model/model_analysis-1_SSA_copy.trace"
		fname_nd = file.path(getwd(), path, fsep = .Platform$file.sep)
	}

	if(!is.null(furl_st))
	{
		fst_ext = unlist(strsplit(basename(furl_st), "\\."))[2]
		dest_st = file.path(getwd(), paste0("file1.", fst_ext), fsep = .Platform$file.sep)
		download.file(furl_st, dest_st)
		trace1 = read.csv(file = dest_st, header = TRUE, sep = sep, quote = "\"", dec = ".", row.names = NULL)
	}else
	{
		if(!file.exists(fname_st))
		{
			log_it(paste("ERROR:", fname_st, "file not exists! Abort"), fun)
			stop(paste(fname_st, "file not exists! Abort"))
		}else{
			trace1 = read.csv(file = fname_st, header = TRUE, sep = sep, quote = "\"", dec = ".", row.names = NULL)
		}

	}

	if(!file.exists(fname_nd)){
		if(!is.null(furl_st))
			unlink(dest_st)
		log_it(paste("ERROR:", fname_nd, "file not exists! Abort"), fun)
		stop(paste(fname_nd, "file not exists! Abort"))
	}else
	{
		trace2 = read.csv(fname_nd, header = TRUE, sep = sep, quote = "\"", dec = ".", row.names = NULL)
	}

	if(nrow(trace1) != nrow(trace2) || ncol(trace1) != ncol(trace2))
	{
		log_it("ERROR: The two files to compare must have the same number of elements!", fun)
		stop("The two files to compare must have the same number of elements!")
	}


	if(!all(names(trace1) == names(trace2), na.rm = TRUE))
	{
		log_it("ERROR: The columns of the two files to compare must have the same name", fun)
		stop("The columns of the two files to compare must have the same name")
	}


	#Values of the Time columns will be the names of columns
	n_ex <- length(trace1$Time) / length(unique(trace1$Time))

	#Iteration of all columns excluded the first (Time column)
	#for(column_names in names(trace1)[-1])
	#for(column_names in "S")
	for(column_names in names(trace1)[-1])
	{
		trace1.ready <- data.frame()
		#The interested elements of i-run
		base = 1
		#Construction of first data frame, which has the number of row equals to the number of run
		for(i in c(1:n_ex-1))
		{
			ref_column_elem = trace1[base:((base + nrow(trace1) / n_ex) - 1), column_names]
			trace1.ready <- rbind(trace1.ready , ref_column_elem)
			base = base + nrow(trace1) / n_ex
		}
		cnames = "Time0"
		for(i in c(2:(nrow(trace1) / n_ex)))
			cnames = c(cnames, paste0("Time", i-1))
		names(trace1.ready) = cnames

		#Writing the new format on file
		#write.table(trace1.ready,
		# 		file = file.path(paste0("./fda_files", .Platform$file.sep, "fda_fstfile_", column_names, ".trace")),
		# 		sep=" ", append=FALSE, row.names=FALSE)

		n_ex <- length(trace2$Time) / length(unique(trace2$Time))
		trace2.ready <- data.frame()
		base = 1
		#Construction of second data frame, which has the number of row equals to the number of run
		for(i in c(1:n_ex-1))
		{
			ref_column_elem = trace2[base:((base + nrow(trace2) / n_ex) - 1), column_names]
			trace2.ready <- rbind(trace2.ready, ref_column_elem)
			base = base + nrow(trace2) / n_ex
		}
		cnames = "Time0"
		for(i in c(2:(nrow(trace2) / n_ex)))
			cnames = c(cnames,paste0("Time", i-1))
		names(trace2.ready) = cnames

		#Writing the new format on file
		#write.table(trace2.ready,
		#			file = file.path(paste0("./fda_files", .Platform$file.sep, "fda_fndfile_", column_names, ".trace")),
		#			sep=" ", append=FALSE, row.names = FALSE)

		ITP.result <- ITP2bspline(trace1.ready, trace2.ready, nknots=20, B=1000)

		#Open graphic device to print plot and images on png
		png(file = file.path(paste0("./results_check/fda_check", .Platform$file.sep, "place", column_names, "_%2d.png")),
			width = 1300, height = 900)

		for(i in c(1:nrow(trace1.ready)))
		{
			if(i == 1)
			{
				#Set margin
				par(mar=c(5, 5, 4, 2) + 0.1)
				#Set plot
				plot(c(1:ncol(trace1.ready)), trace1.ready[i,], type="l", col="black", lty=2, ylim=c(min(trace1.ready)-100,
					max(trace1.ready)+100), xlab="time", ylab="population", main=paste("Place's real traces ", column_names),
					cex.lab=2, cex.main=2, yaxt="n", xaxt="n")
				axis(1, cex.axis=2)
				axis(2, cex.axis=2)
				legend(x = "topright",                                           # Position
					   inset = 0.08,                                               # Distance from the margin as a fraction of the plot region
					   cex = 1.5,                                                  # Change legend size
					   title = "Solver type",                                      # Title
					   legend = c("Trace 1 solver", "Trace 2 solver"),             # Legend texts
					   lty = c(2, 1),                                              # Line types
					   col = c("black", "red"),                                    # Line colors
					   lwd = 1)                                                    # Line width
			}else{
			 	points(c(1:ncol(trace1.ready)), trace1.ready[i,], type="l", lty=2, col="black")
			 }
		}

		for(i in c(1:nrow(trace2.ready)))
		{
			points(c(1:ncol(trace2.ready)), trace2.ready[i,], type="l", col="red")
		}


		plot(ITP.result, xlab="time", ylab="population", main=paste("Place's curve fitting", column_names),
			 cex.lab=2, cex.main=2)
		ITPimage(ITP.result)

		#If p-val >= threshold the null hypotesis it's confirmed, refused otherwise
		log_it(paste("\n\nP-val >=", threshold, "for place", column_names, ":"), fun)
		for(i in ITP.result[["pval"]])
		{
			if(i >= threshold)
			{
				log_it(paste(i,"  PASS"), fun)
			}else{
				log_it(paste(i,"  FAIL"),fun)
			}
		}

		#Writing p-val and p-val matrix on file
		#lapply(ITP.result[["pval"]], write,
		#	   file = file.path(paste0("./results_check/fda_check", .Platform$file.sep, "pval_col_", column_names, ".txt")),
		#	   append = TRUE)
		#write.matrix(ITP.result[["pval.matrix"]],
		#			 file = file.path(paste0("./fda_files", .Platform$file.sep, "pval_matr_col_", column_names, ".txt")))
	}

	#Close graphic device
	dev.off()

	log_it("END DATA ANALYSIS...", fun)
}

results_check <- function(fname_st = NULL, fname_nd = NULL, furl_st = NULL, fun, threshold = NULL){
	if(missing(fname_st) & (is.null(furl_st) | missing(furl_st)))
		stop("Either fname_st or furl_st parameter is missing! Abort")

	if(missing(fname_nd))
		stop("fname_nd parameter is missing! Abort")

	if(missing(fun) | is.null(fun))
		stop("fun parameter must be specified! Abort")

	if(!fun %in% c("det_check","sto_check","fda_test"))
		stop("The specified function doesn't exist! You can choose between det_check, sto_check and fda_test")

	if(fun == "fda_test" & (is.null(threshold) | missing(threshold)))
	   stop("threshold parameter must be specified! Abort")

	if(!dir.exists("./results_check"))
		dir.create("results_check")

	switch(fun,
		   "det_check" = det_results_check(fname_st, fname_nd, furl_st),
		   "sto_check" = sto_results_check(fname_st, fname_nd, furl_st),
		   "fda_test" = fda_check(fname_st, fname_nd, furl_st, threshold = threshold))
}
#Example of running det_check:
#results_check("results_reference/deterministic_model/model_analysis-1.trace",
#			  "results_reference/deterministic_model/model_analysis-1 (modified).trace",
#			  "det_check")
#results_check(furl_st = "https://raw.githubusercontent.com/qBioTurin/SIR/master/Results/results_sensitivity_analysis/SIR.solver",
#			  fname_nd = "Results/results_model_analysis/SIR.solver",
#			  fun = "det_check")
#results_check("Results/results_model_analysis/SIR.solver", "Results/results_model_analysis/SIR.solver", "det_check")

#Example of running sto_check:
#results_check(fname_st = "results_reference/stochastic_model/model_analysis-1_TAUG.trace",
#			  fname_nd = "results_reference/stochastic_model/model_analysis-1_TAUG_copy.trace",
#			  fun = "sto_check")
#results_check(fname_st = "results_reference/stochastic_model/model_analysis-1_SSA.trace",
#			  fname_nd = "results_reference/stochastic_model/model_analysis-1_TAUG.trace",
#			  fun = "sto_check")

#Example of running fda_check:
#results_check(fname_st = "results_reference/stochastic_model/model_analysis-1_SSA.trace",
#		  fname_nd = "results_reference/stochastic_model/model_analysis-1_TAUG.trace",
#		  fun = "fda_test",
#		  threshold = 0.05)
#
#
#Useful commands to create a single .trace file with all traces into a given
#directory (e.g. results_sensitivity_analysis):
#tail -n +2 -q SIR-sensitivity-*.trace | awk '{$1=$1};1' > SIR.trace
#sed -i '1s/^/Time S I R\n/' SIR.trace
#
#WARNING!
#Maybe, in the case of sto_check and fda_test, it's necessary to check the input traces
#files or to create a .trace file that includes all .trace files into a given directory
#with the above commands.
