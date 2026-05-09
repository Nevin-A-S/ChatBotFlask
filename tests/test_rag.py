import pytest
from unittest.mock import AsyncMock, MagicMock, patch
import numpy as np
from rag import return_response, add_to_conversation_history, CONVERSATION_HISTORY

@pytest.fixture(autouse=True)
def clear_history():
    CONVERSATION_HISTORY.clear()
    yield
    CONVERSATION_HISTORY.clear()

def test_add_to_conversation_history():
    add_to_conversation_history("Hello", "Hi there!")
    assert len(CONVERSATION_HISTORY) == 2
    assert CONVERSATION_HISTORY[0] == {"role": "user", "content": "Hello"}
    assert CONVERSATION_HISTORY[1] == {"role": "assistant", "content": "Hi there!"}

@patch('rag.get_rag')
def test_return_response_no_rag(mock_get_rag):
    mock_get_rag.return_value = None
    response = return_response("test query")
    assert "unavailable" in response.lower()

@patch('rag.get_rag')
def test_return_response_success(mock_get_rag):
    mock_rag_instance = MagicMock()
    mock_rag_instance.aquery = AsyncMock(return_value="Mocked answer")
    mock_get_rag.return_value = mock_rag_instance
    
    response = return_response("What is the location?")
    assert response == "Mocked answer"
    assert len(CONVERSATION_HISTORY) == 2
    assert CONVERSATION_HISTORY[0]['content'] == "What is the location?"
    assert CONVERSATION_HISTORY[1]['content'] == "Mocked answer"
