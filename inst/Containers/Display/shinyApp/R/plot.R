#' @title Plot model simulation results
#' @description
#'   Visualizes the results of simulations.
#'   Depending on the contents of the specified directory, the function automatically
#'   recognizes whether the results refer to an analysis, calibration, or sensitivity
#'   experiment, and produces the corresponding plots.
#'   Through its input parameters, the user can configure the visualization by
#'   enabling or disabling the display of uncertainty areas and individual traces,
#'   by selecting between combined or separated plots, and by optionally providing
#'   a reference data file.
#'
#' @param directory Folder path of model simulation.
#' @param plot_mode Type of visualization to generate:
#'  \itemize{
#'    \item combined: plots all places on a single figure;
#'    \item separate: plots one panel per place
#'  } Default is combined.
#' @param reference_file Optional path to a CSV file containing reference data to
#' be plotted alongside simulation results. If NULL, the function searches for a
#' file named reference_data.csv within the provided directory.
#' @param plot_traces If TRUE, individual simulation traces are drawn. Default is TRUE.
#' @param plot_area If TRUE, areas representing the minimum and maximum value ranges
#' are displayed. Default is TRUE.
#' @param plot_places Optional character vector specifying a subset of model places
#' to include in the plot. If NULL, all places are shown.
#'
#' @param line_width_reference Numeric value specifying the line width used for
#' reference data traces (applicable in calibration and sensitivity experiments).
#' Default is 0.8.
#' @param line_width_mean Numeric value specifying the line width used for mean
#' traces (applicable in analysis experiments). Default is 0.8.
#' @param line_width_traces Numeric value specifying the line width for individual
#' simulation traces. Default is 0.5.
#' @param alpha_traces Numeric value (between 0 and 1) controlling the transparency
#' of individual traces. Default is 0.5.
#' @param alpha_ribbon Numeric value (between 0 and 1) controlling the transparency
#' of uncertainty ribbons (areas between minimum and maximum values). Default is 0.2.
#' @param dist_low Color used for the lowest distance (or rank) in calibration or
#' sensitivity experiments. Default is "#132B43".
#' @param dist_high Color used for the highest distance (or rank) in calibration or
#' sensitivity experiments. Default is "#56B1F7".
#'
#' @param plot_params Optional character vector specifying a subset of parameters
#' for the scatter plot in case of Sensitivity. Default NULL.
#' @param dist_low_scatter Color used for the lowest distance (or rank) in the scatter plot.
#' Default is "#132B43".
#' @param dist_high_scatter Color used for the highest distance (or rank) in the scatter plot.
#' Default is "#56B1F7".
#'
#' @return A list containing:
#' \describe{
#'   \item{plot_main}{The main ggplot object showing simulation results.}
#'   \item{plot_scatter}{A ggplot object for a scatter plot of selected parameters
#'   (only for sensitivity experiments), or NULL if not applicable.}
#'   \item{varying_params}{A character vector of parameter names that vary in the
#'   simulation, or NULL if not applicable.}
#' }
#'
#' @export

library(dplyr)
library(ggplot2)
library(tidyr)
library(grid)
library(ggnewscale)

epimod.plot <- function(
  directory, plot_mode = "combined", reference_file = NULL, plot_traces = TRUE,
  plot_area = TRUE, plot_places = NULL,
  line_width_reference = 0.8,
  line_width_mean = 0.8,
  line_width_traces = 0.5,
  alpha_traces = 0.5,
  alpha_ribbon = 0.2,
  dist_low = "#132B43",
  dist_high = "#56B1F7",
  plot_params = NULL,
  dist_low_scatter = "#132B43",
  dist_high_scatter = "#56B1F7"
) {
  check_directory(directory)

  tmp <- detect_experiment_type(directory)
  type <- tmp$type
  trace_files <- tmp$trace_files
  message("Detected experiment type: ", type)

  if (type == "Sensitivity") {
    # Folder traces
    params <- get_params(directory)
    if (!"folder_trace" %in% names(params)) {
      stop("folder_trace not found.")
    }
    folder_trace <- params[["folder_trace"]]
    folder_trace <- file.path(dirname(directory), folder_trace)

    # Search trace files
    trace_files <- list.files(folder_trace, pattern = ".trace", full.names = TRUE)

    df <- get_df(trace_files[1])
    time_col <- get_time_col(df)
    check_filter_places(df, plot_places, time_col)

    # Ranking file
    rank <- get_rank(directory)

    # Read trace files and assignment of ID and rank
    id.traces <- as.numeric(gsub(".*-([0-9]+)\\.trace$", "\\1", basename(trace_files)))
    traces <- lapply(seq_along(trace_files), function(i) {
      trace.tmp <- read.csv(trace_files[i], sep = "")
      data.frame(
        trace.tmp,
        ID = id.traces[i],
        rank = rank[which(rank[, 2] == basename(trace_files[i])), 1]
      )
    })
    traces <- do.call("rbind", traces)

    # Normalization
    traces$rank <- (traces$rank - min(traces$rank, na.rm = TRUE)) /
      (max(traces$rank, na.rm = TRUE) - min(traces$rank, na.rm = TRUE))

    # Places identification
    places <- setdiff(names(traces), c("ID", "rank", time_col))

    ref.long <- read_reference(reference_file, df, directory, places)

    # Traces long format
    traces.long <- traces %>%
      pivot_longer(
        cols = all_of(places),
        names_to = "Place",
        values_to = "Value"
      )

    if (!is.null(plot_places)) {
      traces.long <- filter_places(traces.long, plot_places)
      ref.long <- filter_places(ref.long, plot_places)
    }

    ribbon_data <- compute_ribbon(traces.long)

    traces.long <- order_factor(traces.long, places)
    ribbon_data <- order_factor(ribbon_data, places)
    ref.long <- order_factor(ref.long, places)

    # Plot
    plSeparate <- ggplot() +
      {
        if (plot_area) geom_ribbon(data = ribbon_data, aes(x = Time, ymin = min_Value, ymax = max_Value, fill = Place), alpha = alpha_ribbon, show.legend = FALSE)
      } +
      {
        if (plot_traces) geom_line(data = traces.long, aes(x = Time, y = Value, group = interaction(ID, Place), color = rank), linewidth = line_width_traces, alpha = alpha_traces)
      } +
      scale_color_gradient(low = dist_low, high = dist_high, name = "Distance", guide = guide_colorbar(order = 2)) +
      ggnewscale::new_scale_color() +
      geom_line(data = ref.long, aes(x = Time, y = RefValue, col = Place), linewidth = line_width_reference) +
      labs(color = "Reference Places") +
      guides(color = guide_legend(order = 1)) +
      facet_wrap(~Place, scales = "free_y") +
      labs(x = "Time", y = "Number of tokens") +
      theme_light()
    plCombined <- ggplot() +
      {
        if (plot_area) geom_ribbon(data = ribbon_data, aes(x = Time, ymin = min_Value, ymax = max_Value, fill = Place), alpha = alpha_ribbon, show.legend = FALSE)
      } +
      {
        if (plot_traces) geom_line(data = traces.long, aes(x = Time, y = Value, group = interaction(ID, Place), color = rank), linewidth = line_width_traces, alpha = alpha_traces)
      } +
      scale_color_gradient(low = dist_low, high = dist_high, name = "Distance", guide = guide_colorbar(order = 2)) +
      ggnewscale::new_scale_color() +
      geom_line(data = ref.long, aes(x = Time, y = RefValue, color = Place), linewidth = line_width_reference) +
      labs(color = "Reference Places") +
      guides(color = guide_legend(order = 1)) +
      labs(x = "Time", y = "Number of tokens") +
      theme_light()

    # Scatter plot
    tmp <- setting_scatter(params, rank, places)
    df_params <- tmp$df_params
    varying_params <- tmp$varying_params

    if (is.null(plot_params)) {
      if (length(varying_params) == 0) {
        stop("No varying parameters found in params.")
      } else if (length(varying_params) == 1) {
        x_param <- varying_params[1]
        y_param <- varying_params[1]
      } else {
        x_param <- varying_params[1]
        y_param <- varying_params[2]
      }
    } else {
      x_param <- plot_params$x
      y_param <- plot_params$y
    }

    plPoints <- ggplot(df_params, aes_string(x = x_param, y = y_param, color = "rank_scaled")) +
      geom_point(size = 3, alpha = 0.8) +
      scale_color_gradient(low = dist_low_scatter, high = dist_high_scatter, name = "Distance") +
      theme_light() +
      labs(
        x = x_param,
        y = y_param
      )
  }

  if (type == "Analysis") {
    df <- get_df(trace_files[1])
    time_col <- get_time_col(df)
    check_filter_places(df, plot_places, time_col)

    # n_run identification
    n_run_tot <- table(df[[time_col]])
    n_run <- n_run_tot[1]

    # Delete time_col values not present in every simulation
    time_delete <- as.numeric(names(n_run_tot[n_run_tot != n_run_tot[1]]))
    if (length(time_delete) != 0) df <- df[which(df[[time_col]] != time_delete), ]

    # ID for each simulation
    df$ID <- rep(1:n_run[1], each = length(unique(df[[time_col]])))

    # Check for params/ranking to enable Sensitivity-like features
    params <- tryCatch(get_params(directory), error = function(e) NULL)
    rank <- tryCatch(get_rank(directory), error = function(e) NULL)

    # Traces long format
    traces.long <- lapply(
      colnames(df)[-which(colnames(df) %in% c("ID", time_col))],
      function(c) {
        data.frame(V = df[, c], ID = df$ID, Time = df[[time_col]], Place = c)
      }
    )
    traces.long <- do.call("rbind", traces.long)

    # Add rank mapping if available
    if (!is.null(rank)) {
      traces.long$rank <- rank$measure[match(traces.long$ID, rank$numeric_id)]
      # Normalization
      traces.long$rank <- (traces.long$rank - min(traces.long$rank, na.rm = TRUE)) /
        (max(traces.long$rank, na.rm = TRUE) - min(traces.long$rank, na.rm = TRUE))
    }

    places <- setdiff(names(df), c("ID", time_col))
    traces.long <- order_factor(traces.long, places)

    if (!is.null(plot_places)) {
      traces.long <- filter_places(traces.long, plot_places)
    }

    # Mean
    mean_trace <- traces.long %>%
      group_by(Time, Place) %>%
      summarise(V = mean(V, na.rm = TRUE), .groups = "drop")

    if (n_run > 1) {
      ribbon_data <- traces.long %>%
        group_by(Time, Place) %>%
        summarise(
          mean_V = mean(V, na.rm = TRUE),
          min_V = min(V, na.rm = TRUE),
          max_V = max(V, na.rm = TRUE),
          .groups = "drop"
        )
      ribbon_data <- order_factor(ribbon_data, places)
      linetype <- "dashed"
      alpha <- 0.5
    } else {
      linetype <- "solid"
      alpha <- 0
    }

    # Plot
    plSeparate <- ggplot() +
      {
        if (n_run > 1 && plot_area) geom_ribbon(data = ribbon_data, aes(x = Time, ymin = min_V, ymax = max_V, fill = Place), alpha = alpha_ribbon, show.legend = FALSE)
      } +
      {
        if (plot_traces) {
          if (!is.null(rank)) {
            geom_line(data = traces.long, aes(x = .data[[time_col]], y = V, group = ID, color = rank), linewidth = line_width_traces, alpha = alpha_traces)
          } else {
            geom_line(data = traces.long, aes(x = .data[[time_col]], y = V, group = ID), linewidth = line_width_traces, alpha = alpha_traces, color = "grey")
          }
        }
      } +
      {
        if (!is.null(rank)) scale_color_gradient(low = dist_low, high = dist_high, name = "Distance", guide = guide_colorbar(order = 2))
      } +
      {
        if (!is.null(rank)) ggnewscale::new_scale_color()
      } +
      geom_line(data = mean_trace, aes(x = Time, y = V, col = Place), linewidth = line_width_mean, linetype = linetype) +
      facet_wrap(~Place, scales = "free_y") +
      labs(x = "Time", y = "Number of tokens", color = "Places") +
      theme_light()

    plCombined <- ggplot() +
      {
        if (n_run > 1 && plot_area) geom_ribbon(data = ribbon_data, aes(x = Time, ymin = min_V, ymax = max_V, fill = Place), alpha = alpha_ribbon, show.legend = FALSE)
      } +
      {
        if (plot_traces) {
          if (!is.null(rank)) {
            geom_line(data = traces.long, aes(x = .data[[time_col]], y = V, group = interaction(ID, Place), color = rank), linewidth = line_width_traces, alpha = alpha_traces)
          } else {
            geom_line(data = traces.long, aes(x = .data[[time_col]], y = V, group = interaction(ID, Place)), linewidth = line_width_traces, alpha = alpha_traces, color = "grey")
          }
        }
      } +
      {
        if (!is.null(rank)) scale_color_gradient(low = dist_low, high = dist_high, name = "Distance", guide = guide_colorbar(order = 2))
      } +
      {
        if (!is.null(rank)) ggnewscale::new_scale_color()
      } +
      geom_line(data = mean_trace, aes(x = Time, y = V, col = Place), linewidth = line_width_mean, linetype = linetype) +
      labs(x = "Time", y = "Number of tokens", color = "Places") +
      theme_light()

    # Scatter plot if params are found
    if (!is.null(params)) {
      tmp_scatter <- tryCatch(setting_scatter(params, rank, places), error = function(e) NULL)
      if (!is.null(tmp_scatter)) {
        df_params <- tmp_scatter$df_params
        varying_params <- tmp_scatter$varying_params

        if (length(varying_params) > 0) {
          x_param <- varying_params[1]
          y_param <- varying_params[2] %||% varying_params[1]

          plPoints <- ggplot(df_params, aes_string(x = x_param, y = y_param, color = "rank_scaled")) +
            geom_point(size = 3, alpha = 0.8) +
            scale_color_gradient(low = dist_low_scatter, high = dist_high_scatter, name = "Distance") +
            theme_light() +
            labs(x = x_param, y = y_param)
        }
      }
    }
  } else if (type == "Calibration") { # CALIBRATION

    # Optim config file
    optim_config_file <- list.files(directory, pattern = "calibration_optim-config\\.csv$", full.names = TRUE)
    if (length(optim_config_file) == 0) stop("File '-calibration_optim-config.csv' not found.")
    calibration_optim_trace <- read.csv(optim_config_file, sep = "")

    # Read trace files and assignment of ID
    id.traces <- calibration_optim_trace$id
    traces <- lapply(id.traces, function(x) {
      trace_file <- trace_files[grepl(paste0("-", x, "\\.trace$"), trace_files)]
      if (length(trace_file) == 0) stop(paste("Trace file per ID", x, "not found."))
      trace.tmp <- read.csv(trace_file, sep = "")
      trace.tmp$ID <- calibration_optim_trace$distance[calibration_optim_trace$id == x]
      trace.tmp
    })
    traces <- do.call("rbind", traces)

    df <- get_df(trace_files[1])
    time_col <- get_time_col(df)
    check_filter_places(df, plot_places, time_col)

    # Places identification
    places <- setdiff(names(traces), c(time_col, "ID"))

    ref.long <- read_reference(reference_file, df, directory, places)

    # Traces long format
    traces.long <- traces %>%
      pivot_longer(
        cols = all_of(places),
        names_to = "Place",
        values_to = "Value"
      )

    if (!is.null(plot_places)) {
      traces.long <- filter_places(traces.long, plot_places)
      ref.long <- filter_places(ref.long, plot_places)
    }

    ribbon_data <- compute_ribbon(traces.long)

    traces.long <- order_factor(traces.long, places)
    ribbon_data <- order_factor(ribbon_data, places)
    ref.long <- order_factor(ref.long, places)

    # Plot
    plSeparate <- ggplot() +
      {
        if (plot_area) geom_ribbon(data = ribbon_data, aes(x = Time, ymin = min_Value, ymax = max_Value, fill = Place), alpha = alpha_ribbon, show.legend = FALSE)
      } +
      {
        if (plot_traces) geom_line(data = traces.long, aes(x = Time, y = Value, group = ID, color = as.numeric(ID)), linewidth = line_width_traces, alpha = alpha_traces)
      } +
      scale_color_gradient(low = dist_low, high = dist_high, name = "Distance", guide = guide_colorbar(order = 2)) +
      ggnewscale::new_scale_color() +
      geom_line(data = ref.long, aes(x = Time, y = RefValue, group = Place, col = Place), linewidth = line_width_reference) +
      labs(color = "Reference Places") +
      guides(color = guide_legend(order = 1)) +
      facet_wrap(~Place, scales = "free_y") +
      labs(x = "Time", y = "Number of tokens") +
      theme_light()

    plCombined <- ggplot() +
      {
        if (plot_area) geom_ribbon(data = ribbon_data, aes(x = Time, ymin = min_Value, ymax = max_Value, fill = Place), alpha = alpha_ribbon, show.legend = FALSE)
      } +
      {
        if (plot_traces) geom_line(data = traces.long, aes(x = Time, y = Value, group = interaction(ID, Place), color = as.numeric(ID)), linewidth = line_width_traces, alpha = alpha_traces)
      } +
      scale_color_gradient(low = dist_low, high = dist_high, name = "Distance", guide = guide_colorbar(order = 2)) +
      ggnewscale::new_scale_color() +
      geom_line(data = ref.long, aes(x = Time, y = RefValue, group = Place, color = Place), linewidth = line_width_reference) +
      labs(color = "Reference Places") +
      guides(color = guide_legend(order = 1)) +
      labs(x = "Time", y = "Number of tokens") +
      theme_light()
  }

  if (exists("plPoints")) {
    return(list(
      plot_main = if (plot_mode == "combined") plCombined else plSeparate,
      plot_scatter = plPoints,
      varying_params = varying_params
    ))
  } else {
    return(list(
      plot_main = if (plot_mode == "combined") plCombined else plSeparate,
      plot_scatter = NULL,
      varying_params = NULL
    ))
  }
}

# Detect experiment type
detect_experiment_type <- function(directory) {
  trace_files <- list.files(directory, pattern = "\\.trace$", full.names = TRUE)

  if (length(trace_files) == 0) {
    params <- tryCatch(get_params(directory), error = function(e) NULL)
    if (is.null(params)) {
      return(list(type = "Unknown", trace_files = NULL))
    }
    rank <- get_rank(directory)
    places <- get_places(directory)
    tmp <- setting_scatter(params, rank, places)
    return(list(type = "Sensitivity", trace_files = NULL, varying_params = tmp$varying_params))
  }else{
    # Check if calibration_optim-config.csv exists
    optim_config_file <- list.files(directory, pattern = "calibration_optim-config\\.csv$", full.names = TRUE)
    if (length(optim_config_file) > 0) {
      return(list(type = "Calibration", trace_files = trace_files))
    }else {
      params <- tryCatch(get_params(directory), error = function(e) NULL)
      varying_params <- NULL
      if (!is.null(params)) {
        places <- tryCatch(get_places(directory), error = function(e) character(0))
        tmp_setting <- tryCatch(setting_scatter(params, NULL, places), error = function(e) NULL)
        varying_params <- if (!is.null(tmp_setting)) tmp_setting$varying_params else NULL
      }
      return(list(type = "Analysis", trace_files = trace_files, varying_params = varying_params))
    }
  }
}

# Read file trace
get_df <- function(trace_file) {
  df <- read.table(trace_file, header = TRUE, sep = "", quote = "\"", stringsAsFactors = FALSE)
  return(df)
}

# Get time column
get_time_col <- function(df) {
  tc <- names(df)[grepl("^time$", names(df), ignore.case = TRUE)]
  if (length(tc) == 0) stop("Time column not found.")
  return(tc)
}

# Check filter places
check_filter_places <- function(df_template, plot_places, time_col) {
  if (is.null(plot_places)) {
    return(invisible(TRUE))
  }
  available_places <- setdiff(names(df_template), time_col)
  not_found <- setdiff(plot_places, available_places)
  if (length(not_found) > 0) stop("Places not found: ", paste(not_found, collapse = ", "))
}

# Filter places
filter_places <- function(long, plot_places) {
  long <- long %>% filter(Place %in% plot_places)
  return(long)
}

# Read/validate reference file and return long ref
read_reference <- function(reference_file, template_df, directory, places) {
  if (is.null(reference_file)) {
    reference_file <- list.files(directory, pattern = "reference_data.csv$", full.names = TRUE)
    if (length(reference_file) == 0) stop("File 'reference_data.csv' not found.")
  }
  reference <- read.table(reference_file, header = FALSE, sep = "", stringsAsFactors = FALSE)
  # Check reference file
  if (ncol(template_df) == ncol(reference)) {
    # message("Reference file has same structure as traces.")
  } else if (ncol(reference) == ncol(template_df) - 1) {
    # message("Reference file appears to have no header (missing 'Time'). Assuming same structure as traces.")
    colnames(reference) <- names(template_df)[-1]
    reference <- cbind(Time = seq_len(nrow(reference)) - 1, reference)
  } else {
    stop(
      paste0(
        "Reference file structure does not match traces. - ",
        "Trace columns: ", paste(ncol(template_df)), " - ",
        "Reference columns: ", paste(ncol(reference))
      )
    )
  }
  ref.long <- reference %>%
    pivot_longer(cols = -V1, names_to = "RefPlace", values_to = "RefValue") %>%
    rename(Time = V1)
  ref.long$Place <- places[
    match(ref.long$RefPlace, paste0("V", seq_along(places) + 1))
  ]
  ref.long$Time <- as.numeric(as.character(ref.long$Time))
  ref.long$RefValue <- as.numeric(as.character(ref.long$RefValue))
  ref.long$Place <- factor(ref.long$Place, levels = places)
  return(ref.long)
}

# Ribbon data
compute_ribbon <- function(traces_long) {
  ribbon_data <- traces_long %>%
    group_by(Time, Place) %>%
    summarise(
      mean_Value = mean(Value, na.rm = TRUE),
      min_Value = min(Value, na.rm = TRUE),
      max_Value = max(Value, na.rm = TRUE),
      .groups = "drop"
    )
  return(ribbon_data)
}

# Order factor column
order_factor <- function(data, places) {
  data$Place <- factor(data$Place, levels = places)
  return(data)
}

# Check the directory
check_directory <- function(directory) {
  if (!dir.exists(directory)) {
    stop("The directory doesn't exist.")
  }
}

# Get params from directory
get_params <- function(directory) {
  params_file <- list.files(directory, pattern = "params", full.names = TRUE)
  params <- readRDS(params_file)
  return(params)
}

# Get places from directory
get_places <- function(directory) {
  trace_files <- list.files(directory, pattern = "\\.trace$", full.names = TRUE)
  if (length(trace_files) == 0) {
    params <- get_params(directory)
    if (!"folder_trace" %in% names(params)) {
      stop("folder_trace no found.")
    }
    folder_trace <- params[["folder_trace"]]
    folder_trace <- file.path(dirname(directory), folder_trace)
    # Search trace files
    trace_files <- list.files(folder_trace, pattern = ".trace", full.names = TRUE)
    if (length(trace_files) == 0) {
      stop("folder_trace no found.")
    }
  }
  df <- tryCatch(
    read.table(trace_files[1], header = TRUE, nrows = 1),
    error = function(e) NULL
  )
  if (is.null(df)) {
    return(character(0))
  }
  time_col <- get_time_col(df)
  places <- setdiff(names(df), time_col)
  return(places)
}

get_rank <- function(directory) {
  ranking_file <- list.files(directory, pattern = "ranking", full.names = TRUE)
  if (length(ranking_file) > 0) {
    load(ranking_file)
    rank$numeric_id <- as.numeric(gsub(".*-([0-9]+)\\.trace$", "\\1", rank[, 2]))
  } else { # no ranking
    rank <- data.frame(measure = 0, id = id.traces)
  }
  return(rank)
}

setting_scatter <- function(params, rank = NULL, places) {
  if (!"config" %in% names(params)) {
    stop("'config' element not found.")
  }
  configs <- params$config
  rows <- lapply(seq_len(length(configs[[1]])), function(j) {
    row_list <- list()
    for (i in seq_along(configs)) {
      p <- configs[[i]][[j]]
      pname <- as.character(p[[1]])
      pval <- p[[3]]
      if (length(pval) > 1) {
        if (length(p) >= 2 && as.character(p[[2]]) == "i") {
          if (length(places) != length(pval)) {
            stop("places must have the same length as the parameter vector")
          }
          for (k in seq_along(pval)) {
            coln <- places[k]
            row_list[[coln]] <- as.numeric(pval[[k]])
          }
        } else {
          for (k in seq_along(pval)) {
            coln <- paste0(pname, k)
            row_list[[coln]] <- as.numeric(pval[[k]])
          }
        }
      } else {
        row_list[[pname]] <- as.numeric(pval)
      }
    }
    row_list[["ID"]] <- j
    row_list
  })
  all_names <- unique(unlist(lapply(rows, names)))
  df_list <- lapply(rows, function(r) {
    vals <- setNames(vector("numeric", length(all_names)), all_names)
    vals[] <- NA_real_
    for (nm in names(r)) vals[[nm]] <- as.numeric(r[[nm]])
    as.data.frame(as.list(vals), stringsAsFactors = FALSE)
  })
  df_params <- do.call(rbind, df_list)
  df_params$ID <- as.integer(df_params$ID)

  if (!is.null(rank)) {
    df_params$rank <- rank$measure[match(df_params$ID, rank$numeric_id)]
    df_params$rank_scaled <- (df_params$rank - min(df_params$rank, na.rm = TRUE)) /
      (max(df_params$rank, na.rm = TRUE) - min(df_params$rank, na.rm = TRUE))
  }
  varying_params <- df_params %>%
    dplyr::select(-ID, -dplyr::any_of("rank")) %>%
    summarise(across(everything(), ~ n_distinct(.))) %>%
    tidyr::pivot_longer(everything(), names_to = "param", values_to = "n_unique") %>%
    dplyr::filter(n_unique > 1) %>%
    dplyr::pull(param)
  return(list(df_params = df_params, varying_params = varying_params))
}
