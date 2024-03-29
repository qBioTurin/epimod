#' @title Generates a set of simulation's configurations
#' @description This is an internal function generating a set of configurations. The generation process is driven by the functions listed in param_list. Such functions either are native R functions or user defined ones. In the latter case, the functions have to be defined in a single file and passed through the argument parm_fname
#' @param n_config, number of configuratons to generate
#' @param parm_fname, file with the definition of user defined functions
#' @param parm_list, file listing the name of the functions, the parameters and the name under which the parameters have to be saved
#' @param out_dir, output directory specified by the user
#' @param out_fname, prefix used to name output files
#' @param extend, unused parameter. Placeholder for future development
#' @author Marco Beccuti, Paolo Castagno, Simone Pernice
#'
#' @export
#' @examples
#'\dontrun{
#' experiment.configurations(nconfig = 10,
#'                           param_list = list.csv,
#'                           out_dir="/path/to/output/directory",
#'                           out_fname="example")
#' }

experiment.configurations <- function(n_config,
                                      parm_fname = NULL, parm_list = NULL,
                                      out_dir,out_fname,
                                      ini_vector = NULL, ini_vector_mod = FALSE,
																			extend = FALSE, config = list()){

		print("[experiment.configurations] Generating configurations...")
    # if(is.null(parm_fname)) # ini_vector_mod)
    # {
    #     stop("Wrong parameters: impossible to generate a configuration to run!\n Please provide a file with parameter generating functions or allow to use the optimization vector without modification.\n Abort!\n")
    # }
    # Initialize an empty list of configurations
    if(!is.null(parm_fname))
    {
        source(parm_fname)
    }
    # Read file
    if(!is.null(parm_list))
    {
    		print("[experiment.configurations] Reading parameters file")
        conn <- file(parm_list,open="r")
        lines <-readLines(conn)
        close(conn)
        # Remove empty lines and comments
        rmv <- c(which(startsWith(lines,'#')),which(lines == ""))
        if(length(rmv) != 0)
        {
            lines <- lines[-rmv]
        }
        print("[experiment.configurations] Done reading parameters file")
    }
    # For each line the file defines how to generate a (set of) parameter(s)
		config_length <- 0
		if(length(config) != 0)
			config_length <- length(config[[1]])
		print("[experiment.configurations] Parsing parameters...")
    for (i in 1:length(lines)){
    		print(paste0("[experiment.configurations] Parsing parameter ", lines[i]))
        # Create an environment to evaluate the parameters read from file
        env <-new.env()
        is_function <- FALSE
        if(!is.null(parm_list))
        {
            args<-unlist(strsplit(lines[i], ";"))
            # The first element of each line is a tag controlling how/where to save each (set of) parameter(s)
            tag <- gsub(" ", "", args[1])
            # The second element of each line is the name of the file to store the values
            file <- gsub(" ", "", args[2])
            # The third element of each line is the function name
            f <- gsub(" ", "", args[3])
            # Further arguments, other the first three, are the parameters used by the user defined function
            # if(length(args) > 3)
            if(suppressWarnings(is.na(as.numeric(f))))
            {
                args<-args[-c(1:3)]
                args <- lapply(c(1:length(args)),function(x){
                    eval(parse(text=args[x]), envir = env)
                })
                is_function <- TRUE
            }
        }
        #for(j in c(1:n_config)){
        for(j in c((config_length+1):(config_length+n_config))){
            if(j==1)
                config[[i]] <- list()
            if(!is.null(ini_vector) && is_function && "optim_v" %in% formalArgs(f)){
                env$optim_v <- ini_vector
            }
            if(!is.null(parm_list))
            {
                if(is_function)
                {
                    data <- do.call(f,as.list.environment(env))
                }
                else
                {
                    data <- as.numeric(f)
                }
            }
            # Initial marking
            if(exists("tag") && tag == "i"){
                config[[i]][[j]] <- list("init", "i", data)
            }
            # General rate function
            else if(exists("tag") && tag == "g")
            {
                config[[i]][[j]] <- list(file, "g", data)
            }
            # Exponential rate
            else if(exists("tag") && tag == "c")
            {
                config[[i]][[j]] <- list(file, "c", data)
            }
            # Marking for a specific place
            else if(exists("tag") && tag == "m")
            {
            	config[[i]][[j]] <- list(file, "m", data)
            }
            else
            {
                stop("Wrong parameter configuration: please check parameters controlling the generation of experiments' configurations.\n Abort!\n")
            }
        }
    }
		print("[experiment.configurations] Done parsing parameters")
    save(config, file = paste0(out_dir, out_fname,".RData"))
    print("[experiment.configurations] Done generating configurations")
    return(config)
}
