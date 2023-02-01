sensitivity.prcc<-function(config,
                           # target_value_fname, target_value,
													 functions_fname, target_value,
                           i_time, s_time, f_time,
                           out_fname, out_dir,
													 folder_trace,
													 out_fname_analysis,
                           parallel_processors
){
    flatten <- function(x, name)
  	{
    	ret <- data.frame()
    	x <- data.frame(x)
    	if(nrow(x) > 1 & ncol(x) == 1)
    		x <- t(x)
    	if(nrow(x) > 1){
    		x <- as.data.frame(x)
    		names(x) <- paste0(name,"-<I>-", c(1:ncol(x)))
    		x <- x[vapply(x, function(k) length(unique(k)) > 1, logical(1L))]
    		nms <- names(x)
    		for(i in c(1:nrow(x)))
    		{
    			r <- as.data.frame(x[i,])
    			names(r) <- nms
    			names(r) <- gsub(x = names(r),
    											 pattern = "<I>",
    											 replacement = i)
    			if(i == 1)
    			{
    				ret <- r
    			} else {
    				ret <- cbind(ret, r)
    			}
    		}
    	} else {
    		ret <- as.data.frame(x)
    		# names(ret) <- paste0(name, "-1")
    		if(ncol(x) > 1){
    			names(ret) <- paste0(name,"-", c(1:ncol(x)))
    		} else {
    			names(ret) <- name
    		}
    	}
    	return(ret)
    }
    # Load distance definition
    source(functions_fname)
    # Extracts the target value from the simulations' trace
    targetExtr <- function(id, functions_fname, target_value, folder_trace, out_fname_analysis){
        # Read the output and compute the distance from reference data
    		print(paste0("[sensitivity.prcc.target] Reading trace ",
    								 folder_trace,
    								 out_fname_analysis,"-",
    								 id,".trace") )
        trace <- read.csv(file = paste0(folder_trace,out_fname_analysis,"-", id,".trace"), sep = "", header = TRUE)

        # Read target fields and return a single column data serie
        print("[sensitivity.prcc.target] computing target ...")
        tgt <- do.call(target_value, list(trace))
        tgt <- data.frame(Time = trace$Time, Target = tgt)
        colnames(tgt) = c("Time",paste0("Target",id))
        print("[sensitivity.prcc.target] Done!")
        return(tgt)
    }
    compute_prcc <- function(time,config,data){
    	print(names(config))
        # Dataframe containing the configuration generated and, as last column, the corresponding model output
    		config.table <- table(gsub(x=names(config), pattern="(-[0-9]+-){1}", replacement = "-"))
    		config.names <- names(config.table)
    		config.names[config.table > 1] <- gsub(pattern = "-",
    																					 replacement = paste0("-", time, "-"),
    																					 x = config.names[config.table > 1])
    		config <- config[,which(names(config) %in% config.names)]
    		dat<-cbind(config,t(data[which(data$Time==time),][-1]))
        dat<- lapply(1:length(dat[1,]),
        			 function(x){
        			 	unlist(dat[,x])
        			 })
        dat<-do.call("cbind",dat)
        dat <- as.data.frame(dat)
        # names(dat) <- c(names(config)[!is.na(names(config))],"Output")
        names(dat) <- c(config.names,"Output")
        prcc<-epiR::epi.prcc(dat)
        return(list( prcc= prcc$est, p.value=prcc$p.value ) )
    }
    n_var <- length(config)
    traces <- list.files(path = folder_trace,pattern = ".trace$")
    n_config <- length(traces)
    traces.id = as.numeric(gsub(pattern = paste0("(",out_fname_analysis,"-)|(.trace)"),replacement = "",x = traces)
)
    print(paste0("[sensitivity.prcc] Computing PRCC using ",
    						 n_var, " variables and ",
    						 n_config," model realizations.") )
    # Flatten all the parameters in the configuration
    print("[sensitivity.prcc] Creating data structure..." )
    config <- lapply(c(1:n_var),function(x, config)
  		{
    		print(paste0("[sensitivity.prcc] Flattening variable #", x, " ..."))
    		inner_config <- lapply(c(1:n_config),function(k, cfg){
    			print(paste0("\t[sensitivity.prcc] ... configuration ", k))
    			return(flatten(cfg[[k]][[3]], name = cfg[[k]][[1]]))
        },
        cfg = config[[x]])
        return(do.call("rbind",inner_config))
    }, config = config)
    print("[sensitivity.prcc] Done creating data structure!")
    # Filter out the parameters that do not chage within the configuration provided
    parms <- NULL
    print("[sensitivity.prcc] Filtering constant variables.")
    for(i in c(1:length(config)))
    {
    	#print(unique(config[[i]]))
        if(dim(unique(config[[i]]))[1] > 1)
            if(is.null(parms))
                parms <- config[[i]]
            else
                parms <- cbind(parms,config[[i]])
    }
    if(is.null(parms))
    	stop("No parameters configurations are found, the parameters should change.")

    pos<- sapply(1:length(parms[1,]), function(k){
        if(length(unique(parms[,k]))==1) return(FALSE) else return(TRUE)})
    pnames <- names(parms)[pos]
    parms <- as.data.frame(parms[,pos])
    pnames.unique <- unique(gsub(x=pnames, pattern="(-[0-9]+-){1}", replacement = "-"))
    print("[sensitivity.prcc] Done filtering Variables!")
    print(paste0("[sensitivity.prcc] Computing PRCC using ",
    						 length(pnames.unique), " variables and ",
    						 n_config," model realizations.") )
    names(parms)<-pnames
    print("[sensitivity.prcc] Extracting target variable...")

    # source(target_value_fname)
    # Create a cluster
    # cl <- parallel::makeCluster(parallel_processors, type = "FORK")
    # Extract data
    # tval <- parallel::parLapply( cl,
    # 														 c(1:n_config),
    # 														 target,
    # 														 target_value_fname = target_value_fname,
    # 														 target_value = target_value,
    # 														 out_fname = out_fname,
    # 														 out_dir = out_dir)
    folder_trace = paste0("/home/docker/data/",basename(folder_trace),"/" )
    folder_sensitivity = paste0("/home/docker/data/",basename(out_fname) )

    tval <- lapply( traces.id,
    								targetExtr,
    								functions_fname = functions_fname,
    								target_value = target_value,
    								out_fname_analysis = out_fname_analysis,
    								folder_trace = folder_trace)
    # parallel::stopCluster(cl)
    print("[sensitivity.prcc] Done extracting target variable!")
    # Make it a data.frame
    #tval <- do.call("cbind",tval)
    tvalMerged = Reduce(function(x, y) merge(x, y, by="Time",all = T), tval)

    # Add a column for the time
    # Check next line, it could be wrong: different number of rows
    # tval <- as.data.frame(cbind(seq(from = i_time, to = f_time, by = s_time), tval))
    # tval <- tval[-1,]
    # names(tval)[1] <- "Time"
    print("[sensitivity.prcc] Computing PRCC...")
    PRCC.info<-lapply(X = tvalMerged$Time,
                      FUN = function(X, config, data){
                      	tryCatch(expr = compute_prcc(time = X,config = config, data = data),
                      					error = function(e){
                      						return(list(prcc=rep(NA, length(pnames.unique)),
                      												p.values=rep(NA, length(pnames.unique))))
                      					})
                      },
                      config = parms,
                      data = tvalMerged)
    print("[sensitivity.prcc] Done computing PRCC!")
    PRCC<-lapply(1:length(tvalMerged$Time),function(x) matrix(c(tvalMerged$Time[x], PRCC.info[[x]]$prcc),nrow = 1 ) )
    # PRCC <- as.data.frame(t(as.data.frame(PRCC)))
    PRCC <- do.call("rbind", PRCC)
    PRCC <- as.data.frame(PRCC)
    P.values<-lapply(1:length(tvalMerged$Time),function(x) matrix(c(tvalMerged$Time[x], PRCC.info[[x]]$p.value),nrow = 1 ) )
    P.values <- do.call("rbind", P.values)
    # p.values <- as.data.frame(t(as.data.frame(P.values)))
    P.values <- as.data.frame(P.values)
    names(P.values) <- colnames(PRCC) <- c("Time", pnames.unique )
    return(list(PRCC=PRCC,P.values=P.values))
}
