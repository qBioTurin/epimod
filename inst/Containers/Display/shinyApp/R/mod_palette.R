# R/mod_palette.R

mod_palette_server <- function(input, output, session, inputs) {
  ns <- session$ns
  
  main_current <- reactiveValues(
    color_scheme = "viridis",
    manual_colors = "#FF0000,#00FF00,#0000FF",
    alpha_traces = 0.5,
    line_width_traces = 0.5,
    alpha_ribbon = 0.2,
    line_width_reference = 0.8,
    line_width_mean = 0.8,
    dist_low = "#132B43",
    dist_high = "#56B1F7",
    plot_mode = "combined",
    trace = TRUE,
    area = TRUE,
    place_selector = character(0)
  )
  
  scatter_current <- reactiveValues(
    dist_low_scatter = "#132B43",
    dist_high_scatter = "#56B1F7"
  )

  prcc_current <- reactiveValues(
    color_scheme_prcc = "brewer",
    manual_colors_prcc = "#FF0000,#00FF00,#0000FF",
    rect_fill = "#FFFF00",
    rect_alpha = 0.6
  )
  
  sobol_current <- reactiveValues(
    color_scheme_sobol = "viridis",
    manual_colors_sobol = "#FF0000,#00FF00,#0000FF",
    time_sobol = ""
  )
  
  palette_trigger <- reactiveVal(0)
  palette_trigger_prcc <- reactiveVal(0)
  palette_trigger_sobol <- reactiveVal(0)
  
  current_palette <- reactive({
    palette_trigger()
    scheme <- input$color_scheme_live %||% input$color_scheme %||% main_current$color_scheme
    manual <- if (identical(scheme, "manual")) input$manual_colors_live %||% input$manual_colors %||% main_current$manual_colors else NULL
    get_palette(scheme, manual, n = 5)
  })
  
  current_palette_prcc <- reactive({
    palette_trigger_prcc()
    scheme <- input$color_scheme_live_prcc %||% input$color_scheme_prcc %||% prcc_current$color_scheme_prcc
    manual <- if (identical(scheme, "manual_prcc")) input$color_scheme_live_prcc %||% input$manual_colors_prcc %||% prcc_current$manual_colors_prcc else NULL
    get_palette(gsub("_prcc$", "", scheme), manual, n = 5)
  })
  
  current_palette_sobol <- reactive({
    palette_trigger_sobol()
    scheme <- input$color_scheme_live_sobol %||% input$color_scheme_sobol %||% sobol_current$color_scheme_sobol
    manual <- if (identical(scheme, "manual_sobol")) input$color_scheme_live_sobol %||% input$manual_colors_sobol %||% sobol_current$manual_colors_sobol else NULL
    get_palette(gsub("_sobol$", "", scheme), manual, n = 5)
  })
  
  output$palette_preview <- renderUI({
    cols <- current_palette()
    if (is.null(input$color_scheme) || input$color_scheme == "manual") return(NULL)
    palette_preview_ui(cols)
  })
  
  output$palette_preview_prcc <- renderUI({
    cols <- current_palette_prcc()
    if (is.null(input$color_scheme_prcc) || input$color_scheme_prcc == "manual_prcc") return(NULL)
    palette_preview_ui(cols)
  })
  
  output$palette_preview_sobol <- renderUI({
    cols <- current_palette_sobol()
    if (is.null(input$color_scheme_sobol) || input$color_scheme_sobol == "manual_sobol") return(NULL)
    palette_preview_ui(cols)
  })
  
  observeEvent(input$color_scheme_live, {
    palette_trigger(isolate(palette_trigger()) + 1)
  })
  observeEvent(input$manual_colors_live, {
    palette_trigger(isolate(palette_trigger()) + 1)
  })
  observeEvent(input$color_scheme_live_prcc, {
    palette_trigger_prcc(isolate(palette_trigger_prcc()) + 1)
  })
  observeEvent(input$manual_colors_live_prcc, {
    palette_trigger_prcc(isolate(palette_trigger_prcc()) + 1)
  })
  observeEvent(input$color_scheme_live_sobol, {
    palette_trigger_sobol(isolate(palette_trigger_sobol()) + 1)
  })
  observeEvent(input$manual_colors_live_sobol, {
    palette_trigger_sobol(isolate(palette_trigger_sobol()) + 1)
  })

  observe({
    req(inputs$places())
    choices_base <- c(
      "Viridis" = "viridis",
      "Brewer - Set1" = "brewer",
      "ggsci - NPG" = "ggsci_npg",
      "Wes Anderson" = "wesanderson",
      "MetBrewer - Hokusai1" = "metbrewer",
      "Scico - lajolla" = "scico"
    )
    if (!is.null(inputs$places()) && length(inputs$places()) > 0) {
      choices_base <- c(choices_base, "Manual (custom)" = "manual")
    }
    updateSelectInput(
      session,
      "color_scheme",
      choices = choices_base,
      selected = isolate(input$color_scheme %||% "viridis")
    )
  })

  output$manual_color_inputs <- renderUI({
    req(input$color_scheme == "manual")
    req(inputs$places())
    pl_all <- inputs$places()
    pl_sel <- inputs$selected_places()
    pl <- if (length(pl_sel) > 0) pl_sel else pl_all
    current_colors_raw <- isolate(main_current$manual_colors)
    if (is.null(current_colors_raw) || !is.character(current_colors_raw)) {
      current_colors_raw <- "#CCCCCC"
    }
    cols <- strsplit(current_colors_raw, ",")[[1]] |> trimws()
    if (length(cols) < length(pl_all)) {
      cols <- c(cols, rep("#CCCCCC", length(pl_all) - length(cols)))
    }
    color_map <- setNames(cols[seq_along(pl_all)], pl_all)
    div(
      style = "display:flex; flex-wrap:wrap; align-items:center; gap:10px; row-gap:8px;",
      lapply(pl, function(place) {
        div(
          style = "display:flex; align-items:center; gap:6px; min-width:140px;",
          tags$span(
            place,
            style = "text-align:right; white-space:nowrap; font-size:16px; flex-shrink:0;"
          ),
          colourInput(
            inputId = ns(paste0("manual_color_", place)),
            label = NULL,
            value = color_map[[place]] %||% "#CCCCCC",
            allowTransparent = TRUE,
            showColour = "both",
            width = "90px"
          )
        )
      })
    )
  })
  
  output$manual_color_inputs_prcc <- renderUI({
    req(input$color_scheme_prcc == "manual_prcc")
    req(inputs$params())
    params_all <- inputs$params()
    params_sel <- inputs$selected_params()
    params <- if (length(params_sel) > 0) params_sel else params_all
    current_colors_raw_prcc <- isolate(prcc_current$manual_colors_prcc)
    if (is.null(current_colors_raw_prcc) || !is.character(current_colors_raw_prcc)) {
      current_colors_raw_prcc <- "#CCCCCC"
    }
    cols_prcc <- strsplit(current_colors_raw_prcc, ",")[[1]] |> trimws()
    if (length(cols_prcc) < length(params_all)) {
      cols_prcc <- c(cols_prcc, rep("#CCCCCC", length(params_all) - length(cols_prcc)))
    }
    color_map_prcc <- setNames(cols_prcc[seq_along(params_all)], params_all)
    div(
      style = "display:flex; flex-wrap:wrap; align-items:center; gap:10px; row-gap:8px;",
      lapply(params, function(param) {
        div(
          style = "display:flex; align-items:center; gap:6px; min-width:140px;",
          tags$span(
            param,
            style = "text-align:right; white-space:nowrap; font-size:16px; flex-shrink:0;"
          ),
          colourInput(
            inputId = paste0("manual_color_prcc_", param),
            label = NULL,
            value = color_map_prcc[[param]] %||% "#CCCCCC",
            allowTransparent = TRUE,
            showColour = "both",
            width = "90px"
          )
        )
      })
    )
  })
  
  output$manual_color_inputs_sobol <- renderUI({
    req(input$color_scheme_sobol == "manual_sobol")
    
    #req(inputs$params())
    params_all <- inputs$params()
    
    time_vec <- if (nzchar(input$time_sobol)) {
      as.numeric(strsplit(input$time_sobol, ",")[[1]])
    } else {
      seq(7, 35, by = 7)  # default
    }
    
    
    params_sel <- inputs$selected_params()
    params <- if (length(params_sel) > 0) params_sel else params_all
    current_colors_raw_sobol <- isolate(sobol_current$manual_colors_sobol)
    if (is.null(current_colors_raw_sobol) || !is.character(current_colors_raw_sobol)) {
      current_colors_raw_sobol <- "#CCCCCC"
    }
    cols_sobol <- strsplit(current_colors_raw_sobol, ",")[[1]] |> trimws()
    
    #if (length(cols_sobol) < length(params_all)) {
      #cols_sobol <- c(cols_sobol, rep("#CCCCCC", length(params_all) - length(cols_sobol)))
    #}
    #color_map_sobol <- setNames(cols_sobol[seq_along(params_all)], params_all)
    
    if (length(cols_sobol) < length(time_vec)) {
      cols_sobol <- c(cols_sobol, rep("#CCCCCC", length(time_vec) - length(cols_sobol)))
    }
    color_map_sobol <- setNames(cols_sobol[seq_along(time_vec)], time_vec)
    
    div(
      style = "display:flex; flex-wrap:wrap; align-items:center; gap:10px; row-gap:8px;",
      
      #lapply(params, function(param) {
      lapply(time_vec, function(t) {
        
        div(
          style = "display:flex; align-items:center; gap:6px; min-width:140px;",
          tags$span(
            t,
            style = "text-align:right; white-space:nowrap; font-size:16px; flex-shrink:0;"
          ),
          colourInput(
            inputId = paste0("manual_color_sobol_", t),
            label = NULL,
            value = color_map_sobol[[as.character(t)]] %||% "#CCCCCC",
            allowTransparent = TRUE,
            showColour = "both",
            width = "90px"
          )
        )
      })
    )
  })
  
  
  list(
    main_current = main_current,
    scatter_current = scatter_current,
    prcc_current = prcc_current,
    sobol_current = sobol_current,
    current_palette = current_palette,
    current_palette_prcc = current_palette_prcc,
    current_palette_sobol = current_palette_sobol,
    palette_trigger = palette_trigger,
    palette_trigger_prcc = palette_trigger_prcc,
    palette_trigger_sobol = palette_trigger_sobol
  )
}
