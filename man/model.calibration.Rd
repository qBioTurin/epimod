% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/model.calibration.R
\name{model.calibration}
\alias{model.calibration}
\title{Run model calibration}
\usage{
model.calibration(
  solver_fname,
  i_time = 0,
  f_time,
  s_time,
  atol = 1e-06,
  rtol = 1e-06,
  solver_type = "LSODA",
  taueps = 0.01,
  n_run = 1,
  parameters_fname = NULL,
  functions_fname = NULL,
  volume = getwd(),
  timeout = "1d",
  parallel_processors = 1,
  ini_v,
  lb_v,
  ub_v,
  ini_vector_mod = FALSE,
  threshold.stop = NULL,
  max.call = 1e+07,
  max.time = NULL,
  reference_data = NULL,
  distance_measure = NULL,
  event_times = NULL,
  event_function = NULL,
  seed = NULL,
  out_fname = NULL,
  user_files = NULL,
  debug = FALSE,
  fba_fname = NULL
)
}
\arguments{
\item{solver_fname}{.solver file (generated in with the function model_generation).}

\item{i_time}{Initial solution time.}

\item{f_time}{Final solution time.}

\item{s_time}{Time step defining the frequency at which explicit estimates for the system values are desired.}

\item{atol}{Absolute error tolerance that determine the error control performed by the LSODA solver.}

\item{rtol}{Relative error tolerance that determine the error control performed by the LSODA solver.}

\item{solver_type}{\itemize{
  \item Deterministic: three explicit methods which can be efficiently used  for systems without stiffness: Runge-Kutta 5th order integration, Dormand-Prince method, and Kutta-Merson method (ODE-E, ODE-RKF, ODE45). Instead for systems with stiffness we provided a Backward Differentiation Formula (LSODA);
  \item Stochastic: the Gillespie algorithm,which is an exact stochastic method widely used to simulate chemical systems whose behaviour can be described by the Master equations (SSA); or an approximation method of the SSA called tau-leaping method (TAUG), which provides a good compromise between the solution execution time  and its quality.
  \item Hybrid: Stochastic  Hybrid  Simulation, based on the co-simulation of discrete and continuous events (HLSODA).
} Default is LSODA.}

\item{taueps}{The error control parameter from the tau-leaping approach.}

\item{n_run}{Integer for the number of stochastic simulations to run. If n_run is greater than 1 when the deterministic process is analyzed (solver_type is *Deterministic*), then n_run identical simulation are generated.}

\item{parameters_fname}{a textual file in which the  parameters to be studied are listed associated with their range of variability.
This file is defined by three mandatory columns (*which must separeted using ;*):
 (1) a tag representing the parameter type: *i* for the complete initial marking (or condition),
  *m* for the initial marking of a specific place, *c* for a single constant rate,
  and *g* for a rate associated with general transitions (Pernice et al. 2019)  (the user must define a file name coherently with the one used in the  general transitions file);
   (2) the name of the transition which is varying (this must correspond to name used in the PN draw in GreatSPN editor), if the complete initial marking is considered
   (i.e., with tag *i*) then by default the name *init*  is used; (3) the function used for sampling the value of the variable considered,
    it could be either a R function or an user-defined function (in this case it has to be implemented into the R script passed through the *functions_fname* input parameter).
     Let us note that the output of this function must have size equal to the length of the varying parameter, that is 1 when tags *m*, *c* or *g* are used,
      and the size of the marking (number of places) when *i* is used.  The remaining columns represent the input parameters needed by the functions defined in the third column.}

\item{functions_fname}{an R file storing: 1) the user defined functions to generate instances of the parameters summarized in the *parameters_fname* file, and
2) the functions to compute: the distance (or error) between the model output and the reference dataset itself (see *reference_data* and *distance_measure*), and
the discrete events which may modify the marking of the net at specific time points (see *event_function*).}

\item{volume}{The folder to mount within the Docker image providing all the necessary files.}

\item{timeout}{Maximum execution time allowed to each configuration.}

\item{parallel_processors}{Integer for the number of available processors to use for parallelizing the simulations.}

\item{ini_v}{Initial values for the parameters to be optimized.}

\item{lb_v, ub_v}{Vectors with length equal to the number of parameters which are varying. Lower/Upper bounds for each parameter.}

\item{threshold.stop, max.call, max.time}{These are GenSA arguments, which can be used to control the behavior of the algorithm. (see \code{\link{GenSA}})
\itemize{
  \item threshold.stop (Numeric) represents the threshold for which the program will stop when the expected objective function value will reach it. Default value is NULL.
  \item max.call (Integer) represents the maximum number of call of the objective function. Default is 1e7.
  \item max.time (Numeric) is the maximum running time in seconds. Default value is NULL.
} These arguments not always work, actually.}

\item{reference_data}{csv file storing the data to be compared with the simulations’ result.}

\item{distance_measure}{String reporting the distance function, implemented in *functions_fname*, to exploit for ranking the simulations.
Such function takes 2 arguments: the reference data and a list of data_frames containing simulations' output.
It has to return a data.frame with the id of the simulation and its corresponding distance from the reference data.}

\item{event_times}{Vector representing the time points at which the simulation has to stop in order to
simulate a discrete event that modifies the marking of the net given a specific rule defined in *functions_fname*.}

\item{event_function}{String reporting the function, implemented in *functions_fname*, to exploit for modifying the total marking at a specific time point.
Such function takes in input: 1) a vector representing the marking of the net (called *marking*), and 2) the time point at which the simulation has stopped (called *time*).
In particular, *time* takes values from *event_times*.}

\item{seed}{.RData file that can be used to initialize the internal random generator.}

\item{out_fname}{Prefix to the output file name}

\item{user_files}{Vector of user files to copy inside the docker directory}

\item{debug}{If TRUE enables logging activity.}

\item{fba_fname}{vector of .txt files encoding different flux balance analysis problems, which as to be included in the general transitions (*transitions_fname*).
It must be the same files vector passed to the function *model_generation* for generating the *solver_fname*. (default is NULL)}

\item{extend}{If TRUE the actual configuration is extended including n_config new configurations.}
}
\description{
This function takes as input a solver and all the required parameters to set up a dockerized running environment to perform model calibration, both for deterministic and stochastic models.
}
\details{
The functions to generate instances of the parameters summarized in the *parameters_fname* file are defined in order
 to return the value (or a linear transformation) of the vector of the unknown parameters generated from the optimization algorithm,
 namely **optim_v**, whose size is equal to number of varying parameters in *parameters_fname*.
 Let us note that the output of these functions must return a value for each input parameter.
 The order of values in **optim_v** is given by the order of the parameters in *parameters_fname*.
}
\author{
Beccuti Marco, Castagno Paolo, Pernice Simone, Baccega Daniele
}
