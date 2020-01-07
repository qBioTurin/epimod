#' @title Generates a set of simulation's configurations
#' @description This is an internal function generating a set of configurations. The generation process is driven by the functions listed in param_list. Such functions either are native R functions or user defined ones. In the latter case, the functions have to be defined in a single file and passed through the argument parm_fname
#' @param n_config, number of configuratons to generate
#' @param parm_fname, file with the definition of user defined functions
#' @param parm_list, file listing the name of the functions, the parameters and the name under which the parameters have to be saved
#' @param out_dir, output directory specified by the user
#' @author Marco Beccuti, Paolo Castagno, Simone Pernice
#'
#' @examples
#'\dontrun{
#' experiment.env_cleanup(id=1, run_dir="/run/directory", out_fname="simulation", out_dir="/out/directory",)
#' }
#' @export
experiment.configurations <- function(n_config,
                                      parm_fname = NULL, parm_list,
                                      out_dir,out_fname,
                                      extend = "", optim_vector = NULL){
    if(!is.null(parm_fname))
    {
        source(parm_fname)
    }
    # Read file
    if(is.null(parm_list))
    {
        stop("No file with parameters configuration provided! Abort!")
    }
    conn <- file(parm_list,open="r")
    lines <-readLines(conn)
    close(conn)
    # Initialize an empty list of configurations
    config <- list()
    # TBD: Add the feature to expand an existing configuration
    # cat(extend)
    # For each line the file defines how to generate a (set of) parameter(s)
    for (i in 1:length(lines)){
        # Create an environment to evaluate the parameters read from file
        env <-new.env()
        args<-unlist(strsplit(lines[i], ";"))
        # The first element of each line is a tag controlling how/where to save each (set of) parameter(s)
        tag <- gsub(" ", "", args[1])
        # The second element of each line is the name of the file to store the values
        file <- gsub(" ", "", args[2])
        # The third element of each line is the function name
        f <- gsub(" ", "", args[3])
        # Further arguments, other the first three, are the parameters used by the user defined function
        args<-args[-c(1:3)]
        args <- lapply(c(1:length(args)),function(x){
            eval(parse(text=args[x]), envir = env)
            })
        for(j in c(1:n_config)){
            if(!is.null(optim_vector)){
                env$x <- optim_vector
            }
            data <- do.call(f,as.list.environment(env))
            if(j==1)
                config[[i]] <- list()
            if(tag == "i"){
                config[[i]][[j]] <- list("init", n_config, data)
            }
            else if(tag == "g")
            {
                config[[i]][[j]] <- list(file, n_config, data)
            }
            else if(tag == "p")
            {
                # When launching the simulation you find a negative value in the second field, write it to a string instead of writing it in a file
                config[[i]][[j]] <- list(file, -n_config, data)
            }
        }
    }
    save(config, file = paste0(out_dir, out_fname,".RData"))
    return(config)
}
