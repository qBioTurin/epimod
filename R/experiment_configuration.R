#' @title Generates a set of simulation's configurations
#' @description This is an internal function generating a set of configurations. The generation process is driven by the functions listed in param_list. Such functions either are native R functions or user defined ones. In the latter case, the functions have to be defined in a single file and passed through the argument parm_fname
#' @param n_config, number of configuratons to generate
#' @param parm_fname, file with the definition of user defined functions
#' @param parm_list, file listing the name of the functions, the parameters and the name under which the parameters have to be saved
#' @param out_dir, output directory specified by the user
#' @author Paolo Castagno
#'
#' @examples
#'\dontrun{
#' experiment.env_cleanup(id=1, run_dir="/run/directory", out_fname="simulation", out_dir="/out/directory",)
#' }
#' @export
experiment.configurations <- function(n_config,
                                      parm_fname, parm_list,
                                      out_dir,out_fname,
                                      extend = "", optim_vector = NULL){
    source(parm_fname)
    conn <- file(parm_list,open="r")
    lines <-readLines(conn)
    close(conn)
    config <- list()
    cat(extend)
    for (i in 1:length(lines)){
        env <-new.env()
        args<-unlist(strsplit(lines[i], ","))
        f <- args[2]
        file <- args[1]
        args<-list(args[-c(1,2)])
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
            config[[i]][[j]] <- list(file, n_config, data)
        }
    }
    save(config, file = paste0(out_dir, out_fname,".RData"))
    return(config)
}
