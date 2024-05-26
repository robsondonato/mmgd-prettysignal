library(shiny)
library(openxlsx)

ui <- fluidPage(
  titlePanel("Solar Pretty Signal - Shiny App"),
  sidebarLayout(
    sidebarPanel(
      fileInput("file", "Choose XLSX File", accept = c(".xlsx")),
      checkboxInput("midnight", "Midnight is first hour", TRUE)
    ),
    mainPanel(
      tableOutput("table")
    )
  )
)

server <- function(input, output) {
  data <- reactive({
    req(input$file)
    read.xlsx(input$file$datapath, sheet = 1)
  })

  output$table <- renderTable({
    req(data())
    result <- solar_prettysignal(data(), input$midnight)
    result
  })
}

shinyApp(ui = ui, server = server)
