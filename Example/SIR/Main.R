library(epimod)

### Model generation

start_time <- Sys.time()
model_generation(net_fname = "./Net/SIR.PNPRO")
end_time <- Sys.time()-start_time

### Sensitivity analysis

start_time <- Sys.time()
sensitivity_analysis(solver_fname = "SIR.solver",
										 i_time = 0,
										 f_time = 70,
										 s_time = 1,
										 n_config = 1000,
										 parameters_fname = "Input/Functions_list.csv",
										 parallel_processors = 4,
										 functions_fname = "Rfunction/Functions.R",
										 distance_measure_fname = "Rfunction/msqd.R",
										 reference_data = "Input/reference_data.csv",
										 seed = "seeds-SIR-sensitivity.RData")
end_time <- Sys.time()-start_time

##############################
## Let draw the trajectories
##############################
#source("./Rfunction/SensitivityPlot.R")

### Calibration analysis

start_time <- Sys.time()
model_calibration(solver_fname = "SIR.solver",
									i_time = 0,
									f_time = 70,
									s_time = 1,
									solver_type = "SSA",
									parameters_fname = "Input/Functions_list_Calibration.csv",
									functions_fname = "Rfunction/FunctionCalibration.R",
									parallel_processors = 4,
									ini_v = c(0.45, 0.0005),
									lb_v = c(0.42, 0.0002),
									ub_v = c(0.48, 0.0010),
									max.call = 200,
									distance_measure_fname = "Rfunction/msqd.R",
									reference_data = "Input/reference_data.csv",
									seed = "seeds-SIR-calibration.RData")
end_time <- Sys.time()-start_time

#source("Rfunction/CalibrationPlot.R")

### Model analysis

start_time <- Sys.time()
model_analysis(solver_fname = "SIR.solver",
							 i_time = 0,
							 f_time = 70,
							 s_time = 1,
							 n_config = 100,
							 solver_type = "SSA",
							 parameters_fname = "Input/Functions_list_ModelAnalysis.csv",
							 parallel_processors = 4,
							 seed = "seeds-SIR-analysis.RData")
end_time <- Sys.time()-start_time

#source("Rfunction/ModelAnalysisPlot.R")
