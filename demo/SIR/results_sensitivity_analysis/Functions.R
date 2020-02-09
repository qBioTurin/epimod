####
#
#
###

init_generation<-function(min_init , max_init)
{
   # min/max are vectors = first position interval values for the first place and second position for the second place

    p_1=runif(n=1,min=min_init[1],max=max_init[1])


    return( c(p_1, 1e-4,0) )
}

