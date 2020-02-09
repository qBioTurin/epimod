library(epimod)

# Step 1: download containers
downloadContainers()

# Step 2: draw the model
# ....

# Step 2: Generate model
model_generation(net_fname = "./input/PredyPredator.PNPRO")

# Step 3: run sensitivity analysus
sensitivity<-sensitivity_analysis(n_config = 200,
                                  parameters_fname = "input/Functions_list.csv",
                                  functions_fname = "input/Functions.R",
                                  solver_fname = "PredyPredator.solver",
                                  reference_data = "input/reference_data.csv",
                                  distance_measure_fname = "input/msqd.R" ,
                                  target_value_fname = "input/Target.R" ,
                                  f_time = 20,
                                  s_time = .1)

# Step 4: run calibration
model_calibration(out_fname = "calibration",
                  solver_fname = "PredyPredator.solver",
                  reference_data = "input/reference_data.csv",
                  distance_measure_fname = "input/msqd.R" ,
                  f_time = 20,
                  s_time = .1,
                  # Variables to control the optimization
                  ini_v = c(20,20),
                  ub_v = c(40, 40),
                  lb_v = c(0, 0),
                  ini_vector_mod = FALSE,
                  max.call = 2000,
                  threshold.stop = NULL,
                  max.time = 30
)

# Step 5: run what-if analysis
model_analysis(solver_fname = "PredyPredator.solver",
                  f_time = 20,
                  s_time = .1,
                  # Variables to control the optimization
                  ini_v = c(20,20),
                  ini_vector_mod = FALSE
)
