# R/utils_plot.R

`%||%` <- function(a, b) {
  if (!is.null(a)) a else b
}

safe_run <- function(fun, ...) {
  log_conn <- textConnection("logText", "w", local = TRUE)
  sink(log_conn, type = "output")
  sink(log_conn, type = "message")
  on.exit(
    {
      sink(type = "output")
      sink(type = "message")
      close(log_conn)
    },
    add = TRUE
  )
  res <- tryCatch(
    {
      fun(...)
    },
    error = function(e) e
  )
  list(result = res, log = paste(logText, collapse = "\n"))
}

apply_copalette_preview_ui <- function(cols) {
  if (is.null(cols) || length(cols) == 0) {
    return(NULL)
  }
  div(
    style = "display: flex; gap: 4px; padding: 4px; background: rgba(0,0,0,0.03); border-radius: 6px; border: 1px solid rgba(0,0,0,0.05);",
    lapply(cols, function(cl) {
      div(style = paste0(
        "width: 32px; height: 18px; border-radius: 3px;",
        "background-color:", cl, ";",
        "box-shadow: inset 0 0 0 1px rgba(0,0,0,0.1);"
      ))
    })
  )
}

apply_color_scheme <- function(p, scheme, manual_colors = NULL, names_map = NULL,
                               dist_low = NULL, dist_high = NULL,
                               alpha_ribbon = NULL, alpha_traces = NULL,
                               line_width_reference = NULL, line_width_mean = NULL) {
  if (!inherits(p, "ggplot")) {
    return(p)
  }

  n <- if (!is.null(names_map)) length(names_map) else 10

  if (is.null(scheme)) scheme <- "viridis"
  if (scheme == "viridis") {
    p <- p + scale_color_viridis_d(option = "D", end = 0.95) +
      scale_fill_viridis_d(option = "D", end = 0.95)
  } else if (scheme == "brewer") {
    cols <- RColorBrewer::brewer.pal(min(9, n), "Set1")
    cols <- rep(cols, length.out = n)
    p <- p +
      scale_color_manual(values = cols) +
      scale_fill_manual(values = cols)


    # p <- p + scale_color_brewer(palette = "Set1") +
    #  scale_fill_brewer(palette = "Set1")
  } else if (scheme == "ggsci_npg") {
    if (requireNamespace("ggsci", quietly = TRUE)) {
      cols <- ggsci::pal_npg()(n)
      p <- p +
        scale_color_manual(values = cols) +
        scale_fill_manual(values = cols)


      # p <- p + ggsci::scale_color_npg() + ggsci::scale_fill_npg()
    }
  } else if (scheme == "wesanderson") {
    if (requireNamespace("wesanderson", quietly = TRUE)) {
      cols <- wesanderson::wes_palette("Darjeeling1")
      cols <- rep(cols, length.out = n)
      p <- p +
        scale_color_manual(values = cols) +
        scale_fill_manual(values = cols)

      # p <- p + scale_color_manual(values = wesanderson::wes_palette("Darjeeling1")) +
      #  scale_fill_manual(values = wesanderson::wes_palette("Darjeeling1"))
    }
  } else if (scheme == "metbrewer") {
    if (requireNamespace("MetBrewer", quietly = TRUE)) {
      cols <- MetBrewer::met.brewer("Hokusai1")
      cols <- rep(cols, length.out = n)
      p <- p +
        scale_color_manual(values = cols) +
        scale_fill_manual(values = cols)

      # p <- p + scale_color_manual(values = MetBrewer::met.brewer("Hokusai1")) +
      #  scale_fill_manual(values = MetBrewer::met.brewer("Hokusai1"))
    }
  } else if (scheme == "scico") {
    if (requireNamespace("scico", quietly = TRUE)) {
      p <- p + scico::scale_color_scico_d(palette = "lajolla") +
        scico::scale_fill_scico_d(palette = "lajolla")
    }
  } else if (grepl("^manual", scheme)) {
    if (is.null(manual_colors)) {
      manual_cols <- rep("#CCCCCC", length(names_map))
      names(manual_cols) <- names_map
    } else {
      if (is.character(manual_colors) && length(manual_colors) == 1) {
        manual_cols <- strsplit(manual_colors, ",")[[1]] |> trimws()
      } else {
        manual_cols <- manual_colors
      }
      if (!is.null(names_map) && length(manual_cols) < length(names_map)) {
        manual_cols <- c(manual_cols, rep("#CCCCCC", length(names_map) - length(manual_cols)))
      }
      if (!is.null(names_map)) manual_cols <- setNames(manual_cols[seq_along(names_map)], names_map)
    }
    p <- p + scale_color_manual(values = manual_cols, guide = guide_legend(override.aes = list(alpha = 1))) +
      scale_fill_manual(values = manual_cols)
  }
  if (!is.null(dist_low) && !is.null(dist_high)) {
    dist_cols <- c(dist_low, dist_high)
    p <- p + ggnewscale::new_scale_color() +
      scale_color_gradientn(
        colours = scales::gradient_n_pal(dist_cols)(seq(0, 1, length.out = 7)),
        name = "Distance",
        guide = guide_colorbar(order = 2)
      )
  }
  p
}
