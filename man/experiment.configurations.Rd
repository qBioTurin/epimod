% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/experiment.configuration.R
\name{experiment.configurations}
\alias{experiment.configurations}
\title{Generates a set of simulation's configurations}
\usage{
experiment.configurations(
  n_config,
  parm_fname = NULL,
  parm_list = NULL,
  out_dir,
  out_fname,
  ini_vector = NULL,
  ini_vector_mod = FALSE,
  extend = FALSE,
  config = list()
)
}
\arguments{
\item{n_config, }{number of configuratons to generate}

\item{parm_fname, }{file with the definition of user defined functions}

\item{parm_list, }{file listing the name of the functions, the parameters and the name under which the parameters have to be saved}

\item{out_dir, }{output directory specified by the user}

\item{out_fname, }{prefix used to name output files}

\item{extend, }{unused parameter. Placeholder for future development}
}
\description{
This is an internal function generating a set of configurations. The generation process is driven by the functions listed in param_list. Such functions either are native R functions or user defined ones. In the latter case, the functions have to be defined in a single file and passed through the argument parm_fname
}
\examples{
\dontrun{
experiment.configurations(nconfig = 10,
                          param_list = list.csv,
                          out_dir="/path/to/output/directory",
                          out_fname="example")
}
}
\author{
Marco Beccuti, Paolo Castagno, Simone Pernice
}
