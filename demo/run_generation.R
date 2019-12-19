library(epimod)
model_generation(out_fname = "Solver",
                  net_fname = paste0(local_dir, "/inst/Net/Pertussis.PNPRO"),
                  functions_fname = paste0(local_dir, "/inst/Cpp/transitions.cpp"))
