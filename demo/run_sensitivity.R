# install.packages('~/Documents/git/pertussis_model/Pipeline/EpiTCM',  repos = NULL)
library(EpiTCM)
base_dir <- "/root/scratch/"
local_dir <- "/home/paolo/Documents/git/pertussis_model/Pipeline/"
sensitivity_analysis(n_config = 2^4,
                     out_dir = paste0(local_dir, "Res/"),
                     out_fname = "sensitivity",
                     parameters_fname = paste0(local_dir, "Configuration/Functions_list.csv"),
                     functions_fname = paste0(local_dir, "Configuration/Functions.R"),
                     solver_fname = paste0(local_dir, "Configuration/Solver.solver"),
                     init_fname = "init",
                     f_time = 365*21,
                     s_time = 365,
                     volume = paste0(local_dir, "Res/"),
                     timeout = "1d",
                     processors=4,
                     reference_data = paste0(local_dir, "Configuration/reference_data.csv"),
                     distance_measure_fname = paste0(local_dir, "Configuration/Measures.R"),
                     distance_measure = "msqd",
                     target_value_fname = paste0(local_dir, "Configuration/Select.R"),
                     target_value_f = "infects") # ,
                     # seed = "~/Desktop/ResSensitivity16k/seedssensitivity.RData")
