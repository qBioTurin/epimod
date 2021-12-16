sensitivity.prcc<-function(config,
                           target_value_fname, target_value,
                           s_time, f_time,
                           out_fname, out_dir,
                           parallel_processors
){
    # Prepare the dataset to compute PRCC.
    # Only parameters changing within the configuration will be used
    # Function to flatten a matrix
    # flatten <- function(x, name){
    #     x <- as.data.frame(x)
    #     d <- dim(x)
    #     if(d[1] > 1)
    #     {
    #         ##### Check if there are equal rows in the matrix and remove them
    #         x <- unique(x)
    #         d <- dim(x)
    #         ###
    #     }
    #     nms<-c()
    #     ret<-NULL
    #     if(d[1] > 1)
    #     {
    #     	##### Check if there are equal rows in the matrix
    #     	x <- unique(x)
    #     	d <- dim(x)
    #     	###
    #
    #         for(i in 1:d[1]){
    #             for(j in 1:d[2])
    #                 nms <- c(nms, paste0(name,"_",i,"-",j))
    #                 if(i == 1)
    #                     ret <- x[i,]
    #                 else
    #                     ret <- c(ret,x[i,])
    #         }
    #         # ret<-as.data.frame(ret)
    #         ret<- as.data.frame(matrix(ret,nrow = 1))
    #         names(ret)<-nms
    #     }
    #     else{
    #         ret <- as.data.frame(x)
    #         if(d[2] > 1){
    #             names(ret) <- paste0(name,c(1:length(ret)))
    #         }
    #         else{
    #             names(ret) <- name
    #         }
    #     }
    #     return(ret)
    # }
    flatten <- function(x, name)
  	{
    	ret <- data.frame()
    	if(!is.null(nrow(x))){
    		for(i in c(1:nrow(x)))
    		{
    			r <- as.data.frame(t(x[i,]))
    			names(r) <- paste0(name,"-", i, "-", c(1:ncol(x)))
    			if(i == 1)
    			{
    				ret <- r
    			} else {
    				ret <- cbind(r)
    			}
    		}
    	} else {
    		ret <- data.frame(x)
    		names(ret) <- paste0(name, "-1")
    	}
    	ret[vapply(ret, function(x) length(unique(x)) > 1, logical(1L))]
    	return(ret)
    }
    # Extracts the target value from the simulations' trace
    target <- function(id, target_value_fname, target_value, out_fname, out_dir){
        # Read the output and compute the distance from reference data
    		print(paste0("[sensitivity.prcc.target] Reading trace ",
    								 out_dir,
    								 out_fname,"-",
    								 id,".trace") )
        trace <- read.csv(paste0(out_dir,out_fname,"-", id,".trace"), sep = "", header = TRUE)
        # Load distance definition
        source(target_value_fname)
        # Read target fields and return a single column data serie
        print("[sensitivity.prcc.target] computing distance ...")
        tgt <- do.call(target_value, list(trace))
        print("[sensitivity.prcc.target] Done!" )
        return(tgt)
    }
    compute_prcc <- function(time,config,data){
        # Dataframe containing the configuration generated and, as last column, the corresponding model output
        dat<-cbind(config,t(data[which(data$Time==time),][-1]))
        dat<- lapply(1:length(dat[1,]),
        			 function(x){
        			 	unlist(dat[,x])
        			 })
        dat<-do.call("cbind",dat)
        dat <- as.data.frame(dat)
        names(dat) <- c(names(config)[!is.na(names(config))],"Output")
        prcc<-epiR::epi.prcc(dat)
        return(list( prcc= prcc$gamma, p.value=prcc$p.value ) )
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
    print("[sensitivity.prcc] Done filtering Variables!")
    print(paste0("[sensitivity.prcc] Computing PRCC using ",
    						 length(parms), " variables and ",
    						 n_config," model realizations.") )
    pos<- sapply(1:length(parms[1,]), function(k){
        if(length(unique(parms[,k]))==1) return(FALSE) else return(TRUE)})
    pnames <- names(parms)[pos]
    parms <- parms[,pos]
    names(parms)<-pnames
    print("[sensitivity.prcc] Extracting target variable...")
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
    								target,
    								target_value_fname = target_value_fname,
    								target_value = target_value,
    								out_fname = out_fname,
    								out_dir = out_dir)
    # parallel::stopCluster(cl)
    print("[sensitivity.prcc] Done extracting target variable!")
    # Make it a data.frame
    tval <- do.call("cbind",tval)
    # Add a column for the time
    # Check next line, it could be wrong: different number of rows
    tval <- as.data.frame(cbind(c(0,1:(f_time%/%s_time))*s_time, tval))
    tval <- tval[-1,]
    names(tval)[1] <- "Time"
    print("[sensitivity.prcc] Computing PRCC...")
    PRCC.info<-lapply(tval$Time,
                      compute_prcc,
                      config = parms,
                      data = tval)
    print("[sensitivity.prcc] Done computing PRCC!")
    PRCC<-sapply(1:length(tval$Time),function(x) PRCC.info[[x]]$prcc )
    P.values<-sapply(1:length(tval$Time),function(x) PRCC.info[[x]]$p.value )
    PRCC <- as.data.frame(t(as.data.frame(PRCC)))
    p.values <- as.data.frame(t(as.data.frame(P.values)))
    names(PRCC) <- pnames
    names(P.values) <- pnames
    return(list(PRCC=PRCC,P.values=P.values))
}
