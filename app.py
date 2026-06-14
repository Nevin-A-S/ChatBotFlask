from flask import Flask, request, jsonify
from flask_cors import CORS
import sys
import os
import threading

# Add the current directory to Python path to import rag.py
sys.path.append(os.path.dirname(os.path.abspath(__file__)))

try:
    from rag import return_response, warm_up
except Exception as e:
    import traceback
    print(f"Error importing rag module: {e}")
    traceback.print_exc()
    print("Make sure rag.py is in the same directory as this Flask app")
    
    def return_response(query):
        return f"RAG module not available. Echo: {query}"

    def warm_up():
        return None

app = Flask(__name__)
CORS(app)  # Enable CORS for React frontend

_warmup_started = False
_warmup_lock = threading.Lock()


def start_background_warmup():
    global _warmup_started
    with _warmup_lock:
        if _warmup_started:
            return
        _warmup_started = True
        warmup_thread = threading.Thread(
            target=warm_up,
            daemon=True,
            name="rag-warmup",
        )
        warmup_thread.start()


if os.getenv("WARM_UP_ON_START", "1").lower() in {"1", "true", "yes", "on"}:
    start_background_warmup()

@app.route('/api/health', methods=['GET'])
def health_check():
    """Health check endpoint"""
    return jsonify({"status": "healthy", "message": "Flask server is running"})

@app.route('/api/chat', methods=['POST'])
def chat():
    """Main chat endpoint that interfaces with your RAG pipeline"""
    try:
        data = request.get_json()
        
        if not data or 'message' not in data:
            return jsonify({"error": "No message provided"}), 400
        
        user_message = data['message'].strip()
        
        if not user_message:
            return jsonify({"error": "Empty message"}), 400
        
        # Call your RAG pipeline function
        response = return_response(user_message)
        
        return jsonify({
            "response": response,
            "status": "success"
        })
        
    except Exception as e:
        print(f"Error in chat endpoint: {str(e)}")
        return jsonify({
            "error": "An error occurred while processing your request",
            "details": str(e)
        }), 500

@app.route('/api/clear-history', methods=['POST'])
def clear_history():
    """Clear conversation history"""
    try:
        # Import the conversation history from your rag module
        from rag import CONVERSATION_HISTORY
        CONVERSATION_HISTORY.clear()
        
        return jsonify({
            "message": "Conversation history cleared",
            "status": "success"
        })
        
    except Exception as e:
        print(f"Error clearing history: {str(e)}")
        return jsonify({
            "error": "Could not clear conversation history",
            "details": str(e)
        }), 500

@app.errorhandler(404)
def not_found(error):
    return jsonify({"error": "Endpoint not found"}), 404

@app.errorhandler(500)
def internal_error(error):
    return jsonify({"error": "Internal server error"}), 500

if __name__ == '__main__':
    print("Starting Flask server...")
    print("Make sure rag.py is in the same directory")
    print("Server will run on http://localhost:5000")
    debug = os.getenv("FLASK_DEBUG", "0").lower() in {"1", "true", "yes", "on"}
    app.run(debug=debug, use_reloader=False, host='0.0.0.0', port=5000)
