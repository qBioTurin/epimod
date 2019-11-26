msqd<-function(reference, output)
{
    ynames <- names(output)
    col_names <- "(InfectCount_a){1}[0-9]{1}"
    col_idxs <- c( which(ynames %in% grep(col_names, ynames, value=T)) )
    infects <- rowSums(output[,col_idxs])
    infects <- infects[-1]
    diff<-c(infects[1],diff(infects,differences = 1))
    ret <- sum(( diff - reference )^2 )
    return(ret)
}

aic<-function(reference, output)
{
    n_samples <- length(reference)
    n_run <- length(output[,1])%/%n_samples
    # Get column names
    ynames <- names(output)
    # Select columns accounting for the number of infects
    col_names <- "(InfectCount_a){1}[0-9]{1}"
    col_idxs <- c( which(ynames %in% grep(col_names, ynames, value=T)) )
    # Reshape the vector to a row vector
    tmp<-as.data.frame(rowSums(output[,col_idxs]))
    # aggregate runs by the time
    tmp<-as.data.frame(aggregate(tmp, by=list(Time=output$Time), FUN=median))
    names(tmp)<-c("Time","Infects")
    # compute the infects of each year from the cumulative infects in the interval
    tmp$Infects <- c(tmp$Infects[1],diff(tmp$Infects,differences = 1))
    tmp<-tmp[-1,]
    # Create a data.frame with median and corresponding simulation time
    avg<-as.data.frame(cbind(tmp$Time[1:(length(tmp$Time))], tmp$Infects))
    names(avg) = c("Time","Infects")
    # Squared error
    rss<-as.data.frame(sum((reference-avg$Infects)^2))
    # rss<-as.data.frame(sum(na.omit((reference-avg$Infects)^2)))
    # compute AIC
    n_params <- 2
    AIC<-2*n_params+n_samples*log(rss, base = exp(1))
    return(as.numeric(AIC))
}
