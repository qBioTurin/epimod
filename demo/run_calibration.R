# install.packages('./EpiTCM',  repos = NULL)
library(EpiTCM)
base_dir <- "/root/scratch/"
local_dir <- "/home/paolo/Documents/git/pertussis_model/Pipeline/"
model_calibration(out_dir = paste0(base_dir, "Res/"),
                  out_fname = "calibration",
                  parameters_fname = paste0(local_dir, "Configuration/Functions_list_p.csv"),
                  functions_fname = paste0(local_dir, "Configuration/Functions.R"),
                  solver_fname = paste0(local_dir, "Configuration/Solver.solver"),
                  init_fname = "init",
                  f_time = 365*21,
                  s_time = 365,
                  volume = paste0(local_dir,"Res/"),
                  timeout = "1d",
                  processors=4,
                  reference_data = paste0(local_dir, "Configuration/reference_data.csv"),
                  distance_measure_fname = paste0(local_dir, "Configuration/Measures.R"),
                  distance_measure = "msqd",
                  target_value_fname = paste0(local_dir, "Configuration/Select.R"),
                  target_value_f = "infects",
                  # Vectors to control the optimization
                  ini_v = c(0.76178767, 0.84050871, 0.34856665, 0.08674269, 0.56469066, 0.46910767, 0.18296426, 0.30995419, 0.03797388, 0.07480976, 0.13119845, 0.33429836, 0.45969342),
                  # ub_v = c(0.85, 0.85, 1.3, 1.3, 1.3, 1.3, 1.3, 1.3, 1.3, 1.3, 1.3, 1.3, 1.3),
                  # lb_v = c(1e-7, 1e-7, 1e-7, 1e-7, 1e-7, 1e-7, 1e-7, 1e-7, 1e-7, 1e-7, 1e-7, 1e-7, 1e-7),
                  ub_v = c(1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1),
                  lb_v = c(0, 0, 1e-7, 1e-7, 1e-7, 1e-7, 1e-7, 1e-7, 1e-7, 1e-7, 1e-7, 1e-7, 1e-7),
                  nb.stop.improvement = 1500)
