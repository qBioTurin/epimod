

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
                  functions_fname = "FunctionsTarget.R",
                  solver_fname = "PredyPredator.solver",
                  reference_data = "reference_data.csv",
                  distance_measure_fname = "msqd.R" ,
                  target_value_fname = "Target.R" ,
                  f_time = 20,
                  s_time = .1,
                  # Vectors to control the optimization
                  ini_v = c(0,0),
                  ub_v = c(10, 10),
                  lb_v = c(0, 0),
                  nb.stop.improvement = 150)



####### With General function
# Model generation step
setwd("ExampleWithGeneralFunction/")
model_generation(net_fname = "PredyPredator.PNPRO",functions_fname="transitions.cpp")

