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
