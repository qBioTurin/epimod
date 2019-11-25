install.packages('/root/pipeline/EpiTCM.tar.gzz',  repos = NULL)
library(EpiTCM)
base_dir <- "/root/scratch/"
local_dir <- "/root/Pipeline/"
model_calibration(out_dir = paste0(base_dir, "Res/"),
                  out_fname = "calibration",
                  parameters_fname = paste0(local_dir, "Configuration/Functions_list_s.csv"),
                  functions_fname = paste0(local_dir, "Configuration/Functions.R"),
                  solver_fname = paste0(local_dir, "Configuration/Solver_s.solver"),
                  solver_type = "HLSODA",
                  n_run = 256,
                  init_fname = "init",
                  f_time = 365*21,
                  s_time = 365,
                  volume = paste0(local_dir,"Res/"),
                  timeout = "1d",
                  processors=64,
                  reference_data = paste0(local_dir, "Configuration/reference_data.csv"),
                  distance_measure_fname = paste0(local_dir, "Configuration/Measures.R"),
                  distance_measure = "aic",
                  target_value_fname = paste0(local_dir, "Configuration/Select.R"),
                  target_value_f = "infects",
                  # Vectors to control the optimization
                  ini_v = c(0.9990625,0.9826859,1,0.04128766,0.01880468,0.9953585,0.002005376,1e-7,1e-7,0.9972827,0.006188635,1e-7,1e-7),
                  ub_v = c(1,1,1,1,1,1,1,1,1,1,1,1,1)*(1+1e-7),
                  lb_v = c(1,1,1,1,1,1,1,1,1,1,1,1,1)*(1-1e-7),
                  nb.stop.improvement = 1500)
