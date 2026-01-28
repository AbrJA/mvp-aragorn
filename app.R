library(shiny)
library(bslib)
library(ragnar)
library(ellmer)
library(markdown)

# Define the UI with a modern, dark theme
ui <- page_sidebar(
  theme = bs_theme(
    version = 5,
    bootswatch = "darkly",
    primary = "#00bc8c", # Vibrant green accent
    base_font = font_google("Inter"),
    code_font = font_google("Fira Code")
  ),
  title = "Ragnar + Gemini RAG Demo",
  sidebar = sidebar(
    title = "Configuration",
    textInput("api_key", "GEMINI_API_KEY", type = "password", placeholder = "Enter your Google AI Studio Key"),
    fileInput("file", "Upload Document",
              accept = c(".pdf", ".txt", ".md", ".docx", ".html"),
              multiple = FALSE),
    actionButton("process_btn", "Ingest & Embed", class = "btn-primary w-100"),
    hr(),
    markdown("
    **Instructions:**
    1. Enter your API Key.
    2. Upload a file (PDF, text, etc.).
    3. Click **Ingest & Embed**.
    4. Ask questions about the data.
    ")
  ),
  layout_columns(
    col_widths = c(12),
    card(
      card_header("Chat with your Data"),
      card_body(
        div(
          style = "display: flex; gap: 10px; align-items: flex-start;",
          textAreaInput("question", NULL, placeholder = "Ask a question about the uploaded document...", width = "100%", rows = 2),
          actionButton("ask_btn", "Ask", class = "btn-success", style = "margin-top: 5px;")
        ),
        hr(),
        uiOutput("chat_output")
      )
    ),
    card(
      card_header("System Status"),
      verbatimTextOutput("status_log")
    )
  )
)

# Define the Server logic
server <- function(input, output, session) {

  # Reactive values to hold the state
  rv <- reactiveValues(
    store = NULL,
    status = "Ready. Please enter API key and upload a file.",
    chat_history = list() # Future: implement chat history if needed
  )

  observeEvent(input$process_btn, {
    req(input$api_key, input$file)

    # Update status
    rv$status <- "Processing document... converting to markdown..."

    tryCatch({
      # 1. Ingest document
      # read_as_markdown handles various formats
      doc <- read_as_markdown(input$file$datapath)

      rv$status <- "Chunking document..."
      # 2. Chunk document
      chunks <- markdown_chunk(doc)

      rv$status <- "Creating vector store & generating embeddings..."

      # NOTE: We set the env var for the session so functions can find it if needed implicitly,
      # but we also pass it explicitly if the API supports it.
      Sys.setenv(GOOGLE_API_KEY = input$api_key)

      # 3. Create Store with Gemini Embeddings
      # We use embed_google_gemini() which uses the API key
      store <- ragnar_store_create(
        embed = embed_google_gemini(api_key = input$api_key)
      )

      # 4. Insert chunks
      ragnar_store_insert(store, chunks)

      rv$store <- store
      rv$status <- paste0("Success! Ingested ", length(chunks), " chunks. Ready to ask questions.")

      showNotification("Document processed successfully!", type = "message")

    }, error = function(e) {
      rv$status <- paste("Error:", e$message)
      showNotification(paste("Error processing file:", e$message), type = "error")
    })
  })

  observeEvent(input$ask_btn, {
    req(input$question, input$api_key)

    if (is.null(rv$store)) {
      showNotification("Please ingest a document first.", type = "warning")
      return()
    }

    withProgress(message = 'Thinking...', value = 0, {

      incProgress(0.3, detail = "Retrieving context...")

      tryCatch({
        # 1. Retrieve relevant chunks
        # ragnar_retrieve uses the store's embedding function to embed the query
        context_chunks <- ragnar_retrieve(rv$store, input$question)

        # Format context for the LLM
        # context_chunks is likely a data frame or list. We extract text.
        # ragnar_retrieve typically returns a data frame with a 'text' column.
        context_text <- paste(context_chunks$text, collapse = "\n\n---\n\n")

        incProgress(0.6, detail = "Querying Gemini...")

        # 2. Call Gemini via ellmer
        chat <- chat_gemini(
          api_key = input$api_key,
          system_prompt = "You are a helpful assistant. Use the provided context to answer the user's question. If the answer is not in the context, say so."
        )

        # Construct the prompt with context
        full_prompt <- paste0(
          "Context:\n", context_text, "\n\n",
          "Question: ", input$question
        )

        response <- chat$chat(full_prompt)

        # Update output
        output$chat_output <- renderUI({
          markdown(response)
        })

        rv$status <- "Answer generated."

      }, error = function(e) {
        rv$status <- paste("Error generating answer:", e$message)
        showNotification(paste("Error:", e$message), type = "error")
      })
    })
  })

  output$status_log <- renderText({
    rv$status
  })
}

shinyApp(ui, server)
