# R/mod_plot_scatter.R

mod_plot_scatter_ui <- function() {
  navset_card_pill(
    id = "subtabs_scatter",
    nav_panel(
      title = "Parameter Analysis",
      value = "Plot1",
      card(
        card_header("Sensitivity Scatter Plot"),
        layout_column_wrap(
          width = 1 / 2,
          uiOutput("scatter_x_ui"),
          uiOutput("scatter_y_ui")
        ),
        uiOutput("plot_error_scatter"),
        plotOutput("plot_scatter", height = "500px")
      )
    ),
    nav_panel(
      title = "Timepoint Scatter",
      value = "Plot2",
      card(
        card_header("Cross-sectional Analysis"),
        layout_column_wrap(
          width = 1 / 2,
          uiOutput("scatter_x2_ui"),
          uiOutput("scatter_y2_ui")
        ),
        sliderInput("time_scatter", "Time selection:", value = 0, min = 0, max = 1, step = 1, width = "100%"),
        uiOutput("plot_error_scatter_2"),
        plotOutput("plot_scatter2", height = "500px")
      )
    ),
    nav_panel(
      title = "Graphic Settings",
      value = "GraphicSettings",
      card(
        card_header("Scatter Plot Appearance"),
        layout_column_wrap(
          width = 1 / 2,
          colourInput("dist_low_scatter", "Low distance color:", value = "#132B43"),
          colourInput("dist_high_scatter", "High distance color:", value = "#56B1F7")
        ),
        hr(),
        mod_settings_ui("settings_scatter")
      )
    )
  )
}

mod_plot_scatter_server <- function(input, output, session, inputs, palettes, settings) {
  current_plot_main <- inputs$current_plot_main
  current_plot_scatter <- inputs$current_plot_scatter
  current_plot_scatter2 <- inputs$current_plot_scatter2
  scatter_params_selected <- inputs$scatter_params_selected
  scatter_params_selected2 <- inputs$scatter_params_selected2
  varying_params <- inputs$varying_params
  places <- inputs$places
  plot_error_scatter <- inputs$plot_error_scatter
  exp_type <- inputs$exp_type

  generate_plot <- function() {
    dir = inputs$dir_path()
    validate(need(dir.exists(dir), "Directory not valid."))
    req(scatter_params_selected$x, scatter_params_selected$y)
    if (!exists("epimod.plot", mode = "function")) {
      stop("epimod.plot() not found. Provide the function in your app environment.")
    }
    res <- safe_run(epimod.plot,
      directory = dir,
      plot_params = list(x = scatter_params_selected$x, y = scatter_params_selected$y),
      dist_low_scatter = isolate(palettes$scatter_current$dist_low_scatter %||% "#132B43"),
      dist_high_scatter = isolate(palettes$scatter_current$dist_high_scatter %||% "#56B1F7")
    )
    if (!inherits(res$result, "error")) {
      out <- res$result
      if (!is.null(out$plot_scatter)) {
        current_plot_scatter(out$plot_scatter)
      } else {
        current_plot_scatter(NULL)
        plot_error_scatter("epimod.plot did not return plot_scatter")
      }
    } else {
      current_plot_scatter(NULL)
      plot_error_scatter(res$result$message)
      NULL
    }
    req(scatter_params_selected2$x2, scatter_params_selected2$y2)
    if (!exists("scatter", mode = "function")) {
      stop("scatter() not found. Provide the function in your app environment.")
    }
    res2 <- safe_run(scatter,
      directory = dir,
      time = input$time_scatter %||% 0,
      places = list(scatter_params_selected2$x2, scatter_params_selected2$y2)
    )
    if (!inherits(res2$result, "error")) {
      out <- res2$result
      if (!is.null(out)) {
        current_plot_scatter2(out$plot)
        updateSliderInput(session, "time_scatter",
          min = out$time_min,
          max = out$time_max,
          value = input$time_scatter,
          step = 1
        )
      } else {
        current_plot_scatter2(NULL)
        plot_error_scatter("scatter did not return plot_scatter")
      }
    } else {
      current_plot_scatter2(NULL)
      plot_error_scatter(res2$result$message)
      NULL
    }
  }

  observeEvent(settings$apply(), {
    isolate({
      palettes$scatter_current$dist_low_scatter <- input$dist_low_scatter
      palettes$scatter_current$dist_high_scatter <- input$dist_high_scatter
    })
    generate_plot()
    updateTabsetPanel(session, "subtabs_scatter", selected = "Plot1")
  })

  observeEvent(settings$reset(), {
    isolate({
      palettes$scatter_current$dist_low_scatter <- "#132B43"
      palettes$scatter_current$dist_high_scatter <- "#56B1F7"
    })
    updateColourInput(session, "dist_low_scatter", value = palettes$scatter_current$dist_low_scatter)
    updateColourInput(session, "dist_high_scatter", value = palettes$scatter_current$dist_high_scatter)
    generate_plot()
    updateTabsetPanel(session, "subtabs_scatter", selected = "Plot1")
  })

  observeEvent(list(input$scatter_x, input$scatter_y), {
    req(input$scatter_x, input$scatter_y)
    scatter_params_selected$x <- input$scatter_x
    scatter_params_selected$y <- input$scatter_y
    generate_plot()
  })

  observeEvent(list(input$scatter_x2, input$scatter_y2, input$time_scatter), {
    req(input$scatter_x2, input$scatter_y2)
    scatter_params_selected2$x2 <- input$scatter_x2
    scatter_params_selected2$y2 <- input$scatter_y2
    generate_plot()
  })

  observeEvent(input$subtabs_scatter, {
    updateColourInput(session, "dist_low_scatter", value = palettes$scatter_current$dist_low_scatter)
    updateColourInput(session, "dist_high_scatter", value = palettes$scatter_current$dist_high_scatter)
  })

  plot_result <- eventReactive(input$run, {
    generate_plot()
    updateTabsetPanel(session, "subtabs_main", selected = "Plot")
  })

  output$plot_scatter <- renderPlot({
    plot_result()
    req(current_plot_scatter())
    req(varying_params())
    current_plot_scatter()
  })

  output$plot_scatter2 <- renderPlot({
    plot_result()
    req(current_plot_scatter2())
    req(places())
    current_plot_scatter2()
  })

  output$scatter_x_ui <- renderUI({
    req(exp_type() == "Sensitivity")
    req(varying_params())
    selectInput(
      "scatter_x",
      "X-axis parameter:",
      choices = varying_params(),
      selected = scatter_params_selected$x
    )
  })

  output$scatter_y_ui <- renderUI({
    req(exp_type() == "Sensitivity")
    req(varying_params())
    selectInput(
      "scatter_y",
      "Y-axis parameter:",
      choices = varying_params(),
      selected = scatter_params_selected$y
    )
  })

  output$scatter_x2_ui <- renderUI({
    req(exp_type() == "Sensitivity")
    req(places())
    selectInput(
      "scatter_x2",
      "X-axis parameter:",
      choices = places(),
      selected = scatter_params_selected2$x2
    )
  })

  output$scatter_y2_ui <- renderUI({
    req(exp_type() == "Sensitivity")
    req(places())
    selectInput(
      "scatter_y2",
      "Y-axis parameter:",
      choices = places(),
      selected = scatter_params_selected2$y2
    )
  })
}
