# library(epimod)

# Step 1: download containers
# downloadContainers()

# Step 2: draw the model
# ....

# Step 2: Generate model
# model_generation(net_fname = "./input/SIR.PNPRO")

# Step 3: run sensitivity analysus
sensitivity<-sensitivity_analysis(n_config = 200,
                                  parameters_fname = "input/Functions_list.csv",
                                  functions_fname = "input/Functions.R",
                                  solver_fname = "SIR.solver",
                                  reference_data = "input/reference_data.csv",
                                  distance_measure_fname = "input/msqd.R" ,
                                  target_value_fname = "input/Target.R" ,
                                  f_time = 70,
                                  s_time = 0.1)

# Step 4: run calibration
model_calibration(out_fname = "calibration",
                  parameters_fname = "input/Functions_list_Calibration.csv",
                  functions_fname = "input/FunctionCalibration.R",
                  solver_fname = "SIR.solver",
                  reference_data = "input/reference_data.csv",
                  distance_measure_fname = "input/msqd.R" ,
                  f_time = 7*10, # weeks
                  s_time = 1, # days
                  # Vectors to control the optimization
                  ini_v = c(0.15,0.00015),
                  ub_v = c(0.2, 0.0002),
                  lb_v = c(0.1, 0.0001),
                  ini_vector_mod = T,
                  max.call = 30
)

# Step 5: run what-if analysis
model_analysis(parameters_fname = "input/Functions_list_Calibration.csv",
               functions_fname = "input/Functions_calibration.R",
               solver_fname = "SIR.solver",
               f_time = 7*10, # weeks
               s_time = 1, # days
               # Vectors to control the optimization
               ini_v = c(0.15,0.00015)
               )
