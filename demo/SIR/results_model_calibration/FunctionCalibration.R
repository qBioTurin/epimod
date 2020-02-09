#
# init_generation<-function(optim_vector)
# {
#     return(c(optim_vector[1],1e-4,0))
# }

recovery<-function(x)
{
    return(x[1])
}

infection<-function(x)
{
    return(x[2])
}
