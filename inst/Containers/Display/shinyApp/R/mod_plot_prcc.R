# R/mod_plot_prcc.R

mod_plot_prcc_ui <- function() {
  navset_card_pill(
    id = "subtabs_prcc",
    nav_panel(
      title = "PRCC Time Series",
      value = "Plot1",
      card(
        card_header("Partial Rank Correlation Coefficients over Time"),
        uiOutput("plot_error_prcc"),
        plotOutput("plot_prcc", height = "500px")
      )
    ),
    nav_panel(
      title = "PRCC Bar Chart",
      value = "Plot2",
      card(
        card_header("Sensitivity at Specific Time"),
        sliderInput("time_prcc", "Time selection:", value = 0, min = 0, max = 1, step = 1, width = "100%"),
        uiOutput("plot_error_prcc_2"),
        plotOutput("plot_bar", height = "500px")
      )
    ),
    nav_panel(
      title = "Graphic Settings",
      value = "GraphicSettings",
      card(
        card_header("PRCC Visualization Settings"),
        layout_column_wrap(
          width = 1 / 2,
          selectInput(
            "color_scheme_prcc", "Color palette:",
            choices = c(
              "Viridis" = "viridis",
              "Brewer - Set1" = "brewer",
              "ggsci - NPG" = "ggsci_npg",
              "Wes Anderson" = "wesanderson",
              "MetBrewer - Hokusai1" = "metbrewer",
              "Scico - lajolla" = "scico",
              "Manual Colors" = "manual_prcc"
            ),
            selected = "brewer"
          ),
          div(
            class = "palette-preview-container",
            uiOutput("palette_preview_prcc")
          )
        ),
        conditionalPanel(
          condition = "input.color_scheme_prcc == 'manual_prcc'",
          div(
            class = "manual-colors-list",
            uiOutput("manual_color_inputs_prcc"),
            helpText("Select a color for each parameter.")
          )
        ),
        layout_column_wrap(
          width = 1 / 2,
          colourInput("rect_fill", "Confidence Area Color:", value = "#FFFF00"),
          sliderInput("rect_alpha", "Confidence Area Transparency:", min = 0, max = 1, value = 0.6, step = 0.05)
        ),
        hr(),
        mod_settings_ui("settings_graphics_prcc")
      )
    ),
    nav_panel(
      title = "Variables Settings",
      value = "VariablesSettings",
      card(
        card_header("Target Variable Selection"),
        selectInput(
          inputId = "prcc_target_tab",
          label = "Select target variable for PRCC:",
          choices = character(0),
          selected = NULL,
          width = "100%"
        ),
        hr(),
        mod_settings_ui("settings_variables_prcc")
      )
    )
  )
}

mod_plot_prcc_server <- function(input, output, session, inputs, palettes, settings) {
  current_plot_prcc <- inputs$current_plot_prcc
  current_plot_prcc2 <- inputs$current_plot_prcc2
  plot_error_prcc <- inputs$plot_error_prcc
  params <- inputs$params
  places <- inputs$places
  selected_params <- inputs$selected_params

  generate_plot <- function() {
    dir = inputs$dir_path()
    if (!dir.exists(dir)) {
      return()
    }
    res <- safe_run(function(...) {
      if (!exists("sensitivity.prcc", mode = "function")) stop("sensitivity.prcc not found")
      sensitivity.prcc(
        directory = dir,
        target = isolate(palettes$prcc_current$target_tab),
        rect_fill = isolate(palettes$prcc_current$rect_fill),
        rect_alpha = isolate(palettes$prcc_current$rect_alpha),
        time = input$time_prcc %||% 0
      )
    })
    if (!inherits(res$result, "error")) {
      out <- res$result
      current_plot_prcc(out$plot_prcc)
      current_plot_prcc2(out$plot_bar)
      updateSliderInput(session, "time_prcc",
        min = out$time_min,
        max = out$time_max,
        value = input$time_prcc,
        step = 1
      )
      plot_error_prcc(NULL)
    } else {
      current_plot_prcc(NULL)
      current_plot_prcc2(NULL)
      plot_error_prcc(res$result$message)
    }
  }

  apply_prcc <- function() {
    isolate({
      palettes$prcc_current$target_tab <- input$prcc_target_tab
      palettes$prcc_current$color_scheme_prcc <- input$color_scheme_prcc
      if (input$color_scheme_prcc == "manual_prcc") {
        req(params())
        params_all <- params()
        cols_prcc <- sapply(params_all, function(pl) {
          inpid <- paste0("manual_color_prcc_", pl)
          val <- input[[inpid]]
          if (is.null(val) || !nzchar(val)) "#CCCCCC" else val
        })
        palettes$prcc_current$manual_colors_prcc <- paste(cols_prcc, collapse = ",")
      }
      palettes$prcc_current$rect_fill <- input$rect_fill
      palettes$prcc_current$rect_alpha <- input$rect_alpha
    })
    generate_plot()
    updateTabsetPanel(session, "subtabs_prcc", selected = "Plot1")
  }

  observeEvent(settings$graphics$apply(), {
    apply_prcc()
  })
  observeEvent(settings$variables$apply(), {
    apply_prcc()
  })

  observeEvent(settings$graphics$reset(), {
    default_values <- list(
      color_scheme_prcc = "brewer",
      manual_colors_prcc = "#FF0000,#00FF00,#0000FF",
      rect_fill = "#FFFF00",
      rect_alpha = 0.6
    )
    for (nm in names(default_values)) {
      palettes$prcc_current[[nm]] <- default_values[[nm]]
    }
    updateSelectInput(session, "color_scheme_prcc", selected = palettes$prcc_current$color_scheme_prcc)
    updateTextInput(session, "manual_colors_prcc", value = palettes$prcc_current$manual_colors_prcc)
    updateColourInput(session, "rect_fill", value = palettes$prcc_current$rect_fill)
    updateSliderInput(session, "rect_alpha", value = palettes$prcc_current$rect_alpha)
    generate_plot()
    updateTabsetPanel(session, "subtabs_prcc", selected = "Plot1")
  })

  observeEvent(settings$variables$reset(), {
    palettes$prcc_current$target_tab <- isolate(places())[1]
    updateSelectInput(session, "prcc_target_tab", selected = palettes$prcc_current$target_tab)
    generate_plot()
    updateTabsetPanel(session, "subtabs_prcc", selected = "Plot1")
  })

  observeEvent(input$time_prcc, {
    generate_plot()
  })

  observeEvent(input$subtabs_prcc, {
    updateSelectInput(session, "color_scheme_prcc", selected = palettes$prcc_current$color_scheme_prcc)
    updateTextInput(session, "manual_colors_prcc", value = palettes$prcc_current$manual_colors_prcc)
    updateColourInput(session, "rect_fill", value = palettes$prcc_current$rect_fill)
    updateSliderInput(session, "rect_alpha", value = palettes$prcc_current$rect_alpha)
    updateSelectInput(session, "prcc_target_tab", selected = palettes$prcc_current$target_tab %||% isolate(places())[1])
  })

  plot_result <- eventReactive(input$run, {
    generate_plot()
    updateTabsetPanel(session, "subtabs_main", selected = "Plot")
  })

  output$plot_prcc <- renderPlot({
    plot_result()
    req(current_plot_prcc())
    p <- current_plot_prcc()
    validate(need(inherits(p, "ggplot"), "PRCC plot is not available or not a ggplot object"))
    cs <- isolate(palettes$prcc_current$color_scheme_prcc)
    manual_prcc <- isolate(palettes$prcc_current$manual_colors_prcc)
    params_all <- isolate(params())
    p2 <- apply_color_scheme(p, cs,
      manual_colors = manual_prcc, names_map = params_all,
      dist_low = NULL, dist_high = NULL
    )
    p2
  })

  output$plot_bar <- renderPlot({
    plot_result()
    req(current_plot_prcc2())
    p <- current_plot_prcc2()
    validate(need(inherits(p, "ggplot"), "PRCC plot is not available or not a ggplot object"))
    cs <- isolate(palettes$prcc_current$color_scheme_prcc)
    manual_prcc <- isolate(palettes$prcc_current$manual_colors_prcc)
    params_all <- isolate(params())
    p2 <- apply_color_scheme(p, cs,
      manual_colors = manual_prcc, names_map = params_all,
      dist_low = NULL, dist_high = NULL
    )
    p2
  })
}
