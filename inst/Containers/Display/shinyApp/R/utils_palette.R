# R/utils_palette.R

get_palette <- function(scheme, manual = NULL, n = 5) {
  requireNamespace("viridis", quietly = TRUE)
  requireNamespace("RColorBrewer", quietly = TRUE)
  switch(scheme,
         viridis      = viridis::viridis(n),
         brewer       = RColorBrewer::brewer.pal(max(3, min(8, n)), "Set1"),
         ggsci_npg    = { if (requireNamespace("ggsci", quietly = TRUE)) ggsci::pal_npg()(n) else viridis::viridis(n) },
         wesanderson  = { if (requireNamespace("wesanderson", quietly = TRUE)) wesanderson::wes_palette("Darjeeling1") else viridis::viridis(n) },
         metbrewer    = { if (requireNamespace("MetBrewer", quietly = TRUE)) MetBrewer::met.brewer("Hokusai1", n = n) else viridis::viridis(n) },
         scico        = { if (requireNamespace("scico", quietly = TRUE)) scico::scico(n, palette = "lajolla") else viridis::viridis(n) },
         manual       = {
           if (is.null(manual)) return(rep("#CCCCCC", 3))
           if (is.character(manual) && length(manual) == 1) {
             cols <- strsplit(manual, ",")[[1]] |> trimws()
           } else {
             cols <- manual
           }
           if (length(cols) < 3) cols <- c(cols, rep("#CCCCCC", 3 - length(cols)))
           cols[seq_len(3)]
         },
         viridis::viridis(n)
  )
}

palette_preview_ui <- function(cols) {
  if (is.null(cols) || length(cols) == 0) return(NULL)
  div(
    lapply(cols, function(cl) {
      div(style = paste0(
        "display:inline-block;width:30px;height:20px;",
        "background-color:", cl, ";border:1px solid #ccc;margin-right:3px;"
      ))
    })
  )
}
