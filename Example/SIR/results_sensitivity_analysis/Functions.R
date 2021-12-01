init_generation<-function(min_init , max_init, n)
{
	S=runif(n=1,min=min_init,max=max_init)
	# It returns a vector of lenght equal to 3 since the marking is
	# defined by the three places: S, I, and R.
	return( c(S, 1,0) )
}



InfectionValuesGeneration<-function(min, max)
{
    rate_value <-  runif(n=1, min = min, max = max)
    return(rate_value)
}
