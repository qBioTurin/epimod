# R/mod_data_inputs.R

mod_data_inputs_server <- function(input, output, session) {
  # Standard container data path — always mounted here by display_data()
  DATA_DIR <- "/srv/shiny-server/display/data"
  marker_file <- file.path(DATA_DIR, ".epimod_mounted")
  volume_is_mounted <- file.exists(marker_file)

  preset_dir <- if (volume_is_mounted) DATA_DIR else ""

  # Roots for shinyFiles — always include the data dir so user can also browse manually
  roots <- c("Mounted Data" = DATA_DIR, home = "~", getVolumes()())
  shinyDirChoose(input, "directory_select", roots = roots, session = session)

  # Pre-populate with mounted dir if volume was detected; updated on user picker selection
  local_path_val <- reactiveVal(if (nzchar(preset_dir)) preset_dir else NULL)

  observeEvent(input$directory_select, {
    path <- parseDirPath(roots, input$directory_select)
    if (length(path) > 0 && nzchar(path)) {
      local_path_val(path)
    }
  }, ignoreInit = TRUE)

  # Parsed directory path for local mode
  local_path <- reactive(local_path_val())

  # Reactive value for cloud mode (unzipped zip)
  cloud_path <- reactiveVal(NULL)

  # Final directory path based on mode
  directory_path <- reactive({
    if (isTRUE(input$input_mode == "local")) {
      local_path()
    } else {
      cloud_path()
    }
  })

  # Observer for ZIP upload
  observeEvent(input$zip_upload, {
    req(input$zip_upload)

    # Cleanup previous temp dir if exists
    if (!is.null(cloud_path()) && dir.exists(cloud_path())) {
      unlink(cloud_path(), recursive = TRUE)
    }

    # Create new temp dir
    tdir <- file.path(tempdir(), paste0("epimod_results_", format(Sys.time(), "%Y%m%d_%H%M%S")))
    dir.create(tdir, showWarnings = FALSE)

    # Unzip
    tryCatch(
      {
        unzip(input$zip_upload$datapath, exdir = tdir)
        # Find folder containing params.RDS or trace files
        all_files <- list.files(tdir, recursive = TRUE, full.names = TRUE)

        # Priority 1: Folder with params.RDS
        params_files <- all_files[grepl("params", basename(all_files))]
        # Priority 2: Folder with .trace files
        trace_files <- all_files[grepl("\\.trace$", all_files)]

        if (length(params_files) > 0) {
          if (any(grepl("sensitivity", params_files))) {
            sensindex <- which(grepl("sensitivity", params_files))[1]
            res_dir <- dirname(params_files[sensindex])
            params_file <- params_files[sensindex]
          } else {
            res_dir <- dirname(params_files[1])
            params_file <- params_files[1]
          }

          # If we ALSO have traces, let's patch the path for Sensitivity
          if (length(trace_files) > 0) {
            trace_dir <- dirname(trace_files[1])

            # Load and patch params
            p <- readRDS(params_file)

            # We need the path from dirname(res_dir) to trace_dir
            # because epimod.plot calls file.path(dirname(directory), folder_trace)
            base_dir <- normalizePath(dirname(res_dir), winslash = "/", mustWork = FALSE)
            abs_trace_dir <- normalizePath(trace_dir, winslash = "/", mustWork = FALSE)

            if (grepl(paste0("^", base_dir), abs_trace_dir)) {
              # If trace_dir is a descendant of base_dir (includes siblings)
              new_folder_trace <- sub(paste0("^", base_dir, "/?"), "", abs_trace_dir)
            } else {
              # Fallback: if they are not in the same sub-tree, use the folder name
              new_folder_trace <- basename(trace_dir)
            }

            p$folder_trace <- new_folder_trace
            saveRDS(p, params_file)
          }

          cloud_path(res_dir)
        } else if (length(trace_files) > 0) {
          # Only traces found - likely an Analysis experiment
          cloud_path(dirname(trace_files[1]))
        } else {
          cloud_path(tdir)
        }
      },
      error = function(e) {
        cloud_path(NULL)
        showNotification(paste("Error unzipping:", e$message), type = "error")
      }
    )
  })

  # Cleanup on session end
  onSessionEnded(function() {
    if (!is.null(cloud_path()) && dir.exists(cloud_path())) {
      unlink(cloud_path(), recursive = TRUE)
    }
  })

  # Display selected path
  output$selected_path_display <- renderText({
    path <- local_path()
    if (is.null(path) || length(path) == 0 || path == "") {
      if (volume_is_mounted) {
        paste0("Mounted folder: ", DATA_DIR, " \u2014 click 'Check data' to load")
      } else {
        "No folder selected"
      }
    } else {
      if (volume_is_mounted && path == DATA_DIR) {
        paste0("Mounted folder: ", path)
      } else {
        path
      }
    }
  })

  dir_valid <- reactiveVal(FALSE)
  exp_type <- reactiveVal(NULL)
  exp_n_run <- reactiveVal(NULL)
  reference_file <- reactiveVal(NULL)
  selected_places <- reactiveVal(character(0))
  selected_params <- reactiveVal(character(0))
  varying_params <- reactiveVal(NULL)

  current_plot_main <- reactiveVal(NULL)
  current_plot_prcc <- reactiveVal(NULL)
  current_plot_prcc2 <- reactiveVal(NULL)
  current_plot_scatter <- reactiveVal(NULL)
  current_plot_scatter2 <- reactiveVal(NULL)
  current_plot_sobol <- reactiveVal(NULL)

  plot_error_main <- reactiveVal(NULL)
  plot_error_scatter <- reactiveVal(NULL)
  plot_error_prcc <- reactiveVal(NULL)
  plot_error_sobol <- reactiveVal(NULL)

  scatter_params_selected <- reactiveValues(x = NULL, y = NULL)
  scatter_params_selected2 <- reactiveValues(x2 = NULL, y2 = NULL)

  places <- reactive({
    req(dir_valid(), directory_path())
    tryCatch(
      {
        if (exists("get_places", mode = "function")) {
          get_places(directory_path())
        } else {
          stop("Manca get_places")
          character(0)
        }
      },
      error = function(e) character(0)
    )
  })

  observeEvent(places(),
    {
      new_choices <- places()
      updatePickerInput(session, "place_selector",
        choices = new_choices,
        selected = new_choices
      )
      selected_places(new_choices)
    },
    ignoreNULL = FALSE
  )

  observeEvent(input$place_selector,
    {
      selected_places(input$place_selector)
    },
    ignoreInit = TRUE
  )

  observeEvent(input$place_selector_empty,
    {
      req(places())
      allp <- places()
      updatePickerInput(session, "place_selector",
        choices = allp,
        selected = allp
      )
      selected_places(allp)
    },
    ignoreInit = TRUE
  )

  params <- reactive({
    req(dir_valid(), directory_path())
    tryCatch(
      {
        if (exists("sensitivity.prcc", mode = "function")) {
          tmp <- sensitivity.prcc(directory = directory_path(), target = input$prcc_target_tab)
          tmp$param_names
        } else {
          stop("Manca sensitivity.prcc")
          character(0)
        }
      },
      error = function(e) character(0)
    )
  })

  observeEvent(input$reference, {
    if (!is.null(input$reference)) {
      reference_file(input$reference$datapath)
    } else {
      reference_file(NULL)
    }
  })

  observeEvent(directory_path(), {
    dir_valid(FALSE)
    exp_type(NULL)
    exp_n_run(NULL)
    output$directory_info <- renderUI({
      NULL
    })

    session$sendInputMessage("reference", list(value = NULL))
    reference_file(NULL)
    current_plot_main(NULL)
    current_plot_scatter(NULL)
    current_plot_scatter2(NULL)
    current_plot_prcc(NULL)
    current_plot_prcc2(NULL)
    current_plot_sobol(NULL)
    plot_error_main(NULL)
    plot_error_scatter(NULL)
    plot_error_prcc(NULL)
    plot_error_sobol(NULL)
    removeTab(inputId = "tabs", target = "Scatter")
    removeTab(inputId = "tabs", target = "PRCC")
    removeTab(inputId = "tabs", target = "Sobol")
  })

  observeEvent(input$check_dir, {
    req(directory_path())
    path <- directory_path()

    plot_error_main(NULL)
    plot_error_scatter(NULL)
    plot_error_prcc(NULL)
    plot_error_sobol(NULL)
    current_plot_main(NULL)
    current_plot_scatter(NULL)
    current_plot_scatter2(NULL)
    current_plot_prcc(NULL)
    current_plot_prcc2(NULL)
    current_plot_sobol(NULL)
    removeTab(inputId = "tabs", target = "Scatter")
    removeTab(inputId = "tabs", target = "PRCC")
    removeTab(inputId = "tabs", target = "Sobol")

    tmp <- tryCatch(
      {
        if (!exists("check_directory", mode = "function")) stop("check_directory missing")
        check_directory(path)

        if (!exists("detect_experiment_type", mode = "function")) stop("detect_experiment_type missing")
        detect_experiment_type(path)
      },
      error = function(e) {
        plot_error_main(e$message)
        # Return a custom error object
        structure(list(error = e$message), class = "error")
      }
    )

    if (inherits(tmp, "error")) {
      dir_valid(FALSE)
      exp_type(NULL)
      exp_n_run(NULL)
      output$directory_info <- renderUI({
        div(
          class = "mt-3",
          style = "color:#dc3545; font-size:0.9rem; background-color: #fff5f5; border: 1px solid #ff000033; padding: 10px; border-radius: 6px;",
          tags$strong("Validation Error:"),
          tags$br(),
          tmp$error
        )
      })
      return()
    }

    if (is.null(tmp)) {
      dir_valid(FALSE)
      exp_type(NULL)
      exp_n_run(NULL)
      output$directory_info <- renderUI({
        div(style = "color:red; font-weight:bold; margin-top:10px", "Empty or invalid directory results.")
      })
      return()
    }

    dir_valid(TRUE)
    exp_type(tmp$type)
    if (tmp$type == "Analysis") {
      if (exists("get_df", mode = "function") && exists("get_time_col", mode = "function")) {
        df <- get_df(tmp$trace_files[1])
        time_col <- get_time_col(df)
        n_run <- table(df[[time_col]])[1]
        exp_n_run(n_run)
      } else {
        exp_n_run(NA)
      }
    }

    # Insert Scatter tab if varying params are found (Sensitivity or Analysis)
    if (!is.null(tmp$varying_params)) {
      varying_params(tmp$varying_params)
      scatter_params_selected$x <- varying_params()[1]
      scatter_params_selected$y <- varying_params()[2] %||% varying_params()[1]

      # Ensure places are loaded if possible
      curr_places <- tryCatch(if (exists("get_places", mode = "function")) get_places(path) else character(0), error = function(e) character(0))
      if (length(curr_places) > 0) {
        scatter_params_selected2$x2 <- curr_places[1]
        scatter_params_selected2$y2 <- if (length(curr_places) > 1) curr_places[2] else curr_places[1]
      }

      insertTab(
        inputId = "tabs",
        tabPanel("Scatter Plots", value = "Scatter", mod_plot_scatter_ui()),
        select = FALSE
      )
    }

    if (tmp$type == "Sensitivity") {
      target_prcc <- tryCatch(if (exists("get_places", mode = "function")) get_places(path) else character(0), error = function(e) character(0))
      updateSelectInput(session, "prcc_target_tab",
        choices = target_prcc,
        selected = if (length(target_prcc) > 0) target_prcc[1] else NULL
      )
      target_sobol <- tryCatch(if (exists("get_places", mode = "function")) get_places(path) else character(0), error = function(e) character(0))
      updateSelectInput(session, "sobol_target_tab",
        choices = target_sobol,
        selected = if (length(target_sobol) > 0) target_sobol[1] else NULL
      )

      insertTab(
        inputId = "tabs",
        tabPanel("PRCC Plots", value = "PRCC", mod_plot_prcc_ui()),
        select = FALSE
      )
      insertTab(
        inputId = "tabs",
        tabPanel("Sobol Plots", value = "Sobol", mod_plot_sobol_ui()),
        select = FALSE
      )
    }

    output$directory_info <- renderUI({
      # Get the display path (just the folder name for cloud, full path for local)
      display_path <- if (isTRUE(input$input_mode == "cloud")) {
        basename(path)
      } else {
        path
      }

      div(
        style = "color:darkgreen; font-weight:bold; margin-top:10px; margin-bottom:20px; background-color: #f6fff6; border: 1px solid #00800033; padding: 10px; border-radius: 6px;",
        "Data Loaded Successfully",
        tags$br(),
        tags$small(
          style = "color: #555; font-weight: normal;",
          paste("Detected Root:", display_path)
        ),
        tags$br(),
        tags$small(
          style = "color: #555; font-weight: normal;",
          paste("Experiment Type:", tmp$type)
        )
      )
    })
  })

  output$reference_ui <- renderUI({
    if (dir_valid() && exp_type() != "Analysis") {
      div(
        style = "margin-bottom:-20px;",
        fileInput("reference", "Optional reference file (.csv)", accept = ".csv")
      )
    } else {
      NULL
    }
  })

  (list(
    dir_valid = dir_valid,
    dir_path = directory_path,
    exp_type = exp_type,
    exp_n_run = exp_n_run,
    reference_file = reference_file,
    places = places,
    params = params,
    selected_places = selected_places,
    selected_params = selected_params,
    varying_params = varying_params,
    current_plot_main = current_plot_main,
    current_plot_prcc = current_plot_prcc,
    current_plot_prcc2 = current_plot_prcc2,
    current_plot_scatter = current_plot_scatter,
    current_plot_scatter2 = current_plot_scatter2,
    current_plot_sobol = current_plot_sobol,
    plot_error_main = plot_error_main,
    plot_error_scatter = plot_error_scatter,
    plot_error_prcc = plot_error_prcc,
    plot_error_sobol = plot_error_sobol,
    scatter_params_selected = scatter_params_selected,
    scatter_params_selected2 = scatter_params_selected2
  ))
}
