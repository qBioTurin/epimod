b_rate<-function(file, x = NULL)
{
    load(file)
    b_rates <- birth_rates
    return(unlist(b_rates,use.names = FALSE))
}

c_rate<-function(file, x = NULL)
{
    load(file)
    c_rates <- contact_matrix
    return(matrix(unlist(c_rates), nrow = 3))
}

d_rate<-function(file, x = NULL)
{
    load(file)
    d_rates <- death_rates
    return(matrix(unlist(d_rates), nrow = 3))
}

v_rate<-function(file, x = NULL)
{
    load(file)
    ExpMin <- function( lambda, mu, xi, phases, probability ) {
        ( lambda / ( lambda + mu + xi ) ) ^ phases - probability
    }

    v_rates<-sapply(1:length(t(vaccination_coverage)), function(x){
        uniroot( f =ExpMin , interval = c(0,100), mu = death_rates[1,x], xi = 0.0030303, probability = t(vaccination_coverage)[x] , phases = 3 ,tol = 1e-8 )$root
    } )
    return(v_rates)
}

probability <- function(file, x = NULL)
{
    load(file)
    if( is.null(x) ){
        x <- 1.5 - runif(length(probabilities))
        x[length(x)] = 0
    }
    else{
        # x <- c(0.04965668,x[c(1:2)],0)
        x <- c(0.004139731,x[c(1:2)],0.7)
    }
    return(matrix(unlist(probabilities), ncol = 1) * x)
}

initial_marking <- function(file, x = NULL)
{
    load(file)
    n_variables <- 11
    if( is.null(x))
        x <- runif(n_variables)
    else
        x <- x[c((length(x)-n_variables+1):length(x))]
    yini[c("S_a1", "R_a1_nv_l2","R_a1_nv_l3")] <- sum(yini[c("S_a1","R_a1_nv_l2","R_a1_nv_l3")]) * (x[c(1:3)]/sum(x[c(1:3)]))
    yini[c("S_a2","R_a2_nv_l2","R_a2_nv_l3","R_a2_nv_l4")] <- sum(yini[c("S_a2","R_a2_nv_l2","R_a2_nv_l3","R_a2_nv_l4")]) * (x[c(4:7)]/sum(x[c(4:7)]))
    yini[c("S_a3","R_a3_nv_l2","R_a3_nv_l3","R_a3_nv_l4")]<-  sum(yini[c("S_a3","R_a3_nv_l2","R_a3_nv_l3","R_a3_nv_l4")]) * (x[c(8:11)]/sum(x[c(8:11)]))
    return(matrix(unlist(yini), ncol = 1))
}

initial_marking_s <- function(file, x = NULL)
{
    load(file)
    n_variables <- 11
    if( is.null(x))
        x <- runif(n_variables)
    else
        x <- x[c((length(x)-n_variables+1):length(x))]
    yini[c("S_a1", "R_a1_l2","R_a1_l3")] <- sum(yini[c("S_a1","R_a1_l2","R_a1_l3")]) * (x[c(1:3)]/sum(x[c(1:3)]))
    yini[c("S_a2","R_a2_l2","R_a2_l3","R_a2_l4")] <- sum(yini[c("S_a2","R_a2_l2","R_a2_l3","R_a2_l4")]) * (x[c(4:7)]/sum(x[c(4:7)]))
    yini[c("S_a3","R_a3_l2","R_a3_l3","R_a3_l4")]<-  sum(yini[c("S_a3","R_a3_l2","R_a3_l3","R_a3_l4")]) * (x[c(8:11)]/sum(x[c(8:11)]))
    return(matrix(unlist(yini), ncol = 1))
}
