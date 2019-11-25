# install.packages('~/Documents/git/pertussis_model/Pipeline/EpiTCM',  repos = NULL)
library(EpiTCM)
base_dir <- "/root/scratch/"
local_dir <- "/home/paolo/Documents/git/pertussis_model/Pipeline/"
model_analysis(out_dir = paste0(base_dir, "Res/"),
               out_fname = "analysis",
               parameters_fname = paste0(local_dir, "Configuration/Functions_list_p.csv"),
               functions_fname = paste0(local_dir, "Configuration/Functions_analysis.R"),
               solver_fname = paste0(local_dir, "Configuration/Solver.solver"),
               solver_type = "HLSODA",
               n_run = 4,
               init_fname = "init",
               f_time = 365*43,
               s_time = 365,
               volume = paste0(local_dir, "Res/"),
               timeout = "1d",
               # ini_v = c(0.9509333, 0.9461494, 1.013153, 0.04425904, 0.02058201, 1.07241, 0.002096745, 9.745058e-08, 9.01e-08, 1.090161, 0.005632654, 9.01e-08, 9.01e-08), # stoch

               ini_v = c(0.998382, 0.9999957 ,0.6090477, 1e-07, 1e-07, 0.9996254, 1e-07, 1e-07, 1e-07, 0.6094091, 0.4046836, 0.0008244062, 0.00032889647), # det
               processors=4)
