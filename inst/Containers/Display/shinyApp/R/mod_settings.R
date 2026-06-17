# R/mod_settings.R
# button management

mod_settings_ui <- function(id) {
  ns <- NS(id)
  
  tagList(
    fluidRow(
      column(
        width = 6,
        actionButton(
          ns("apply_settings"),
          "Apply settings",
          class = "btn-primary w-100"
        )
      ),
      column(
        width = 6,
        actionButton(
          ns("reset_settings"),
          "Reset settings",
          class = "btn-secondary w-100",
          style = "background-color: #d3d3d3; color: #000; border-color: #bcbcbc;"
        )
      )
    ),
  )
}

mod_settings_server <- function(id) {
  moduleServer(id, function(input, output, session) {
    
    settings_apply <- reactive({
      req(input$apply_settings)
      input$apply_settings
    })
    
    settings_reset <- reactive({
      req(input$reset_settings)
      input$reset_settings
    })
    
    return(list(
      apply = settings_apply,
      reset = settings_reset
    ))
  })
}
