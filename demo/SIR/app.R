library(shiny)
library(ggplot2)

ui <- fluidPage( fluidRow( column(3,
                                  sliderInput(inputId = "n_traces", label = "Display traces", min = 0, max = 1e3, value = 20)
                                  ),
                           column(3,
                                  selectInput("dir", h3("Select box"),
                                              choices = "")),
                           column(3,
                                  offset=1,
                                  actionButton(inputId = "update_page", label = "Update")
                                  )
                           ),
                 tabsetPanel( tabPanel("Phase",
                                       fluidRow(column(12, plotOutput("plot_phase")))
                                       ),
                              tabPanel("Susceptibles",
                                       fluidRow(column(12, plotOutput("plot_susceptibles")))
                                       ),
                              tabPanel("Infects",
                                       fluidRow(column(12, plotOutput("plot_infects")))
                                       )
                              ),
                 fluidRow(column(5, offset=1, verbatimTextOutput("text")))
                 )


msqd<-function(reference, output)
{
    reference[,1] -> times_ref
    reference[,3] -> infect_ref

    # We will consider the same time points
    Infect <- output[which(output$Time %in% times_ref),"I"]
    infect_ref <- infect_ref[which( times_ref %in% output$Time)]

    diff.Infect <- sum(( Infect - infect_ref )^2 )

    return(diff.Infect)
}


server <- function(input, output, session) {
    reference <- as.data.frame(t(read.csv("input/reference_data.csv", header = FALSE, sep = "")))
    rv <- reactiveValues(folders = lapply(list.dirs()[-1], function(x){basename(x)}),
                         rank = data.frame(),
                         ls = data.frame())

    update.rank <- function()
    {
        rank_file <- file.path(input$dir,"rank.csv", fsep = .Platform$file.sep)
        # Load the ls of the target folder
        ls <- list.files(path = input$dir, pattern = "[[:graph:]]+(-){1}[[:digit:]]+(.trace)")
        if(length(ls) != length(rv$ls))
        {
            rv$ls <- as.data.frame(ls)
        }
        # Remove traces with already a rank
        # if( length(rv$rank) > 0)
        # {
        #    ls <- ls[-which(ls %in% rv$rank$file_name)]
        # }
        # Compute the rank for the remaining traces
        if(length(ls) > 0)
        {
            rnk <- sapply(ls,
                        function(x){
                            # Compute the distance
                            d <- msqd(reference,
                                      read.csv(file.path(input$dir, x, fsep = .Platform$file.sep), sep = ""))
                            id <- as.numeric(gsub(pattern="(.trace)",
                                                  gsub(pattern="([[:graph:]]+(-){1})",
                                                       x=x, replacement=""),
                                                  replacement="")
                            )
                            return(c(id, d, x))
                        })
            rnk <- as.data.frame(t(rnk))
            names(rnk) <- c("id", "distance", "file_name")
            rownames(rnk) <- c()
            rnk$distance <- sapply(rnk$distance,as.numeric)
            # Keep the previously computed ranks
            # if(!is.null(rv$rank))
            #     rnk <- rbind(rv$rank, rnk)
            # write.table(rnk, file = rank_file, sep = " ", row.names = FALSE)
            rv$rank <- rnk
        }
    }
    # rank <- reactive({
    #     rank_file <- file.path(input$dir,"rank.csv", fsep = .Platform$file.sep)
    #     rnk <- NULL
    #     # Load the ls of the target folder
    #     ls <- list.files(path = input$dir, pattern = "[[:graph:]]+(-){1}[[:digit:]]+(.trace)")
    #     # Remove traces with already a rank
    #     if( file.exists(rank_file))
    #     {
    #         rnk <- read.csv(file =rank_file, sep = "")
    #         ls <- ls[-which(ls %in% rnk)]
    #     }
    #     # Compute the rank for the remaining traces
    #     r <- sapply(ls,
    #                 function(x){
    #                     # Compute the distance
    #                     d <- msqd(reference,
    #                               read.csv(file.path(input$dir, x, fsep = .Platform$file.sep), sep = ""))
    #                     id <- as.numeric(gsub(pattern="(.trace)",
    #                                           gsub(pattern="([[:graph:]]+(-){1})",
    #                                                x=x, replacement=""),
    #                                           replacement="")
    #                                      )
    #                     return(c(id, d, x))
    #                 })
    #     if(length(r) > 0)
    #     {
    #         r <- as.data.frame(t(r))
    #         names(r) <- c("id", "distance", "file_name")
    #         r$distance <- sapply(r$distance,as.numeric)
    #         # Keep the previously computed ranks
    #         if(!is.null(rnk))
    #             r <- rbind(rnk, r)
    #         write.table(r, file = rank_file, sep = " ", row.names = FALSE)
    #         rownames(r) <- c()
    #     }
    #     else
    #     {
    #         r <- rnk
    #     }
    #     r
    # })

    output$plot_phase <- renderPlot({
        plot <- ggplot()
        update.rank()
        rnk <- rv$rank
        if(input$n_traces > 0 && length(rnk) > 0)
        {
            rnk <- rnk[order(rnk$distance),]
            ListTraces<-lapply((1:min(input$n_traces,length(rnk$id))),
                               function(x){
                                   trace.tmp=as.data.frame(read.csv(file.path(input$dir,rnk$file_name[x], fsep = .Platform$file.sep), sep = ""))
                                   #trace.tmp=data.frame(trace.tmp,Distance=rnk$distance[x])
                                   trace.tmp$Distance <- rnk$distance[x]
                                   return(trace.tmp)
                               })
            traces <- do.call("rbind", ListTraces)
            plot <- plot +
                geom_path(data=traces,aes(x=S,y=I,group=Distance,col=Distance),arrow=arrow(length=unit(0.3,"cm"),ends="first"))
        }
        plot +
            geom_point(data=reference,aes(x=V2,y=V3), col="red")
    })

    output$plot_susceptibles <- renderPlot({
        plot <- ggplot()
        rnk <- rv$rank
        if(input$n_traces > 0 && length(rnk) > 0)
        {
            rnk <- rnk[order(rnk$distance),]
            ListTraces<-lapply((1:min(input$n_traces,length(rnk$id))),
                               function(x){
                                   trace.tmp=as.data.frame(read.csv(file.path(input$dir,rnk$file_name[x], fsep = .Platform$file.sep), sep = ""))
                                   #trace.tmp=data.frame(trace.tmp,Distance=rnk$distance[x])
                                   trace.tmp$Distance <- rnk$distance[x]
                                   return(trace.tmp)
                               })
            traces <- do.call("rbind", ListTraces)
            plot <- plot +
                geom_path(data=traces,aes(x=Time,y=S,group=Distance,col=Distance),arrow=arrow(length=unit(0.3,"cm"),ends="first"))
        }
        plot +
            geom_point(data=reference,aes(x=V1,y=V2), col="red")
    })

    output$plot_infects <- renderPlot({
        plot <- ggplot()
        rnk <- rv$rank
        if(input$n_traces > 0 && length(rnk) > 0)
        {
            rnk <- rnk[order(rnk$distance),]
            ListTraces<-lapply((1:min(input$n_traces,length(rnk$id))),
                               function(x){
                                   trace.tmp=as.data.frame(read.csv(file.path(input$dir,rnk$file_name[x], fsep = .Platform$file.sep), sep = ""))
                                   #trace.tmp=data.frame(trace.tmp,Distance=rnk$distance[x])
                                   trace.tmp$Distance <- rnk$distance[x]
                                   return(trace.tmp)
                               })
            traces <- do.call("rbind", ListTraces)
            plot <- plot +
                geom_path(data=traces,aes(x=Time,y=I,group=Distance,col=Distance),arrow=arrow(length=unit(0.3,"cm"),ends="first"))
        }
        plot +
            geom_point(data=reference,aes(x=V1,y=V3), col="red")
    })

    output$text <- renderPrint({
        rnk <- rv$rank
        if(input$n_traces > 0 && length(rnk) > 0)
        {
            rnk <- rnk[,c(1,2)]
            rnk <- rnk[order(rnk$distance),]
            rnk <- rnk[(1:min(input$n_traces,length(rnk$id))),]
        }
        rnk
    })

    observeEvent(input$update_page, {

        rv$folders <- lapply(list.dirs()[-1], function(x){basename(x)})
     })

    observe({
        updateSelectInput(session, "dir",
                          choices = rv$folders
        )})
}



shinyApp(ui, server)
# shinyApp(ui, server_calibration)
# shinyApp(ui, server_model)
