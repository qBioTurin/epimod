# server.R
library(shiny)
library(shinyWidgets)
library(colourpicker)
library(scico)
library(shinyFiles)

# Load function
source("R/plot.R")
source("R/prcc.R")
source("R/scatter.R")
# source("./config_generation_sensobol.R")
# source("./docker_run_laura.R")
# source("./model_analysis_laura.R")
# source("R/sobol_sensobol.R")


# source modules & utils
source("R/mod_data_inputs.R")
source("R/mod_palette.R")
source("R/mod_settings.R")
source("R/mod_plot_main.R")
source("R/mod_plot_scatter.R")
source("R/mod_plot_prcc.R")
source("R/mod_plot_sobol.R")
source("R/utils_palette.R")
source("R/utils_plot.R")

server <- function(input, output, session) {
  inputs <- mod_data_inputs_server(input, output, session)

  # observeEvent(input$check_dir,{
  #   print("check diur")
  # })
  
  output$dir_valid <- reactive({
    isTRUE(inputs$dir_valid())
  })
  
  outputOptions(output, "dir_valid", suspendWhenHidden = FALSE)
  output$exp_type <- reactive({
    req(inputs$exp_type())
    inputs$exp_type()
  })
  outputOptions(output, "exp_type", suspendWhenHidden = FALSE)
  output$exp_n_run_text <- renderText({
    inputs$exp_n_run()
  })
  outputOptions(output, "exp_n_run_text", suspendWhenHidden = FALSE)

  outputOptions(output, "reference_ui", suspendWhenHidden = FALSE)

  palettes <- mod_palette_server(input, output, session, inputs = inputs)

  settings_graphics_main <- mod_settings_server("settings_graphics_main")
  settings_variables_main <- mod_settings_server("settings_variables_main")
  settings_scatter <- mod_settings_server("settings_scatter")
  settings_graphics_prcc <- mod_settings_server("settings_graphics_prcc")
  settings_variables_prcc <- mod_settings_server("settings_variables_prcc")
  settings_graphics_sobol <- mod_settings_server("settings_graphics_sobol")
  settings_variables_sobol <- mod_settings_server("settings_variables_sobol")

  mod_plot_main_server(input, output, session,
    inputs = inputs,
    palettes = palettes,
    settings = list(
      graphics  = settings_graphics_main,
      variables = settings_variables_main
    )
  )

  mod_plot_scatter_server(input, output, session,
    inputs = inputs,
    palettes = palettes,
    settings = settings_scatter
  )

  mod_plot_prcc_server(input, output, session,
    inputs = inputs,
    palettes = palettes,
    settings = list(
      graphics  = settings_graphics_prcc,
      variables = settings_variables_prcc
    )
  )

  mod_plot_sobol_server(input, output, session,
    inputs = inputs,
    palettes = palettes,
    settings = list(
      graphics  = settings_graphics_sobol,
      variables = settings_variables_sobol
    )
  )
}
