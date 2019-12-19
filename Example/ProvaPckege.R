

# Example of analysis: Prey-Predator model

library(epimod)
setwd("./Example")


downloadContainers()

model_generation(net_fname = "PredyPredator.PNPRO")

sensitivity<-sensitivity_analysis(n_config = 10,
                     parameters_fname = "Functions_list.csv",
                     functions_fname = "Functions.R",
                     target_value_fname = "predator.R",
                     solver_fname = "PredyPredator.solver",
                     f_time = 50,
                     s_time = 1
                     )


