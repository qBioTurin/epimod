# Disclamer: You need to build the docker containers form the Dockerfiles
#            provided with the package. We are working to provide them through
#            Dockerhub
#
# This demo assumes you have the following folders within the same subfolder:
#   - inst folder provided with this package
#   - demo folder provided with this package
#
# Furthermore, it assumes your working directory corresponds to the subfolder
# containig the aforemenntioned folders and you have successfully installed the
# epimod library
#
library(epimod)
#
# Set the required path
base_dir <- "/root/scratch/"
local_dir <- "/set/the/directory/here/"
# Then, to run one or more steps of the pipeline you have excecute one of the
# R scripts provided, as follows:
#   - generate the solver from the provided petri net:
source("demo/run_generation.R")
#   - perform the sensitivity analysis:
source("demo/run_sensitivity.R")
#   - calibrate the model using a deterministic solver:
source("demo/run_calibration.R")
#   - calibrate the model using a stochastic solver:
source("demo/run_calibration_s.R")
#   - perform a what-if analysis:
source("demo/run_analysis.R")
