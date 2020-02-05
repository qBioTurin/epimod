library(shiny)
library(ggplot2)

ui <- fluidPage( fluidRow( column(2,
                                  offset = 5,
                                  sliderInput(inputId = "n_traces", label = "Display traces", min = 0, max = 1e3, value = 50)),
                           actionButton(inputId = "update_plot", label = "Update")),
                 tabsetPanel( tabPanel("Phase",
                                       fluidRow(column(12, plotOutput("plot_phase")))
                                       ),
                              tabPanel("Prey",
                                       fluidRow(column(12, plotOutput("plot_prey")))
                                       ),
                              tabPanel("Predator",
                                       fluidRow(column(12, plotOutput("plot_predator")))
                                       )
                              ),
                 fluidRow(column(5, offset=1, verbatimTextOutput("text")))
                 )


server <- function(input, output, session) {
 rank <- reactive({
    if(input$n_traces > 0 && file.exists("./results/calibration_optim-trace.csv"))
    {
      rnk <- read.csv("./results/calibration_optim-trace.csv", sep = "")
      rnk <- rnk[order(rnk$distance),]
      rnk <- rnk[1:min(input$n_traces,length(rnk[,1])),]
    }
    else
    {
      rnk <- NULL
    }
    rnk
  })

  # observeEvent(input$update_plot, {
  #   if(input$n_traces > 0 && file.exists("./results/calibration_optim-trace.csv"))
  #   {
  #     rnk <- read.csv("./results/calibration_optim-trace.csv", sep = "")
  #     rnk <- rnk[order(rank$distance),]
  #     rnk <- rnk[1:min(input$n_traces,length(rank[,1])),]
  #   }
  #   else
  #     rnk <- NULL
  #   rank <- rnk
  # })

  output$plot_phase <- renderPlot({
    reference <- as.data.frame(t(read.csv("reference_data.csv", header = FALSE, sep = "")))
    plot <- ggplot()
    if(!is.null(rank()))
    {
      ListTraces<-lapply(rank()$id,
                         function(x){
                           trace.tmp=read.csv(paste0("./results/calibration-",x,".trace"), sep = "")
                           trace.tmp=data.frame(trace.tmp,Distance=rank()[which(rank()[,2]==x),1])
                           return(trace.tmp)
                         })
      traces <- do.call("rbind", ListTraces)
      plot <- plot +
        geom_path(data=traces,aes(x=Prey,y=Predator,group=Distance,col=Distance),arrow=arrow(length=unit(0.3,"cm"),ends="first"))
    }
    plot +
      geom_point(data=reference,aes(x=V1,y=V2), col="red")
  })

  output$plot_prey <- renderPlot({
    reference <- as.data.frame(t(read.csv("reference_data.csv", header = FALSE, sep = "")))
    time <- (0:200)*.1
    plot <- ggplot()
    if(!is.null(rank()))
    {
      ListTraces<-lapply(rank()$id,
                         function(x){
                           trace.tmp=read.csv(paste0("./results/calibration-",x,".trace"), sep = "")
                           trace.tmp=data.frame(trace.tmp,Distance=rank()[which(rank()[,2]==x),1])
                           return(trace.tmp)
                         })
      traces <- do.call("rbind", ListTraces)
      plot <- plot +
        geom_path(data=traces,aes(x=Time,y=Prey,group=Distance,col=Distance))
    }
    plot +
      geom_point(data=reference,aes(x=time,y=V1), col="red")
  })

  output$plot_predator <- renderPlot({
    reference <- as.data.frame(t(read.csv("reference_data.csv", header = FALSE, sep = "")))
    time <- (0:200)*.1
    plot <- ggplot()
    if(!is.null(rank()))
    {
      ListTraces<-lapply(rank()$id,
                         function(x){
                           trace.tmp=read.csv(paste0("./results/calibration-",x,".trace"), sep = "")
                           trace.tmp=data.frame(trace.tmp,Distance=rank()[which(rank()[,2]==x),1])
                           return(trace.tmp)
                         })
      traces <- do.call("rbind", ListTraces)
      plot <- plot +
        geom_path(data=traces,aes(x=Time,y=Predator,group=Distance,col=Distance))
    }
    plot +
      geom_point(data=reference,aes(x=time,y=V2), col="red")
  })

  output$text <- renderPrint(rank())

}

shinyApp(ui, server)
