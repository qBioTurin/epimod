sensitivity.prcc<-function(config,
                           # target_value_fname, target_value,
													 functions_fname, target_value,
                           i_time, s_time, f_time,
                           out_fname, out_dir,
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
    # Extracts the target value from the simulations' trace
    targetExtr <- function(id, functions_fname, target_value, out_fname, out_dir){
        # Read the output and compute the distance from reference data
    		print(paste0("[sensitivity.prcc.target] Reading trace ",
    								 out_dir,
    								 out_fname,"-",
    								 id,".trace") )
        trace <- read.csv(file = paste0(out_dir,out_fname,"-", id,".trace"), sep = "", header = TRUE)
        # Load distance definition
        source(functions_fname)
        # Read target fields and return a single column data serie
        print("[sensitivity.prcc.target] computing target ...")
        tgt <- do.call(target_value, list(trace))
        print("[sensitivity.prcc.target] Done!")
        return(tgt)
    }
    compute_prcc <- function(time,config,data){
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
    n_config <- length(config[[1]])
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
        if(dim(unique(config[[i]]))[1] > 1)
            if(is.null(parms))
                parms <- config[[i]]
            else
                parms <- cbind(parms,config[[i]])
    }
    pos<- sapply(1:length(parms[1,]), function(k){
        if(length(unique(parms[,k]))==1) return(FALSE) else return(TRUE)})
    pnames <- names(parms)[pos]
    parms <- parms[,pos]
    pnames.unique <- unique(gsub(x=pnames, pattern="(-[0-9]+-){1}", replacement = "-"))
    print("[sensitivity.prcc] Done filtering Variables!")
    print(paste0("[sensitivity.prcc] Computing PRCC using ",
    						 length(pnames.unique), " variables and ",
    						 n_config," model realizations.") )
    # names(parms)<-pnames
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
    tval <- lapply( c(1:n_config),
    								targetExtr,
    								functions_fname = functions_fname,
    								target_value = target_value,
    								out_fname = out_fname,
    								out_dir = out_dir)
    # parallel::stopCluster(cl)
    print("[sensitivity.prcc] Done extracting target variable!")
    # Make it a data.frame
    tval <- do.call("cbind",tval)
    # Add a column for the time
    # Check next line, it could be wrong: different number of rows
    tval <- as.data.frame(cbind(seq(from = i_time, to = f_time, by = s_time), tval))
    # tval <- tval[-1,]
    names(tval)[1] <- "Time"
    print("[sensitivity.prcc] Computing PRCC...")
    PRCC.info<-lapply(X = tval$Time,
                      FUN = function(X, config, data){
                      	tryCatch(expr = compute_prcc(time = X,config = config, data = data),
                      					error = function(e){
                      						return(list(prcc=rep(NA, length(pnames.unique)), P.values=rep(NA, length(pnames.unique))))
                      					})
                      },
                      config = parms,
                      data = tval)
    print("[sensitivity.prcc] Done computing PRCC!")
    PRCC<-lapply(1:length(tval$Time),function(x) PRCC.info[[x]]$prcc )
    # PRCC <- as.data.frame(t(as.data.frame(PRCC)))
    PRCC <- do.call("rbind", PRCC)
    PRCC <- as.data.frame(PRCC)
    names(PRCC) <- pnames.unique
    P.values<-lapply(1:length(tval$Time),function(x) PRCC.info[[x]]$p.value )
    P.values <- do.call("rbind", P.values)
    # p.values <- as.data.frame(t(as.data.frame(P.values)))
    P.values <- as.data.frame(as.data.frame(P.values))
    names(P.values) <- pnames.unique
    return(list(PRCC=PRCC,P.values=P.values))
}
