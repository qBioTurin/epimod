msqd<-function(reference, output)
{
    Predator <- output[,"Predator"]
    Prey <- output[,"Prey"]

    diff.Predator <- sum(( Predator - reference[,2] )^2 )
    diff.Prey <- sum(( Prey - reference[,1] )^2 )

    return(diff.Predator+diff.Prey)
}
