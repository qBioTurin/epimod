library(epimod)
model_generation(out_fname = "Solver",
                  net_fname = paste0(local_dir, "Net/Pertussis.PNPRO"),
                  functions_fname = paste0(local_dir, "Cpp/transitions.cpp"))
