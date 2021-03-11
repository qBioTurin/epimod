sensitivity.prcc<-function(config,
                           target_value_fname, target_value,
                           s_time, f_time,
                           out_fname, out_dir,
                           parallel_processors
){
    library(parallel)
    # Prepare the dataset to compute PRCC.
    # Only parameters changing within the configuration will be used
    # Function to flatten a matrix
    flatten <- function(x, name){
        x <- as.data.frame(x)
        d <- dim(x)
        if(d[1] > 1)
        {
            ##### Check if there are equal rows in the matrix and remove them
            x <- unique(x)
            d <- dim(x)
            ###
        }
        nms<-c()
        ret<-NULL
        if(d[1] > 1)
        {
            for(i in 1:d[1]){
                for(j in 1:d[2])
                    nms <- c(nms, paste0(name,"_",i,"-",j))
                    if(i == 1)
                        ret <- x[i,]
                    else
                        ret <- c(ret,x[i,])
            }
            # ret<-as.data.frame(ret)
            ret<- as.data.frame(matrix(ret,nrow = 1))
            names(ret)<-nms
        }
        else{
            ret <- as.data.frame(x)
            if(d[2] > 1){
                names(ret) <- paste0(name,c(1:length(ret)))
            }
            else{
                names(ret) <- name
            }
        }
        return(ret)
    }
    # Extracts the target value from the simulations' trace
    target <- function(id, target_value_fname, target_value, out_fname, out_dir){
        # Read the output and compute the distance from reference data
        trace <- read.csv(paste0(out_dir,out_fname,"-", id,".trace"), sep = "", header = TRUE)
        # Load distance definition
        source(target_value_fname)
        # Read target fields and return a single column data serie
        tgt <- do.call(target_value, list(trace))
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
        # prcc<-epi.prcc(dat)
        prcc<-epiR::epi.prcc(dat)
        return(list( prcc= prcc$gamma, p.value=prcc$p.value ) )
    }
    n_config <- abs(config[[1]][[1]][[2]])
    # Flatten all the parameters in the configuration
    config <- lapply(c(1:length(config)),function(x){
        inner_config <- lapply(c(1:n_config),function(k){
            return(flatten(config[[x]][[k]][[3]],name = config[[x]][[k]][[1]]))
        })
        return(do.call("rbind",inner_config))
    })
    # Filter out the parameters that do not chage within the configuration provided
    parms <- NULL
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
    names(parms)<-pnames
    # Create a cluster
    cl <- makeCluster(parallel_processors, type = "FORK")
    # Extract data
    tval <- parLapply( cl,
    				   c(1:n_config),
    				   target,
    				   target_value_fname = target_value_fname,
    				   target_value = target_value,
    				   out_fname = out_fname,
    				   out_dir = out_dir)
    # tval <- lapply( c(1:n_config),function(x){
    #                    target(id=x,target_value_fname = target_value_fname,
    #                    target_value = target_value,out_fname = out_fname,out_dir = out_dir)})
    stopCluster(cl)
    # Make it a data.frame
    # * tval <- t(do.call("rbind",tval))
    tval <- do.call("cbind",tval)
    # Add a column for the time
    # Check next line, it could be wrong: different number of rows
    tval <- as.data.frame(cbind(c(0,1:(f_time%/%s_time))*s_time, tval))
    tval <- tval[-1,]
    names(tval)[1] <- "Time"
    # save(tval, parms, pnames, file = paste0(params$out_dir,"parms_prcc_",params$out_fname,".RData"))
    PRCC.info<-lapply(tval$Time,
                      compute_prcc,
                      config = parms,
                      data = tval)
    PRCC<-sapply(1:length(tval$Time),function(x) PRCC.info[[x]]$prcc )
    P.values<-sapply(1:length(tval$Time),function(x) PRCC.info[[x]]$p.value )
    PRCC <- as.data.frame(t(as.data.frame(PRCC)))
    p.values <- as.data.frame(t(as.data.frame(P.values)))
    names(PRCC) <- pnames
    names(P.values) <- pnames
    return(list(PRCC=PRCC,P.values=P.values))
}
