# R/mod_plot_main.R
mod_plot_main_server <- function(input, output, session, inputs, palettes, settings) {
  current_plot_main <- inputs$current_plot_main
  current_plot_scatter <- inputs$current_plot_scatter
  current_plot_scatter2 <- inputs$current_plot_scatter2
  plot_error_main <- inputs$plot_error_main
  plot_error_scatter <- inputs$plot_error_scatter
  current_plot_prcc <- inputs$current_plot_prcc
  current_plot_prcc2 <- inputs$current_plot_prcc2
  plot_error_prcc <- inputs$plot_error_prcc
  reference_file <- inputs$reference_file
  selected_places <- inputs$selected_places
  exp_type <- inputs$exp_type
  varying_params <- inputs$varying_params
  scatter_params_selected <- inputs$scatter_params_selected
  scatter_params_selected2 <- inputs$scatter_params_selected2
  places <- inputs$places
  
  generate_plot <- function() {
    dir = inputs$dir_path()
    validate(need(dir.exists(dir), "Directory not valid."))
    pl_sel <- if (length(palettes$main_current$place_selector) > 0) palettes$main_current$place_selector else NULL
    reference_path <- reference_file()
    if (!exists("epimod.plot", mode = "function")) {
      stop("epimod.plot() not found. Provide the function in your app environment.")
    }
    res <- safe_run(epimod.plot, 
                    directory = dir, 
                    plot_mode = palettes$main_current$plot_mode, 
                    reference_file = reference_path, 
                    plot_traces = palettes$main_current$trace, 
                    plot_area = palettes$main_current$area, 
                    plot_places = pl_sel, 
                    line_width_traces = isolate(palettes$main_current$line_width_traces %||% 0.5), 
                    alpha_traces = isolate(palettes$main_current$alpha_traces %||% 0.5), 
                    alpha_ribbon = isolate(palettes$main_current$alpha_ribbon %||% 0.2), 
                    line_width_reference = isolate(palettes$main_current$line_width_reference %||% 0.8), 
                    line_width_mean = isolate(palettes$main_current$line_width_mean %||% 0.8), 
                    dist_low = isolate(palettes$main_current$dist_low %||% "#132B43"), 
                    dist_high = isolate(palettes$main_current$dist_high %||% "#56B1F7"),
                    plot_params = if (exp_type() == "Sensitivity") list(x = scatter_params_selected$x, y = scatter_params_selected$y) else NULL, 
                    dist_low_scatter = isolate(palettes$scatter_current$dist_low_scatter %||% "#132B43"), 
                    dist_high_scatter = isolate(palettes$scatter_current$dist_high_scatter %||% "#56B1F7")
    ) 
    if (!inherits(res$result, "error")) { 
      out <- res$result 
      current_plot_main(out$plot_main) 
      plot_error_main(NULL) 
    } else { 
      current_plot_main(NULL) 
      plot_error_main(res$result$message) 
    }
  }
  
  plot_result <- eventReactive(input$run, {
    generate_plot()
    updateTabsetPanel(session, "subtabs_main", selected = "Plot")
  })
  
  apply_main <- function() {
    isolate({
      palettes$main_current$color_scheme <- input$color_scheme
      palettes$main_current$alpha_traces <- input$alpha_traces
      palettes$main_current$line_width_traces <- input$line_width_traces
      palettes$main_current$alpha_ribbon <- input$alpha_ribbon
      palettes$main_current$line_width_reference <- input$line_width_reference
      palettes$main_current$line_width_mean <- input$line_width_mean
      palettes$main_current$dist_low <- input$dist_low
      palettes$main_current$dist_high <- input$dist_high
      if (input$color_scheme == "manual") {
        req(inputs$places())
        pl_all <- inputs$places()
        cols <- sapply(pl_all, function(pl) {
          val <- input[[paste0("manual_color_", pl)]] %||% "#CCCCCC"
          val
        })
        palettes$main_current$manual_colors <- paste(cols, collapse = ",")
      }
      palettes$main_current$plot_mode <- input$plot_mode
      palettes$main_current$trace <- input$trace
      palettes$main_current$area <- input$area
      palettes$main_current$place_selector <- input$place_selector
    })
    generate_plot()
    updateTabsetPanel(session, "subtabs_main", selected = "Plot")
  }
  
  observeEvent(settings$graphics$apply(), {
    apply_main()
  })
  observeEvent(settings$variables$apply(), {
    apply_main()
  })

  observeEvent(settings$graphics$reset(), {
    isolate({
      palettes$main_current$color_scheme <- "viridis"
      palettes$main_current$manual_colors <- "#FF0000,#00FF00,#0000FF"
      palettes$main_current$alpha_traces <- 0.5
      palettes$main_current$line_width_traces <- 0.5
      palettes$main_current$alpha_ribbon <- 0.2
      palettes$main_current$line_width_reference <- 0.8
      palettes$main_current$line_width_mean <- 0.8
      palettes$main_current$dist_low <- "#132B43"
      palettes$main_current$dist_high <- "#56B1F7"
    })
    updateSelectInput(session, "color_scheme", selected = palettes$main_current$color_scheme)
    updateTextInput(session, "manual_colors", value = palettes$main_current$manual_colors)
    updateNumericInput(session, "alpha_traces", value = palettes$main_current$alpha_traces)
    updateNumericInput(session, "line_width_traces", value = palettes$main_current$line_width_traces)
    updateNumericInput(session, "alpha_ribbon", value = palettes$main_current$alpha_ribbon)
    updateNumericInput(session, "line_width_reference", value = palettes$main_current$line_width_reference)
    updateNumericInput(session, "line_width_mean", value = palettes$main_current$line_width_mean)
    updateColourInput(session, "dist_low", value = palettes$main_current$dist_low)
    updateColourInput(session, "dist_high", value = palettes$main_current$dist_high)
    generate_plot()
    updateTabsetPanel(session, "subtabs_main", selected = "Plot")
  })
  
  observeEvent(settings$variables$reset(), {
    isolate({
      palettes$main_current$plot_mode <- "combined"
      palettes$main_current$trace <- TRUE
      palettes$main_current$area <- TRUE
      palettes$main_current$place_selector <- character(0)
    })
    updateRadioButtons(session, "plot_mode", selected = palettes$main_current$plot_mode)
    updateCheckboxInput(session, "trace", value = palettes$main_current$trace)
    updateCheckboxInput(session, "area", value = palettes$main_current$area)
    updatePickerInput(
      session,
      "place_selector",
      selected = palettes$main_current$place_selector
    )
    generate_plot()
    updateTabsetPanel(session, "subtabs_main", selected = "Plot")
  })
  
  observeEvent(input$subtabs_main, {
    updateSelectInput(session, "color_scheme", selected = palettes$main_current$color_scheme)
    updateTextInput(session, "manual_colors", value = palettes$main_current$manual_colors)
    updateNumericInput(session, "alpha_traces", value = palettes$main_current$alpha_traces)
    updateNumericInput(session, "line_width_traces", value = palettes$main_current$line_width_traces)
    updateNumericInput(session, "alpha_ribbon", value = palettes$main_current$alpha_ribbon)
    updateNumericInput(session, "line_width_reference", value = palettes$main_current$line_width_reference)
    updateNumericInput(session, "line_width_mean", value = palettes$main_current$line_width_mean)
    updateColourInput(session, "dist_low", value = palettes$main_current$dist_low)
    updateColourInput(session, "dist_high", value = palettes$main_current$dist_high)
    updatePickerInput(session, "place_selector", selected = palettes$main_current$place_selector)
    updateCheckboxInput(session, "trace", value = palettes$main_current$trace)
    updateCheckboxInput(session, "area", value = palettes$main_current$area)
    updateRadioButtons(session, "plot_mode", selected = palettes$main_current$plot_mode)
  })
  
  output$plot_main <- renderPlot({
    plot_result()
    req(current_plot_main())
    p <- current_plot_main()
    validate(need(inherits(p, "ggplot"), "Main plot is not available or not a ggplot object"))
    cs <- isolate(palettes$main_current$color_scheme %||% "viridis")
    manual <- isolate(palettes$main_current$manual_colors)
    places_all <- isolate(inputs$places())
    names_map <- places_all
    p2 <- apply_color_scheme(p, cs, manual_colors = manual, names_map = names_map,
                             dist_low = isolate(palettes$main_current$dist_low),
                             dist_high = isolate(palettes$main_current$dist_high),
                             alpha_ribbon = isolate(palettes$main_current$alpha_ribbon),
                             alpha_traces = isolate(palettes$main_current$alpha_traces),
                             line_width_reference = isolate(palettes$main_current$line_width_reference),
                             line_width_mean = isolate(palettes$main_current$line_width_mean)
    )
    p2
  })
  
}
