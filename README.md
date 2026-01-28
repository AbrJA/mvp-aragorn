# mvp-aragorn: RAG Demo with Shiny

This is a **Shiny** application that demonstrates a **Retrieval-Augmented Generation (RAG)** workflow using the `ragnar` and `ellmer` R packages with Google's Gemini model.

## Features
- **File Upload**: Supports PDF, text, Markdown, DOCX, and HTML.
- **RAG Pipeline**: Ingests, chunks, and creates vector embeddings of your documents.
- **Semantic Search**: Retrieves relevant context based on your questions.
- **Gemini Chat**: Uses the Gemini LLM to answer questions using the retrieved context.
- **Modern UI**: Styled with `bslib` for a premium look.

## Prerequisites

You need the following R packages installed:

```r
install.packages(c("shiny", "bslib", "markdown", "remotes"))
# Install ragnar and ellmer (assuming they are CRAN or GitHub packages)
# If ragnar/ellmer are on CRAN:
# install.packages(c("ragnar", "ellmer"))
# If they are on GitHub:
# remotes::install_github("r-lib/ragnar")
# remotes::install_github("tidyverse/ellmer")
```

## How to Run

1.  Open this project in RStudio or VS Code.
2.  Run the app:
    ```r
    shiny::runApp()
    ```
3.  In the app:
    *   Enter your **Google Gemini API Key**.
    *   Upload a document.
    *   Click **Ingest & Embed**.
    *   Ask a question!

## Note on API Key
The app uses the API key for both embedding generation (via `ragnar`'s `embed_google_gemini`) and chat (via `ellmer`'s `chat_gemini`). Ensure your key has access to these services.
