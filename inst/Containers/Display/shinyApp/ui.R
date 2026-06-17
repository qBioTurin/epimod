# ui.R
library(shiny)
library(bslib)
library(colourpicker)
library(shinyWidgets)
library(shinyFiles)

ui <- page_sidebar(
  title = "EpiMod Plot Viewer",
  theme = bs_theme(
    bootswatch = "pulse",
    primary = "#593196",
    base_font = font_google("Outfit"),
    heading_font = font_google("Outfit")
  ),

  # Inject external JS and CSS
  header = tags$head(
    includeCSS("www/css/app.css"),
    includeScript("www/js/app.js")
  ),
  sidebar = sidebar(
    title = "Configuration",
    width = 350,
    navset_pill(
      id = "input_mode",
      nav_panel(
        title = "Local",
        value = "local",
        div(
          class = "mt-3 mb-3",
          tags$label("Select Folder:", class = "form-label"),
          shinyDirButton("directory_select", "Open Picker", "Please select a folder", class = "btn-outline-secondary w-100"),
          div(
            style = "margin-top: 8px; font-size: 0.85rem; color: #666; word-break: break-all;",
            textOutput("selected_path_display")
          )
        )
      ),
      nav_panel(
        title = "Cloud (ZIP)",
        value = "cloud",
        div(
          class = "mt-3 mb-3",
          fileInput("zip_upload", "Upload results (.zip):",
            accept = c(".zip", "application/zip", "application/x-zip-compressed"),
            width = "100%"
          )
        )
      )
    ),
    actionButton("check_dir", "Check data", class = "btn-success w-100"),
    uiOutput("directory_info"),
    uiOutput("reference_ui"),
    hr(),
    conditionalPanel(
      condition = "output.dir_valid == true",
      actionButton("run", "Generate Plot", class = "btn-primary w-100 mt-3")
    )
  ),
  navset_card_pill(
    id = "tabs",
    nav_panel(
      title = "Main View",
      value = "Main",
      navset_card_pill(
        id = "subtabs_main",
        nav_panel(
          title = "Plot",
          value = "Plot",
          uiOutput("plot_error_main"),
          plotOutput("plot_main", height = "600px")
        ),
        nav_panel(
          title = "Graphic Settings",
          value = "GraphicSettings",
          card(
            card_header("Appearance Customization"),
            fluidRow(
              column(
                6,
                selectInput(
                  "color_scheme", "Color palette:",
                  choices = c(
                    "Viridis" = "viridis",
                    "Brewer - Set1" = "brewer",
                    "ggsci - NPG" = "ggsci_npg",
                    "Wes Anderson" = "wesanderson",
                    "MetBrewer - Hokusai1" = "metbrewer",
                    "Scico - lajolla" = "scico",
                    "Manual Colors" = "manual"
                  ),
                  selected = "viridis"
                )
              ),
              column(
                6,
                div(
                  class = "palette-preview-container",
                  uiOutput("palette_preview")
                )
              )
            ),
            conditionalPanel(
              condition = "input.color_scheme == 'manual'",
              div(
                class = "manual-colors-list",
                uiOutput("manual_color_inputs"),
                helpText("Select a color for each place.")
              )
            ),
            layout_column_wrap(
              width = 1 / 2,
              card(
                card_header("Transparency & Area"),
                conditionalPanel(
                  condition = "!(output.exp_type == 'Analysis' && Number(output.exp_n_run_text) == 1)",
                  sliderInput("alpha_ribbon", "Area transparency:", value = 0.2, min = 0, max = 1, step = 0.1, ticks = FALSE)
                ),
                conditionalPanel(
                  condition = "!(output.exp_type == 'Analysis' && Number(output.exp_n_run_text) == 1)",
                  sliderInput("alpha_traces", "Traces transparency:", value = 0.5, min = 0, max = 1, step = 0.1, ticks = FALSE)
                )
              ),
              card(
                card_header("Line Weights"),
                conditionalPanel(
                  condition = "output.exp_type == 'Calibration' || output.exp_type == 'Sensitivity'",
                  sliderInput("line_width_reference", "Reference line width:", value = 0.8, min = 0, max = 2, step = 0.1, ticks = FALSE)
                ),
                conditionalPanel(
                  condition = "output.exp_type == 'Analysis' && Number(output.exp_n_run_text) > 1",
                  sliderInput("line_width_mean", "Mean line width:", value = 0.8, min = 0, max = 2, step = 0.1, ticks = FALSE)
                ),
                conditionalPanel(
                  condition = "output.exp_type == 'Analysis' && Number(output.exp_n_run_text) == 1",
                  sliderInput("line_width_mean", "Line width:", value = 0.8, min = 0, max = 2, step = 0.1, ticks = FALSE)
                ),
                conditionalPanel(
                  condition = "!(output.exp_type == 'Analysis' && Number(output.exp_n_run_text) == 1)",
                  sliderInput("line_width_traces", "Traces line width:", value = 0.5, min = 0, max = 2, step = 0.1, ticks = FALSE)
                )
              )
            ),
            conditionalPanel(
              condition = "output.exp_type == 'Calibration' || output.exp_type == 'Sensitivity'",
              card(
                card_header("Distance Gradient Colors"),
                layout_column_wrap(
                  width = 1 / 2,
                  colourInput("dist_low", "Low distance color:", value = "#132B43"),
                  colourInput("dist_high", "High distance color:", value = "#56B1F7")
                )
              )
            ),
            card_footer(
              mod_settings_ui("settings_graphics_main")
            )
          )
        ),
        nav_panel(
          title = "Variables Settings",
          value = "VariablesSettings",
          card(
            card_header("Data Selection"),
            conditionalPanel(
              condition = "output.dir_valid == true",
              layout_column_wrap(
                width = 1 / 2,
                radioButtons("plot_mode", "Plot mode:",
                  choices = c("Combined" = "combined", "Separate (facet)" = "separate"),
                  selected = "combined"
                ),
                div(
                  checkboxInput("trace", "Show traces", TRUE),
                  checkboxInput("area", "Show area of variability", TRUE)
                )
              ),
              pickerInput(
                inputId = "place_selector",
                label = "Select places to plot:",
                choices = character(0),
                selected = character(0),
                multiple = TRUE,
                options = list(`live-search` = TRUE, `style` = "btn-light"),
                width = "100%"
              )
            ),
            card_footer(
              mod_settings_ui("settings_variables_main")
            )
          )
        )
      )
    )
  )
)
