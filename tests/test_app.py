import pytest
from app import app

@pytest.fixture
def client():
    app.config['TESTING'] = True
    with app.test_client() as client:
        yield client

def test_health_check(client):
    """Test the health check endpoint"""
    response = client.get('/api/health')
    assert response.status_code == 200
    data = response.get_json()
    assert data['status'] == 'healthy'

def test_chat_no_message(client):
    """Test chat endpoint with no message"""
    response = client.post('/api/chat', json={})
    assert response.status_code == 400
    data = response.get_json()
    assert 'error' in data

def test_chat_empty_message(client):
    """Test chat endpoint with empty message"""
    response = client.post('/api/chat', json={'message': '  '})
    assert response.status_code == 400
    data = response.get_json()
    assert 'error' in data
