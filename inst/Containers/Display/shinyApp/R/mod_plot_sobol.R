# R/mod_plot_sobol.R

mod_plot_sobol_ui <- function() {
  navset_card_pill(
    id = "subtabs_sobol",
    nav_panel(
      title = "Sobol Indices Plot",
      value = "Plot1",
      card(
        card_header("Global Sensitivity Analysis"),
        uiOutput("plot_error_sobol"),
        plotOutput("plot_sobol", height = "500px")
      )
    ),
    nav_panel(
      title = "Graphic Settings",
      value = "GraphicSettings",
      card(
        card_header("Visualization Customization"),
        layout_column_wrap(
          width = 1 / 2,
          selectInput(
            "color_scheme_sobol", "Color palette:",
            choices = c(
              "Viridis" = "viridis",
              "Brewer - Set1" = "brewer",
              "ggsci - NPG" = "ggsci_npg",
              "Wes Anderson" = "wesanderson",
              "MetBrewer - Hokusai1" = "metbrewer",
              "Scico - lajolla" = "scico",
              "Manual Colors" = "manual_sobol"
            ),
            selected = "viridis"
          ),
          div(
            class = "palette-preview-container",
            uiOutput("palette_preview_sobol")
          )
        ),
        conditionalPanel(
          condition = "input.color_scheme_sobol == 'manual_sobol'",
          div(
            class = "manual-colors-list",
            uiOutput("manual_color_inputs_sobol"),
            helpText("Select a color for each time point.")
          )
        ),
        hr(),
        mod_settings_ui("settings_graphics_sobol")
      )
    ),
    nav_panel(
      title = "Variables Settings",
      value = "VariablesSettings",
      card(
        card_header("Parameter & Time Configuration"),
        selectInput(
          inputId = "sobol_target_tab",
          label = "Select target for Sobol indices:",
          choices = character(0),
          selected = NULL,
          width = "100%"
        ),
        textInput(
          inputId = "time_sobol",
          label = "Time vector (comma separated):",
          placeholder = "e.g. 7, 14, 21, 28",
          value = ""
        ),
        hr(),
        mod_settings_ui("settings_variables_sobol")
      )
    )
  )
}

mod_plot_sobol_server <- function(input, output, session, inputs, palettes, settings) {
  current_plot_sobol <- inputs$current_plot_sobol
  plot_error_sobol <- inputs$plot_error_sobol
  params <- inputs$params
  places <- inputs$places
  selected_params <- inputs$selected_params
  
  generate_plot <- function() {
    dir = inputs$dir_path()
    if (!dir.exists(dir)) {
      return()
    }
    res <- safe_run(function(...) {
      if (!exists("sensitivity.sobol_sensobol", mode = "function")) stop("sensitivity.sobol_sensobol not found")
      sensitivity.sobol_sensobol(
        directory = dir,
        target = isolate(palettes$sobol_current$target_tab),
        time = isolate(palettes$sobol_current$time_sobol)
      )
    })
    if (!inherits(res$result, "error")) {
      out <- res$result

      updateTextInput(session, "time_sobol", value = paste(out$time, collapse = ","))

      current_plot_sobol(out$plot_sobol)
      plot_error_sobol(NULL)
    } else {
      current_plot_sobol(NULL)
      plot_error_sobol(res$result$message)
    }
  }

  apply_sobol <- function() {
    isolate({
      palettes$sobol_current$target_tab <- input$sobol_target_tab
      palettes$sobol_current$color_scheme_sobol <- input$color_scheme_sobol
      palettes$sobol_current$time_sobol <- input$time_sobol
      if (input$color_scheme_sobol == "manual_sobol") {
        req(input$time_sobol)
        time_vec <- if (nzchar(input$time_sobol)) {
          as.numeric(strsplit(input$time_sobol, ",")[[1]])
        } else {
          seq(7, 35, by = 7)
        }
        cols_sobol <- sapply(time_vec, function(ti) {
          inpid <- paste0("manual_color_sobol_", ti)
          val <- input[[inpid]]
          if (is.null(val) || !nzchar(val)) "#CCCCCC" else val
        })


        # req(params())
        # params_all <- params()
        # cols_sobol <- sapply(params_all, function(pl) {
        #  inpid <- paste0("manual_color_sobol_", pl)
        #  val <- input[[inpid]]
        #  if (is.null(val) || !nzchar(val)) "#CCCCCC" else val
        # })

        palettes$sobol_current$manual_colors_sobol <- paste(cols_sobol, collapse = ",")
      }
    })
    generate_plot()
    updateTabsetPanel(session, "subtabs_sobol", selected = "Plot1")
  }

  observeEvent(settings$graphics$apply(), {
    apply_sobol()
  })
  observeEvent(settings$variables$apply(), {
    apply_sobol()
  })

  observeEvent(settings$graphics$reset(), {
    default_values <- list(
      color_scheme_sobol = "viridis",
      manual_colors_sobol = "#FF0000,#00FF00,#0000FF"
    )
    for (nm in names(default_values)) {
      palettes$sobol_current[[nm]] <- default_values[[nm]]
    }
    updateSelectInput(session, "color_scheme_sobol", selected = palettes$sobol_current$color_scheme_sobol)
    updateTextInput(session, "manual_colors_sobol", value = palettes$sobol_current$manual_colors_sobol)
    generate_plot()
    updateTabsetPanel(session, "subtabs_sobol", selected = "Plot1")
  })

  observeEvent(settings$variables$reset(), {
    palettes$sobol_current$time_sobol <- ""
    updateTextInput(session, "time_sobol", value = palettes$sobol_current$time_sobol)

    palettes$sobol_current$target_tab <- isolate(places())[1]
    updateSelectInput(session, "sobol_target_tab", selected = palettes$sobol_current$target_tab)
    generate_plot()
    updateTabsetPanel(session, "subtabs_sobol", selected = "Plot1")
  })


  observeEvent(input$subtabs_sobol, {
    updateSelectInput(session, "color_scheme_sobol", selected = palettes$sobol_current$color_scheme_sobol)
    updateTextInput(session, "manual_colors_sobol", value = palettes$sobol_current$manual_colors_sobol)
    updateSelectInput(session, "sobol_target_tab", selected = palettes$sobol_current$target_tab %||% isolate(places())[1])
  })

  plot_result <- eventReactive(input$run, {
    generate_plot()
    updateTabsetPanel(session, "subtabs_main", selected = "Plot")
  })

  output$plot_sobol <- renderPlot({
    plot_result()
    req(current_plot_sobol())
    p <- current_plot_sobol()
    validate(need(inherits(p, "ggplot"), "SOBOL plot is not available or not a ggplot object"))
    cs <- isolate(palettes$sobol_current$color_scheme_sobol)
    manual_sobol <- isolate(palettes$sobol_current$manual_colors_sobol)

    time_vec <- if (nzchar(input$time_sobol)) {
      as.numeric(strsplit(input$time_sobol, ",")[[1]])
    } else {
      seq(7, 35, by = 7)
    }
    p2 <- apply_color_scheme(p, cs,
      manual_colors = manual_sobol, names_map = time_vec,
      dist_low = NULL, dist_high = NULL
    )

    # params_all <- isolate(params())
    # p2 <- apply_color_scheme(p, cs, manual_colors = manual_sobol, names_map = params_all,
    #                         dist_low = NULL, dist_high = NULL)
    p2
  })
}
