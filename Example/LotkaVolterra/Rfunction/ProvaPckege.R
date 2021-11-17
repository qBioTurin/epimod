

# Example of analysis: Prey-Predator model

library(epimod)

setwd("~/GIT/R_packages_project/epimod/Example")


downloadContainers()
# Model generation step
model_generation(net_fname = "PredyPredator.PNPRO")
# Sensitivity Analisys using a user-function stored in Functions.R
# See PlotOrbitsSensitivityAnalysis for drawing the phase-space plot
sensitivity<-sensitivity_analysis(n_config = 10,
                                  parameters_fname = "Functions_list.csv",
                                  functions_fname = "Functions.R",
                                  solver_fname = "PredyPredator.solver",
                                  f_time = 20,
                                  s_time = .1)
# With target:
sensitivity<-sensitivity_analysis(n_config = 20,
                                  parameters_fname = "Functions_list.csv",
                                  functions_fname = "FunctionsTarget.R",
                                  solver_fname = "PredyPredator.solver",
                                  reference_data = "reference_data.csv",
                                  distance_measure_fname = "msqd.R" ,
                                  target_value_fname = "Target.R" ,
                                  f_time = 20,
                                  s_time = .1)

# Calibraation Analysis

model_calibration(out_fname = "calibration",
                  parameters_fname = "Functions_list.csv",
                  functions_fname = "CalibrationFunctionsTarget.R",
                  solver_fname = "PredyPredator.solver",
                  reference_data = "reference_data.csv",
                  distance_measure_fname = "msqd.R" ,
                  f_time = 20,
                  s_time = .1,
                  # Vectors to control the optimization
                  ini_v = c(5,5),
                  ub_v = c(10, 10),
                  lb_v = c(0, 0),
                  optim_vector_mod = TRUE,
                  max.call = 20,
                  threshold.stop = 1e-3,
                  max.time = 30
)

model_calibration(out_fname = "calibration",
                  solver_fname = "PredyPredator.solver",
                  reference_data = "reference_data.csv",
                  distance_measure_fname = "msqd.R" ,
                  f_time = 20,
                  s_time = .1,
                  # Variables to control the optimization
                  ini_v = c(20,20),
                  ub_v = c(40, 40),
                  lb_v = c(0, 0),
                  optim_vector_mod = FALSE,
                  max.call = 2000,
                  threshold.stop = NULL,
                  max.time = 30
)

####### With General function
# Model generation step
setwd("ExampleWithGeneralFunction/")
model_generation(net_fname = "PredyPredator.PNPRO",functions_fname="transitions.cpp")


# What-if Analysis

model_analysis(out_fname = "model_analysis",
               # Parameters to control the simulation
               solver_fname = "PredyPredator.solver",
               f_time = 20,
               s_time = .1,
               n_run = 1,
               solver_type = "LSODA",
               # User defined simulation's parameters
               # parameters_fname = "Functions_list.csv",
               # functions_fname = "CalibrationFunctionsTarget.R",
               # ini_v = c(1,1),
               # Parameters to manage the simulations' execution
               parallel_processors = 1
)
