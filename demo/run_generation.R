library(epimod)
# local_dir <- "/some/path/to/some/directory/Pipeline/"
local_dir <- "/home/paolo/Documents/git/epimod/inst/"
model_generation(out_fname = "Solver",
                  net_fname = paste0(local_dir, "Net/Pertussis.PNPRO"),
                  functions_fname = paste0(local_dir, "Cpp/transitions.cpp"))
