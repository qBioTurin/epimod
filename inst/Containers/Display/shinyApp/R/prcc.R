#' @title Compute and Plot PRCC Results for Sensitivity Analysis
#' @description
#'   Computes the Partial Rank Correlation Coefficient (PRCC) for model simulation
#'   results to quantify the sensitivity of target outputs to input parameters.
#'   The function extracts simulation traces from the specified directory and generates
#'   time-dependent PRCC line plots and bar plots at a specified time point.
#'
#' @param directory Folder path of model simulation.
#' @param target Character string indicating the place for which the PRCC should be
#' computed.
#' @param rect_fill Fill color for the shaded rectangle indicating PRCC near-zero range.
#' Default is "#FFFF00".
#' @param rect_alpha Transparency for the shaded rectangle. Numeric between 0 and 1.
#' Default is 0.6.
#' @param time Numeric value indicating the time point at which to produce the bar plot.
#' Default is 0.
#'
#' @return A list containing:
#' \describe{
#'   \item{plot_prcc}{A ggplot object showing PRCC over time for each parameter.}
#'   \item{param_names}{Character vector of parameter names used in the PRCC computation.}
#'   \item{plot_bar}{A ggplot object showing PRCC values and p.value for each parameter
#'   at the specified time as a bar plot.}
#'   \item{time_min}{Minimum time in the simulation data.}
#'   \item{time_max}{Maximum time in the simulation data.}
#'   \item{time_mid}{Median time in the simulation data.}
#' }
#'


library(dplyr)
library(ggplot2)
library(tidyr)
library(grid)
library(ggnewscale)


sensitivity.prcc <- function(directory,
                             target = NULL,
                             rect_fill = "#FFFF00",
                             rect_alpha = 0.6,
                             time = 0) {
  params <- get_params(directory)
  config <- params$config
  functions_fname_filename <- basename(params$files$functions_fname)
  functions_fname <- file.path(directory, functions_fname_filename)
  places <- get_places(directory)
  if (is.null(target)) {
    targets <- places
    target_value <- targets[1]
  } else {
    target_value <- target
  }
  i_time <- params$i_time
  s_time <- params$s_time
  f_time <- params$f_time
  out_fname <- params$out_fname
  out_dir <- params$out_dir

  folder_trace <- params$folder_trace
  folder_trace <- normalizePath(file.path(dirname(directory), params$folder_trace))

  out_fname_analysis <- params$out_fname_analysis
  parallel_processors <- params$parallel_processors

  tmp <- setting_scatter(params = params, places = places)

  flatten <- function(x, name) {
    ret <- data.frame()
    x <- data.frame(x)
    if (nrow(x) > 1 & ncol(x) == 1) {
      x <- t(x)
    }
    if (nrow(x) > 1) {
      x <- as.data.frame(x)
      names(x) <- paste0(name, "-<I>-", c(1:ncol(x)))
      x <- x[vapply(x, function(k) length(unique(k)) > 1, logical(1L))]
      nms <- names(x)
      for (i in c(1:nrow(x)))
      {
        r <- as.data.frame(x[i, ])
        names(r) <- nms
        names(r) <- gsub(
          x = names(r),
          pattern = "<I>",
          replacement = i
        )
        if (i == 1) {
          ret <- r
        } else {
          ret <- cbind(ret, r)
        }
      }
    } else {
      ret <- as.data.frame(x)
      if (ncol(x) > 1) {
        # names(ret) <- paste0(name,"-", c(1:ncol(x)))
        names(ret) <- tmp$varying_params
      } else {
        names(ret) <- name
      }
    }
    return(ret)
  }

  if (!is.null(functions_fname)) {
    source(functions_fname)
  }

  targetExtr <- function(id, functions_fname, target_value, folder_trace, out_fname_analysis) {
    trace <- read.csv(
      file = file.path(folder_trace, paste0(out_fname_analysis, "-", id, ".trace")),
      sep = "", header = TRUE, stringsAsFactors = FALSE
    )
    tgt <- lapply(target_value, function(t) {
      if (!t %in% colnames(trace)) {
        stop(paste0("Target ", t, " not found."))
      }

      data.frame(
        Time = trace$Time,
        Target = trace[[t]],
        Type = t
      )
    })

    tgt <- do.call(rbind, tgt)
    colnames(tgt) <- c("Time", paste0("Target", id), "Type")
    return(tgt)
  }

  compute_prcc <- function(time, config, data) {
    config.table <- table(gsub(x = names(config), pattern = "(-[0-9]+-){1}", replacement = "-"))
    config.names <- names(config.table)
    config.names[config.table > 1] <- gsub(
      pattern = "-",
      replacement = paste0("-", time, "-"),
      x = config.names[config.table > 1]
    )
    config <- config[, which(names(config) %in% config.names)]
    dt <- t(data[which(data$Time == time), ][-1])
    dat <- data.frame(config = rownames(dt), Output = c(dt))
    dat <- merge(config, dat) %>% select(-config)

    prcc <- epiR::epi.prcc(dat)
    p.value <- data.frame(p.value = prcc$p.value, Param = head(colnames(dat), -1))
    prcc <- data.frame(prcc = prcc$est, Param = head(colnames(dat), -1))
    prcc <- merge(prcc, p.value)
    prcc$Time <- time
    return(prcc)
  }

  folder_sensitivity <- directory
  n_var <- length(config)
  traces <- list.files(
    path = folder_trace,
    pattern = ".trace$"
  )
  n_config <- length(traces)
  traces.id <- as.numeric(gsub(
    pattern = paste0("(", out_fname_analysis, "-)|(.trace)"),
    replacement = "", x = traces
  ))
  config <- lapply(c(1:n_var), function(x, config) {
    inner_config <- lapply(c(1:n_config), function(k, cfg) {
      return(flatten(cfg[[k]][[3]], name = cfg[[k]][[1]]))
    },
    cfg = config[[x]]
    )
    return(do.call("rbind", inner_config))
  }, config = config)
  parms <- NULL
  for (i in c(1:length(config)))
  {
    if (dim(unique(config[[i]]))[1] > 1) {
      if (is.null(parms)) {
        parms <- config[[i]]
      } else {
        parms <- cbind(parms, config[[i]])
      }
    }
  }
  if (is.null(parms)) {
    stop("No parameters configurations are found, the parameters should change.")
  }
  pos <- sapply(1:length(parms[1, ]), function(k) {
    if (length(unique(parms[, k])) == 1) {
      return(FALSE)
    } else {
      return(TRUE)
    }
  })
  pnames <- names(parms)[pos]
  parms <- as.data.frame(parms[, pos])
  pnames.unique <- unique(gsub(x = pnames, pattern = "(-[0-9]+-){1}", replacement = "-"))
  names(parms) <- pnames
  parms$config <- paste0("Target", 1:n_config)
  tval <- lapply(traces.id,
    targetExtr,
    functions_fname = functions_fname,
    target_value = target_value,
    out_fname_analysis = out_fname_analysis,
    folder_trace = folder_trace
  )

  tvalMerged <- Reduce(function(x, y) merge(x, y, by = c("Time", "Type")), tval)

  time_min <- min(tvalMerged$Time, na.rm = TRUE)
  time_max <- max(tvalMerged$Time, na.rm = TRUE)
  time_mid <- median(tvalMerged$Time, na.rm = TRUE)
  PRCC.info <- lapply(target_value, function(tv, parms, tvalMerged) {
    tvalMerged_sub <- tvalMerged %>%
      filter(Type == tv) %>%
      select(-Type)
    PRCC.info <- lapply(
      X = tvalMerged_sub$Time,
      FUN = function(X, config, data) {
        tryCatch(
          expr = compute_prcc(time = X, config = config, data = data),
          error = function(e) {
            return(
              data.frame(
                Param = pnames.unique,
                prcc = rep(NA, length(pnames.unique)),
                p.value = rep(NA, length(pnames.unique)),
                Time = rep(X, length(pnames.unique))
              )
            )
          }
        )
      },
      config = parms,
      data = tvalMerged_sub
    )
    prcc <- do.call("rbind", PRCC.info)
    prcc$Type <- tv
    return(prcc)
  },
  parms = parms,
  tvalMerged = tvalMerged
  )
  PRCC <- do.call("rbind", PRCC.info)

  print(PRCC)

  plot_prcc <- ggplot(PRCC) +
    annotate("rect",
      xmin = -Inf, xmax = Inf, ymin = -0.2, ymax = 0.2,
      alpha = rect_alpha, fill = rect_fill
    ) +
    geom_line(aes(x = Time, y = prcc, group = Param, col = Param)) +
    ylim(-1, 1) +
    xlab("Time") +
    ylab("PRCC") +
    facet_wrap(~Type, ncol = 1) +
    theme_light() +
    labs(col = "Params")

  PRCC_bar <- PRCC %>%
    filter(Time == time)
  plot_bar <- ggplot(PRCC_bar, aes(x = Param, y = prcc, fill = Param)) +
    geom_col() +
    geom_text(aes(label = paste0("p.value=", signif(p.value, 3))),
      vjust = -0.5, size = 4
    ) +
    ylim(min(PRCC_bar$prcc, -1), max(PRCC_bar$prcc, 1)) +
    labs(
      x = NULL,
      y = "PRCC",
      subtitle = paste("Time:", time)
    ) +
    facet_wrap(~Type, ncol = 1) +
    theme_light() +
    theme(legend.position = "none", plot.subtitle = element_text(hjust = 0.5))

  return(list(
    plot_prcc = plot_prcc,
    param_names = pnames.unique,
    plot_bar = plot_bar,
    time_min = time_min,
    time_max = time_max,
    time_mid = time_mid
  ))
}
