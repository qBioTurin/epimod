msqd<-function(reference, output)
{
    reference[,1] -> times_ref
    reference[,3] -> infect_ref

    # We will consider the same time points
    Infect <- output[which(output$Time %in% times_ref),"I"]
    infect_ref <- infect_ref[which( times_ref %in% output$Time)]

    diff.Infect <- sum(( Infect - infect_ref )^2 )

    return(diff.Infect)
}
