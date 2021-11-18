#
# init_generation<-function(optim_vector)
# {
#     return(c(optim_vector[1],1e-4,0))
# }

recovery<-function(x,n)
{
    return(x[1]*n)
}

infection<-function(x,n)
{
    return(x[2]*n)
}
