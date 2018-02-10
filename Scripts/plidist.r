install.packages("plotly")

library(plotly)

c<-read.table("orbis.csv", header=TRUE, sep=";")
c$Value<-as.numeric(as.character(c$Value))

Sys.setenv("plotly_username"="MarcoRepetto")
Sys.setenv("plotly_api_key"="mCD0rm22RbZBdTQhYOKQ")

p <- plot_ly(c, y = ~c$Value, color = ~c$Type, type = "box")

p1 <- plot_ly(y = ~c$Value, type = "histogram")


s <- subplot(
  plotly_empty(),
  plotly_empty(),
  plot_ly(c, y = ~c$Value, color = ~c$Type, type = "box"),
  plot_ly(y = ~c$Value, color = I("grey") , opacity = 0.8, type = "histogram"),
  nrows = 2, heights = c(0.2, 0.8), widths = c(0.8, 0.2), margin = 0,
  shareX = TRUE, shareY = TRUE, titleX = FALSE, titleY = TRUE
)
p <- layout(s, showlegend = TRUE)

chart_link = api_create(p, filename="Peeno")
