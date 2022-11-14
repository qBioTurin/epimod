
# Utility function
chk_dir <- function(path){
	pwd <- basename(path)
	return(paste0(file.path(dirname(path),pwd, fsep = .Platform$file.sep), .Platform$file.sep))
}
# Read commandline arguments
args <- commandArgs(TRUE)
cat(args)
param_fname <- args[1]

# Load parameters
params <- readRDS(param_fname)

# Load seed and previous configuration, if required.

if(is.null(params$seed)){
	# Save initial seed value
	params$seed <- paste0(params$out_dir, "seeds-", params$out_fname, ".RData")

	timestamp <- as.numeric(Sys.time())
	set.seed(kind = "Super-Duper", seed = timestamp)

	init_seed <- runif(min = 1, max = .Machine$integer.max, n = 1)
	extend_seed <- init_seed
	n <- 1

	save(init_seed, extend_seed, n, file = params$seed)
}else{
	load(params$seed)
	if(params$extend){
		# We want to extend a previous experiment
		assign(x = ".Random.seed", value = extend_seed, envir = .GlobalEnv)
		load(paste0(params$out_dir, params$out_fname, ".RData"))
	}
	else{
		n <- 1
	}
}

if(!params$extend){
	set.seed(kind = "Mersenne-Twister", seed = init_seed)
}

# setwd("/home/")
# folder_trace = paste0("/home/",basename(params$folder_trace) )

folder_trace = paste0("/home/docker/data/",basename(params$folder_trace) )
folder_sensitivity = paste0("/home/docker/data/",basename(params$out_dir) )
flux_fname_file = paste0(folder_sensitivity,"/flux_fname")

fls = list.files(folder_trace,pattern = ".flux$")

fva_name = gsub(fls,pattern = ".flux$",replacement = "")
fva_name = gsub(fva_name,pattern = "analysis",replacement = "fva")
fva_name = paste0(fva_name,"-")
names(fva_name) = fls

setwd(folder_sensitivity)

####### ATTENZIONE
## Per piu' problemi di FBA, bisogna leggere il rispettivo file e
## filtrare le colonne in base ai flussi presenti nei fbafile, questo perche'
## VARIABILITY.sh funziona solo su singolo fbafile!!!!

for(fl in fls){
	# the fbafile index +1 since it starts from 0!
	fba_files_index = 1 + as.numeric(gsub(fl,pattern = paste0("(",params$out_fname_analysis,"-[0-9]-)|(.flux)"),replacement = ""))

	flux <- read.csv(file = paste0(folder_trace,"/",fl), sep = "", header = F)
	flID = flux[1,]
	flux_fname =  params$flux_fname[params$flux_fname %in% flID]

	write(flux_fname,
				file = flux_fname_file,
				ncolumns = 1)

	system(
		paste(
			"VARIABILITY.sh",
			params$files$fba_fname[fba_files_index],
			paste0(folder_trace,"/",fl),
			flux_fname_file,
			params$fva_gamma,
			fva_name[fl],sep = " "
		),
		wait = T
	)
}

