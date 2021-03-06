% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/model_generation.R
\name{model_generation}
\alias{model_generation}
\title{Run model calibration}
\usage{
model_generation(out_fname = NULL, net_fname, functions_fname = NULL,
  volume = getwd())
}
\arguments{
\item{out_fname}{Prefix to the output file name}

\item{net_fname}{.PNPRO file storing  the model as ESPN. In case there are multiple nets defined within the PNPRO file, the first one in the list is the will be automatically selected;}

\item{functions_fname}{C++ file defining the functions managing the behaviour of general transitions.}
}
\description{
this functon takes as input a solver and all the required parameters to set up a dockerized running environment to perform model calibration. both for deterministic and stochastic models
In order to run the simulations, the user must provide a reference dataset and the definition of a function to compute the distance (or error) between the models' output and the reference dataset itself.
The function defining the distance has to be in the following form:

FUNCTION_NAME(reference_dataset, siulation_output)

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
model_generation(out_fname = "Solver",
                 net_fname = paste0(local_dir, "Configuration/Pertussis"),
                 functions_fname = "transitions.cpp")
}
}
\author{
Beccuti Marco, Castagno Paolo, Pernice Simone
}
