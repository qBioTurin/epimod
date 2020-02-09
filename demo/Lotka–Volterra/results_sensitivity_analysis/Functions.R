####
#
#
###

init_generation<-function(min_init , max_init)
{
   # min/max are vectors = first position interval values for the first place and second position for the second place

   i_1=runif(n=1,min=min_init[1],max=max_init[1])
   i_2=runif(n=1,min=min_init[2],max=max_init[2])

   return( c(i_1,i_2) )
}

