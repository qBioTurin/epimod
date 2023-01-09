#' @export
#'
# Function to compute the distance between one simulation trace and the reference data
tool.distance <- function(id,
													out_dir,
													# distance_measure_fname,
													distance_measure,
													reference_data,
													function_fname){
	print("[tool.distance] Begin computing distance")
	pwd <- getwd()
	setwd(out_dir)
	print(paste0("[tool.distance] opening file ", out_dir, id))
	# Read the output and compute the distance from reference data
	trace <- read.csv(id,
										sep = "")
	print(paste0("[tool.distance] Loading reference data ", reference_data))
	# Load reference data (IMPORTANT it has to be a column vector)
	reference <- as.data.frame(t(read.csv(reference_data, header = FALSE, sep = "")))
	# Load distance definition
	# source(distance_measure_fname)
	print("tool.distance] Loading function definitions")
	source(function_fname)
	print("[tool.distance] CallingComputing distance")
	# Compute the user defined distance measure
	measure <- do.call(distance_measure, list(reference, trace))
	setwd(pwd)
	print("[tool.distance] Done computing distance")
	return(data.frame(measure=measure, id=basename(id)) )
}
