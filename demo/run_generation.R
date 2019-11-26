library(epimod)
local_dir <- "/some/path/to/some/directory/Pipeline/"
model_generation(out_fname = "Solver",
                  net_fname = paste0(local_dir, "Pertussis"),
                  functions_fname = "transitions.cpp")
