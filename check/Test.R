source("Parameters.R")

model_generation_test(net_fname = "Net/SIR.PNPRO", functions_fname = "Cpp/transitions.cpp")
#model_generation(net_fname = "Net/SIR.PNPRO", functions_fname = "Cpp/transitions.cpp")
sensitivity_analysis_test(n_config = 100,
                          parameters_fname = "Input/Functions_list.csv",
                          functions_fname = "Rfunction/Functions.R",
                          solver_fname = "Net/SIR.solver",
                          target_value_fname = "Rfunction/Target.R",
                          parallel_processors = 1,
                          reference_data = "Input/reference_data.csv",
                          distance_measure_fname = "Rfunction/msqd.R",
                          f_time = 7*10, # weeks
                          s_time = 1 # days
)
#sensitivity_analysis(n_config = 100,parameters_fname = "Input/Functions_list.csv",functions_fname = "Rfunction/Functions.R",
#                          solver_fname = "Net/SIR.solver",target_value_fname = "Rfunction/Target.R",parallel_processors = 1,
#                          f_time = 7*10, # weeks 
#                          s_time = 1 # days
#)