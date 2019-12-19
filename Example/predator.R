predator<-function(output)
{
    ynames <- names(output)
    col_names <- "predator"
    col_idxs <- c( which(ynames %in% grep(col_names, ynames, value=T)) )
    # Reshape the vector to a row vector
    ret <- rowSums(output[,col_idxs])
    return(as.data.frame(ret))
}
