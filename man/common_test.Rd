% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/common_test.R
\name{common_test}
\alias{common_test}
\title{Test correctness of the parameters before execute a function}
\usage{
common_test(
  folder_trace,
  net_fname,
  functions_fname = NULL,
  reference_data = NULL,
  target_value = NULL,
  ini_v,
  lb_v,
  ub_v,
  solver_fname,
  i_time,
  f_time,
  s_time,
  parameters_fname = NULL,
  volume = getwd(),
  parallel_processors = 1,
  solver_type = "LSODA",
  n_run = 1,
  distance_measure = NULL,
  n_config = 1,
  out_fname = NULL,
  timeout = "1d",
  extend = FALSE,
  seed = NULL,
  ini_vector_mod = FALSE,
  threshold.stop = NULL,
  max.call = 1e+07,
  max.time = NULL,
  taueps = 0.01,
  user_files = NULL,
  event_times = NULL,
  event_function = NULL,
  fba_fname = NULL,
  FVA = F,
  flux_fname = NULL,
  fva_gamma,
  caller_function
)
}
\arguments{
\item{folder_trace}{Folder in which are stored the traces file that are considered to calculate the PRCC analysis.}

\item{net_fname}{.PNPRO file storing the Petri Net (and all its generalizations) model. In case there are multiple nets defined within the PNPRO file, the first one in the list is the will be automatically selected.}

\item{functions_fname}{R file storing the user defined functions to generate instances of the parameters summarized in the parameters_fname file.}

\item{reference_data}{csv file storing the data to be compared with the simulations’ result.}

\item{target_value}{String reporting the target function, implemented in *functions_fname*, to obtain the place or a combination of places from which the PRCCs over the time have to be calculated. In details, the function takes in input a data.frame, namely output, defined by a number of columns equal to the number of places plus one corresponding to the time, and number of rows equals to number of time steps defined previously. Finally, it must return the column (or a combination of columns) corresponding to the place (or combination of places) for which the PRCCs have to be calculated for each time step.}

\item{ini_v}{Initial values for the parameters to be optimized.}

\item{lb_v, ub_v}{Vectors with length equal to the number of parameters which are varying. Lower/Upper bounds for each parameter.}

\item{solver_fname}{.solver file (generated in with the function model_generation).}

\item{i_time}{Initial solution time.}

\item{f_time}{Final solution time.}

\item{s_time}{Time step defining the frequency at which explicit estimates for the system values are desired.}

\item{parameters_fname}{Textual file in which the parameters to be studied are listed associated with their range of variability. This file is defined by three mandatory columns: (1) a tag representing the parameter type: i for the complete initial marking (or condition), p for a single parameter (either a single rate or initial marking), and g for a rate associated with general transitions (Pernice et al. 2019) (the user must define a file name coherently with the one used in the general transitions file); (2) the name of the transition which is varying (this must correspond to name used in the PN draw in GreatSPN editor), if the complete initial marking is considered (i.e., with tag i) then by default the name init is used; (3) the function used for sampling the value of the variable considered, it could be either a R function or an user-defined function (in this case it has to be implemented into the R script passed through the functions_fname input parameter). Let us note that the output of this function must have size equal to the length of the varying parameter, that is 1 when tags p or g are used, and the size of the marking (number of places) when i is used. The remaining columns represent the input parameters needed by the functions defined in the third column.}

\item{volume}{The folder to mount within the Docker image providing all the necessary files.}

\item{parallel_processors}{Integer for the number of available processors to use for parallelizing the simulations.}

\item{solver_type}{\itemize{
  \item Deterministic: three explicit methods which can be efficiently used  for systems without stiffness: Runge-Kutta 5th order integration, Dormand-Prince method, and Kutta-Merson method (ODE-E, ODE-RKF, ODE45). Instead for systems with stiffness we provided a Backward Differentiation Formula (LSODA);
  \item Stochastic: the Gillespie algorithm,which is an exact stochastic method widely used to simulate chemical systems whose behaviour can be described by the Master equations (SSA); or an approximation method of the SSA called tau-leaping method (TAUG), which provides a good compromise between the solution execution time  and its quality.
  \item Hybrid: Stochastic  Hybrid  Simulation, based on the co-simulation of discrete and continuous events (HLSODA).
} Default is LSODA.}

\item{n_run}{Integer for the number of stochastic simulations to run. If n_run is greater than 1 when the deterministic process is analyzed (solver_type is *Deterministic*), then n_run identical simulation are generated.}

\item{distance_measure}{String reporting the distance function, implemented in *functions_fname*, to exploit for ranking the simulations. Such function takes 2 arguments: the reference data and a list of data_frames containing simulations' output. It has to return a data.frame with the id of the simulation and its corresponding distance from the reference data.}

\item{n_config}{Number of configurations to generate, to use only if some parameters are generated from a stochastic distribution, which has to be encoded in the functions defined in *functions_fname* or in *parameters_fname*.}

\item{out_fname}{Prefix to the output file name}

\item{timeout}{Maximum execution time allowed to each configuration.}

\item{extend}{If TRUE the actual configuration is extended including n_config new configurations.}

\item{seed}{.RData file that can be used to initialize the internal random generator.}

\item{ini_vector_mod}{Logical value for ... . Default is FALSE.}

\item{threshold.stop, max.call, max.time}{These are GenSA arguments, which can be used to control the behavior of the algorithm. (see \code{\link{GenSA}})
\itemize{
  \item threshold.stop (Numeric) represents the threshold for which the program will stop when the expected objective function value will reach it. Default value is NULL.
  \item max.call (Integer) represents the maximum number of call of the objective function. Default is 1e7.
  \item max.time (Numeric) is the maximum running time in seconds. Default value is NULL.
} These arguments not always work, actually.}

\item{taueps}{The error control parameter from the tau-leaping approach.}

\item{user_files}{Vector of user files to copy inside the docker directory}

\item{event_times}{Vector representing the time points at which the simulation has to stop in order to
simulate a discrete event that modifies the marking of the net given a specific rule defined in *functions_fname*.}

\item{event_function}{String reporting the function, implemented in *functions_fname*, to exploit for modifying the total marking at a specific time point.
Such function takes in input: 1) a vector representing the marking of the net (called *marking*), and 2) the time point at which the simulation has stopped (called *time*).
In particular, *time* takes values from *event_times*.}

\item{FVA}{Flag to enable the flux variability analysis}

\item{flux_fname}{vector of fluxes id to compute the FVA}

\item{caller_function}{a string defining which function will be executed with the specified parameters (generation, sensitivity, calibration, analysis)}
}
\description{
Check if the passed parameters are well defined to execute the specified function, verifying
  the existence of the resource path, the length of the array, the value of solver type etc.
}
\author{
Paolo Castagno, Daniele Baccega, Luca Rosso
}
