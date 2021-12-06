# Function to compute the distance between one simulation trace and the reference data
tool.distance <- function(id,
																 ## run_dir,
																 ## out_fname,
																 out_dir,
																 distance_measure_fname,
																 distance_measure,
																 reference_data){
	pwd <- getwd()
	setwd(out_dir)
	system(paste0("echo \"Trying to open ", id, "\""))
	# Read the output and compute the distance from reference data
	## trace <- read.csv(paste0(out_fname, "-", id, "-1-1.trace"), sep = "")
	trace <- read.csv(id,
										sep = "")
	# Load distance definition
	source(distance_measure_fname)
	# Load reference data (IMPORTANT it has to be a column vector)
	reference <- as.data.frame(t(read.csv(reference_data, header = FALSE, sep = "")))
	# Compute the user defined distance measure
	measure <- do.call(distance_measure, list(reference, trace))
	setwd(pwd)
	return(data.frame(measure=measure, id=id))
}
