# Oxford College Chatbot

This project is a Flask-based chatbot using Retrieval-Augmented Generation (RAG) with LightRAG and Google Gemini.

## Migration to uv

The project has been migrated to use [uv](https://github.com/astral-sh/uv) for fast, reliable dependency management.

### Prerequisites

- [uv](https://github.com/astral-sh/uv) installed on your system.

### Installation

1. Clone the repository.
2. Install dependencies and create a virtual environment:
   ```bash
   uv sync
   ```
3. Copy `.env.template` to `.env` and add your `GEMINI_API_KEY`:
   ```bash
   cp .env.template .env
   ```

### Running the Application

To start the Flask backend:
```bash
uv run python app.py
```

### Running Tests

To run the test suite:
```bash
uv run python -m pytest
```

## Project Structure

- `app.py`: Flask backend providing API endpoints.
- `rag.py`: RAG pipeline implementation using LightRAG and Google Gemini.
- `tests/`: Unit tests for the application and RAG logic.
- `SCT/`: Storage directory for LightRAG's knowledge base.
- `frontend/`: React frontend (if applicable).
- `pyproject.toml`: Project configuration and dependencies managed by uv.
