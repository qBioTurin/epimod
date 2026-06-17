#' @title Generate a Scatter Plot Between Two Model Outputs at a Given Time
#'
#' @description
#'    Reads trace files from a Sensitivity experiment and extracts the values of two
#'    selected places at a specific time.
#'    The function returns a scatter plot of these values across all traces, together
#'    with the minimum, maximum, and midpoint of the time range observed in the trace files.
#'
#' @param directory Folder path of model simulation.
#' @param time Numeric. The time point at which values should be extracted from
#'   all trace files.
#' @param places Character vector of length 2. The names of the two places to plot
#' on the x and y axes, respectively.
#'
#' @return A named list with the following elements:
#' \describe{
#'   \item{plot}{A scatter plot of the two selected places.}
#'   \item{time_min}{Minimum time value found across all trace files.}
#'   \item{time_max}{Maximum time value found across all trace files.}
#'   \item{time_mid}{Midpoint between time_min and time_max.}
#' }
#'



scatter <- function(directory, time, places) {
  tmp <- detect_experiment_type(directory)
  if (tmp$type == "Sensitivity") {
    params <- get_params(directory)
    if (!"folder_trace" %in% names(params)) {
      stop("folder_trace not found.")
    }
    folder_trace <- params[["folder_trace"]]
    folder_trace <- file.path(dirname(directory), folder_trace)
    trace_files <- list.files(folder_trace, pattern = ".trace", full.names = TRUE)
  }

  place_x <- places[[1]]
  place_y <- places[[2]]
  time_target <- time

  points_list <- list()
  all_times <- c()

  for (i in seq_along(trace_files)) {
    df <- read.table(trace_files[i], header = TRUE)
    all_times <- c(all_times, df$Time)
    row <- df[df$Time == time_target, ]
    if (nrow(row) == 0) next
    points_list[[i]] <- data.frame(
      x = row[[place_x]],
      y = row[[place_y]]
    )
  }

  data <- do.call(rbind, points_list)

  time_min <- min(all_times)
  time_max <- max(all_times)
  time_mid <- round((time_min + time_max) / 2)

  # Plot
  p <- ggplot(data, aes(x = x, y = y)) +
    geom_point() +
    labs(
      x = place_x,
      y = place_y,
      subtitle = paste("Time:", time)
    ) +
    theme_light() +
    theme(plot.subtitle = element_text(hjust = 0.5))

  return(list(
    plot = p,
    time_min = time_min,
    time_max = time_max,
    time_mid = time_mid
  ))
}
