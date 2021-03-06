% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/model_calibration.R
\name{model_calibration}
\alias{model_calibration}
\title{Run model calibration}
\usage{
model_calibration(solver_fname, f_time, s_time, solver_type = "LSODA",
  n_run = 1, parameters_fname = NULL, functions_fname = NULL,
  volume = getwd(), timeout = "1d", parallel_processors = 1, ini_v,
  lb_v, ub_v, ini_vector_mod = FALSE, threshold.stop = NULL,
  max.call = 1e+07, max.time = NULL, reference_data = NULL,
  distance_measure_fname = NULL, extend = NULL, seed = NULL,
  out_fname)
}
\arguments{
\item{solver_fname}{.solver file (generated in with the function model_generation)}

\item{f_time}{Final solution time.}

\item{s_time}{Time step at whicch explicit estimates for the system are desired}

\item{solver_type}{\itemize{ \item Deterministic: ODE-E, ODE-RKF, ODE45, LSODA,
\item Stochastic:  SSA or TAUG,
\item Hybrid: HLSODA or (H)SDE or HODE
} Default is LSODA.}

\item{n_run}{.....}

\item{functions_fname}{File with the user defined functions to generate istances of the parameters}

\item{volume}{The folder to mount within the Doker image providing all the necessary files}

\item{timeout}{....}

\item{parallel_processors}{Integer for the parallel....}

\item{ini_v}{Initial values for the parameters to be optimized.}

\item{lb_v, ub_v}{Vectors with length equal to the number of paramenters which are varying. Lower/Upper bounds for esch paramenter.}

\item{ini_vector_mod}{Logical value for ... . Default is FALSE.}

\item{threshold.stop, max.call, max.time}{These are GenSA arguments, which can be used to control the behavior of the algorithm. (see \code{\link{GenSA}})
\itemize{
\item threshold.stop (Numeric) respresents the threshold for which the program will stop when the expected objective function value will reach it. Default value is NULL.
\item maxit (Integer) represents the maximum number of call of the objective function. Default is 1e7.
\item max.time (Numeric) is the maximum running time in seconds. Default value is NULL.}}

\item{reference_data}{Data to compare with the simulations' results}

\item{distance_measure_fname}{File containing the definition of a distance measure to rank the simulations'. Such function takes 2 arguments: the reference data and a list of data_frames containing simulations' output. It has to return a data.frame with the id of the simulation and its corresponding distance from the reference data.}

\item{extend}{...}

\item{seed}{Value that can be set to initialize the internal random generator.}

\item{out_fname}{Prefix to the output file name}
}
\description{
this functon takes as input a solver and all the required parameters to set up a dockerized running environment to perform model calibration. both for deterministic and stochastic models
In order to run the simulations, the user must provide a reference dataset and the definition of a function to compute the distance (or error) between the models' output and the reference dataset itself.
The function defining the distance has to be in the following form:

FUNCTION_NAME(reference_dataset, simulation_output)

Moreover, the function must return a column vector with one entry for each evaluation point (i.e. f_time/s_time entries)
in addiction to that, the user is asked to provide a function that, given the output of the solver, returns the releveant measure (one column) used to evalaute the quality of the solution.

The sensitivity analysis will be performed through a Monte Carlo sampling throug user defined functions.
the parameters involved in the sensitivity analysis have to be listed in a cvs file using the following structure:

OUTPUT_FILE_NAME, FUNCTION_NAME, LIST OF PARAMETERS (comma separated)

The functions allowed to compute the parameters are either R functions or user defined functions. In the latter case, all the user defined functions must be provided in a single .R file (which will be passed to run_sensitivity through the parameter parameters_fname)

Exploiting the same mechanism, user can provide an initial marking to the solver. However, if it is the case the corresponding file name in the parameter list must be set to "init"

To drive the optimization, the user has to provide a function to generate a new configuration, starting from a vector of n elements (each one ranging from 0 to 1).
Furthermore, the vector init_v defines the initial point of the search.

IMPORTANT: the length of the vector init_v defines the number of variables to variate within the search of the optimal configuration.
}
\examples{
\dontrun{
local_dir <- "/some/path/to/the/directory/hosting/the/input/files/"
base_dir <- "/root/scratch/"
library(epimod)
model_calibration(out_fname = "calibration",
                  parameters_fname = paste0(local_dir, "Configuration/Functions_list.csv"),
                  functions_fname = paste0(local_dir, "Configuration/Functions.R"),
                  solver_fname = paste0(local_dir, "Configuration/Solver.solver"),
                  init_fname = "init",
                  f_time = 365*21,
                  s_time = 365,
                  volume = volume = "/some/path/to/the/local/output/directory",
                  timeout = "1d",
                  parallel_processors=4,
                  reference_data = paste0(local_dir, "Configuration/reference_data.csv"),
                  distance_measure_fname = paste0(local_dir, "Configuration/Measures.R"),
                  target_value_fname = paste0(local_dir, "Configuration/Select.R"),
                  target_value_f = "infects",
                  ini_v = c(0.48264229, 0.17799173, 0.43572218, 0.06540719, 0.49887063, 0.36793130, 0.01818745, 0.18572619, 0.42815506, 0.07962422, 0.35074813, 0.35074813, 0.36386227),
                  ub_v = c(1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1),
                  lb_v = c(0, 0, 1e-7, 1e-7, 1e-7, 1e-7, 1e-7, 1e-7, 1e-7, 1e-7, 1e-7, 1e-7, 1e-7),
                  nb.stop.improvement = 3000000)
}
}
\author{
Beccuti Marco, Castagno Paolo, Pernice Simone
}
