# app.R - Credit Scoring Shiny App
library(shiny)
library(shinyWidgets)
library(DT)
library(tidyverse)
library(digest)
library(parsnip)
library(workflows)
library(recipes)
library(rsample)
library(yardstick)

source('scripts/train_model.R')

ui <- fluidPage(
  titlePanel('Credit Scoring — R + Shiny (Cached Models)'),
  sidebarLayout(
    sidebarPanel(
      fileInput('file', 'Upload CSV', accept = c('.csv')),
      uiOutput('target_ui'),
      uiOutput('id_ui'),
      uiOutput('model_ui'),
      actionButton('train', 'Train / Retrain'),
      hr(),
      downloadButton('download_scores','Download Scores CSV'),
      helpText(textOutput('note_text'))
    ),
    mainPanel(
      tabsetPanel(
        tabPanel('Data', DTOutput('table')),
        tabPanel('Models', DTOutput('leaderboard')),
        tabPanel('Evaluation', plotOutput('roc_plot'), verbatimTextOutput('metrics_text')),
        tabPanel('Scores', DTOutput('scores'))
      )
    )
  )
)

server <- function(input, output, session) {
  uploaded <- reactiveVal(NULL)
  uploaded_fp <- reactiveVal(NULL)
  models_cache <- reactiveVal(list())
  leaderboard <- reactiveVal(tibble())

  available_models <- reactive({
    base <- c('logistic','rf','xgb')
    if('lightgbm' %in% installed.packages()[,'Package']) base <- c(base, 'lgbm')
    base
  })

  output$model_ui <- renderUI({
    choices <- available_models()
    selectInput('model_type', 'Choose model', choices = choices, selected = choices[1])
  })

  output$note_text <- renderText({
    if(!('lgbm' %in% available_models())) {
      'LightGBM not installed — option hidden. To enable, install the lightgbm R package on the server.'
    } else ''
  })

  observeEvent(input$file, {
    req(input$file)
    df <- read.csv(input$file$datapath, stringsAsFactors = FALSE)
    uploaded(df)
    uploaded_fp(NULL)
    models_cache(list())
    leaderboard(tibble())
    output$target_ui <- renderUI({ selectInput('target_col', 'Target column', choices = names(df), selected = tail(names(df), 1)) })
    output$id_ui <- renderUI({ selectInput('id_col', 'ID column (optional)', choices = c('', names(df)), selected = '') })
  })

  output$table <- renderDT({
    req(uploaded())
    datatable(head(uploaded(), 200), options = list(scrollX = TRUE))
  })

  observeEvent(input$train, {
    req(uploaded(), input$target_col, input$model_type)
    df <- uploaded()
    target <- input$target_col
    model_type <- input$model_type
    fp <- digest::digest(readr::read_file(input$file$datapath), algo = 'md5')
    uploaded_fp(fp)

    showModal(modalDialog(sprintf('Training %s... (this may take a minute for large data)', model_type), footer = NULL))
    res <- tryCatch({
      train_model(df = df, target = target, model_type = model_type, cache_dir = 'models')
    }, error = function(e) {
      removeModal()
      showNotification(paste('Training error:', e$message), type = 'error')
      NULL
    })
    removeModal()
    req(res)
    mc <- models_cache()
    mc[[model_type]] <- res$path
    models_cache(mc)
    lb <- leaderboard()
    lb <- bind_rows(lb, tibble(model = model_type, auc = res$metrics$auc, ks = res$metrics$ks, path = res$path))
    leaderboard(lb)
    showNotification(sprintf('Model %s trained. AUC=%.3f KS=%.3f', model_type, res$metrics$auc, res$metrics$ks), type = 'message')
  })

  output$leaderboard <- renderDT({
    req(leaderboard())
    datatable(leaderboard(), options = list(pageLength = 10))
  })

  output$metrics_text <- renderPrint({
    req(input$model_type)
    mt <- input$model_type
    mc <- models_cache()
    if(is.null(mc[[mt]])) { cat('No model trained yet for', mt); return() }
    metrics <- readRDS(file.path(mc[[mt]], 'metrics.rds'))
    print(metrics)
  })

  output$roc_plot <- renderPlot({
    req(input$model_type, uploaded())
    mt <- input$model_type
    mc <- models_cache()
    if(is.null(mc[[mt]])) return(NULL)
    wf <- readRDS(file.path(mc[[mt]], 'workflow.rds'))
    df <- uploaded()
    target <- input$target_col
    preds <- predict(wf, df, type = 'prob') %>% bind_cols(df %>% select(all_of(target)))
    if('pROC' %in% rownames(installed.packages())) {
      roc_obj <- try(pROC::roc(response = preds[[target]], predictor = preds[['.pred_1']]), silent = TRUE)
      if(!inherits(roc_obj, 'try-error')) {
        plot(roc_obj, main = paste('ROC -', mt))
      }
    } else {
      plot.new(); text(0.5,0.5,'Install pROC for ROC plot')
    }
  })

  scored_data <- reactive({
    req(input$model_type, uploaded())
    mt <- input$model_type
    mc <- models_cache()
    if(is.null(mc[[mt]])) return(NULL)
    wf <- readRDS(file.path(mc[[mt]], 'workflow.rds'))
    df <- uploaded()
    probs <- predict(wf, df, type = 'prob') %>% pull(.pred_1)
    df %>% mutate(.score = probs)
  })

  output$scores <- renderDT({
    req(scored_data())
    datatable(head(scored_data(), 200), options = list(scrollX = TRUE))
  })

  output$download_scores <- downloadHandler(
    filename = function() paste0('scored_', Sys.Date(), '.csv'),
    content = function(file) {
      req(scored_data())
      write.csv(scored_data(), file, row.names = FALSE)
    }
  )
}

shinyApp(ui, server)
