library(shiny)
library(ggplot2)

ui <- fluidPage( theme="bootstrap.css",
                 fluidRow( column(3,
                                  selectInput("dir", h3("Source Directory"),
                                              choices = "")),
                           column(3,
                                  offset=1,
                                  sliderInput(inputId = "n_traces", label = h3("Display traces"), min = 0, max = 1e3, value = 20)),
                           column(3,
                                  offset=1,
                                  selectInput("reference.file", h3("Reference file"),
                                              choices = ""))
                 ),
                 fluidRow(
                           column(4,
                                  offset=4,
                                  actionButton(inputId = "update_page", label = h4("Update Plot"))
                                  )
                           ),
                 tabsetPanel( id = "tabs",
                              tabPanel("Plot traces with distance based ranking",
                                       value="distance",
                                       fluidRow(column(width=5,
                                                       textAreaInput(label = div(class="w-75",h4("Write the distance function here:")),
                                                                     inputId = "distance.function"),
                                                       checkboxInput(inputId = "load.function", label = h4("Load Function"), value = FALSE)),
                                                column(width=3,
                                                       offset=1,
                                                       selectInput(inputId="places", label=h4("Select place(s) to plot"), choices=c(), selected = NULL, multiple = TRUE,
                                                                   selectize = TRUE)),#, width = NULL, size = NULL)),
                                                column(width = 1,
                                                       offset = 1,
                                                       checkboxInput(inputId = "values.diff", label = h4("Plot differences"), value = FALSE))
                                                ),
                                       p("NOTE: define a function called ",em("distance")," taking two parameters: the first parameter is a simulation trace and the second one the reference data."),
                                       fluidRow(column(12, plotOutput("plot")))
                                       )
                              ),
                 fluidRow(column(5, offset=1, verbatimTextOutput("text"))),
                 fluidRow(column(5, offset=1, verbatimTextOutput("configuration_text")))
                 )

server <- function(input, output, session) {
    data_dir <- "./data"
    # reference <- as.data.frame(t(read.csv("input/reference_data.csv", header = FALSE, sep = "")))

    rv <- reactiveValues(folders = c("No directory selected", lapply(list.dirs(path=data_dir)[-1], function(x){basename(x)})),
                         reference.files = c("No file selected",grep(list.files(path = data_dir,recursive = TRUE),
                                               pattern = "[[:graph:]]+(-){1}[[:digit:]]+(.trace)",
                                               invert = TRUE,
                                               value = TRUE)
                                            ),
                         reference=NULL,
                         rank = data.frame(),
                         ls = data.frame(),
                         traces = data.frame())

    observeEvent(input$reference.file,
                 {
                     if(file.exists(file.path(data_dir,input$reference.file,fsep=.Platform$file.sep)) && input$reference.file != "")
                     {
                         rv$reference<-as.data.frame(t(read.csv(file.path(data_dir,input$reference.file,fsep=.Platform$file.sep), header = FALSE, sep = "")))
                     }
                 })

    observeEvent(input$dir,
                 {
                     if(dir.exists(file.path(data_dir,input$dir,fsep=.Platform$file.sep)))
                     {
                         rv$ls<-list.files(path = file.path(data_dir,input$dir,fsep=.Platform$file.sep), pattern = "[[:graph:]]+(-){1}[[:digit:]]+(.trace)")
                         rv$traces <- lapply(rv$ls,
                                          function(x){
                                              f <- file.path(data_dir,input$dir, x, fsep=.Platform$file.sep)
                                              if(file.exists(f))
                                              {
                                                  tr <- read.csv(f, sep = "")
                                                  id <- as.numeric(gsub(pattern="(.trace)",
                                                                        gsub(pattern="([[:graph:]]+(-){1})",
                                                                             x=x, replacement=""),
                                                                        replacement=""))
                                                  id <- data.frame(id=rep(id,length(tr[,1])))
                                                  tr<-cbind(tr,id)
                                                  return(tr)
                                              }
                                          }
                         )
                         # rv$traces <- do.call("rbind",traces)
                         if(input$tabs=="distance" && length(rv$ls)!=0)
                         {
                             if(input$load.function && input$distance.function != "")
                             {
                                 eval(parse(text=input$distance.function))
                                 rnk <- sapply(rv$traces,
                                               function(x){
                                                   # Compute the distance
                                                   d <- distance(x,rv$reference)
                                                   id <- x$id[1]
                                                   return(c(id, d))
                                               })
                                 rnk <- as.data.frame(t(rnk))
                                 names(rnk) <- c("id", "distance")
                                 rownames(rnk) <- c()
                                 rnk$distance <- sapply(rnk$distance,as.numeric)
                                 rv$rank <- rnk
                             } else{
                                 ids<- sapply(rv$ls,
                                              function(x){
                                                  as.numeric(gsub(pattern="(.trace)",
                                                                  gsub(pattern="([[:graph:]]+(-){1})",
                                                                       x=x, replacement=""),
                                                                  replacement=""))
                                              })
                                 rv$rank <- data.frame(id=ids,distance=c(1:length(ids)))
                             }
                         }

                     }
                 })

    output$plot <- renderPlot({
        plot <- ggplot()
        rnk <- rv$rank
        traces <- NULL
        if(input$n_traces > 0 && length(rnk) > 0 && length(input$places) >0)
        {
            rnk<-cbind(rnk,c(1:length(rnk[,1])))
            names(rnk) <- c("id","distance","idx")
            rnk <- rnk[order(rnk$distance),]
            limit_tr <-input$n_traces
            if(limit_tr>length(rnk))
            {
                limit_tr<-length(rnk)
            }
            rnk <- rnk[1:limit_tr,]
            col_idxs <- which(names(rv$traces[[1]]) %in% c(input$places))
            traces <- lapply(rnk$idx,
                             function(x){
                                 r<-rv$traces[[x]]
                                 t<-r[,col_idxs]
                                 if(length(input$places)>1)
                                    t <- rowSums(t)
                                 if(input$values.diff)
                                 {
                                     t<-t[-1]
                                     t <-c(t[1], diff(t,differences=1))
                                     r <-r[-1,]
                                 }
                                 t <- data.frame(Value=t)
                                 t<-cbind(r$Time, t, r$id, rep(rv$rank$distance[x],length(t[,1])))
                             })
            traces <- do.call("rbind",traces)
            traces <- as.data.frame(traces)
            names(traces)<-c("Time","Value","id","distance")
            plot <- plot +
                geom_line(data=traces,aes(x=Time,y=Value,group=id,col=traces$distance),size=1)
        }
        if(!is.null(rv$reference))
        {
            if(!is.null(traces))
            {
                time <- unique(traces$Time)
            } else {
                time<-c(1:max(dim(rv$reference)))
            }
            df <-data.frame(Time=time,Reference=rv$reference)
            names(df)<-c("Time","Reference")
            plot +
                geom_line(data=df,aes(x=Time,y=Reference), col="red",size=1)
        }
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

    observeEvent(input$load.function, {
        eval(parse(text=input$distance.function))
    })

    observe({
        updateSelectInput(session, "dir",
                          choices = rv$folders
        )})

    observe({
        updateSelectInput(session, "reference.file",
                          choices = rv$reference.files
        )})

    observeEvent(rv$traces,{
        updateSelectInput(session, "places",
                          choices = if(length(rv$traces)>0) names(rv$traces[[1]]))
        })


    output$configuration_text <- renderPrint({
        list(dir=file.path(data_dir,input$dir,fsep=.Platform$file.sep),
             reference.files=file.path(data_dir,input$reference.file,fsep=.Platform$file.sep),
             ls=rv$ls,
             reference=rv$reference
             )
    })
}



shinyApp(ui, server)
