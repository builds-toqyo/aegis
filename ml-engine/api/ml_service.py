"""
ML API service for serving predictions
"""

import os
import sys
from pathlib import Path
from typing import List, Dict

import torch
import joblib
import numpy as np
from flask import Flask, request, jsonify
from flask_cors import CORS

# Add parent directory to path
sys.path.append(str(Path(__file__).parent.parent))

from src.models.lstm_model import LSTMPredictor

app = Flask(__name__)
CORS(app)

# Global model and scaler
model = None
scaler = None
device = torch.device('cuda' if torch.cuda.is_available() else 'cpu')


def load_model():
    """Load trained model and scaler"""
    global model, scaler
    
    model_path = os.getenv('ML_MODEL_PATH', 'models/lstm_v1.pth')
    scaler_path = os.path.join(os.path.dirname(model_path), 'scaler.joblib')
    
    # Initialize model
    model = LSTMPredictor(
        input_size=10,  # TODO: Load from config
        hidden_size=128,
        num_layers=2,
        output_size=2  # APY and volatility
    ).to(device)
    
    # Load weights if available
    if os.path.exists(model_path):
        model.load_state_dict(torch.load(model_path, map_location=device))
        model.eval()
        print(f"Model loaded from {model_path}")
    else:
        print("Warning: Model file not found, using untrained model")
    
    # Load scaler if available
    if os.path.exists(scaler_path):
        scaler = joblib.load(scaler_path)
        print(f"Scaler loaded from {scaler_path}")
    else:
        print("Warning: Scaler file not found")


@app.route('/health', methods=['GET'])
def health_check():
    """Health check endpoint"""
    return jsonify({
        'status': 'healthy',
        'model_loaded': model is not None,
        'device': str(device)
    })


@app.route('/predict', methods=['POST'])
def predict():
    """
    Predict APY and volatility for strategies
    
    Request body:
    {
        "strategies": ["aave", "lido", "delta"],
        "horizon_days": 7,
        "features": {...}  # Optional historical features
    }
    """
    try:
        data = request.get_json()
        strategies = data.get('strategies', [])
        horizon_days = data.get('horizon_days', 7)
        
        if not strategies:
            return jsonify({'error': 'No strategies provided'}), 400
        
        # TODO: Fetch actual historical data for each strategy
        # For now, return mock predictions
        predictions = {}
        
        for strategy in strategies:
            # Generate mock prediction
            # In production, this would use the actual model
            if strategy == 'aave':
                apy, volatility = 0.052, 0.08
            elif strategy == 'lido':
                apy, volatility = 0.041, 0.06
            elif strategy == 'delta':
                apy, volatility = 0.085, 0.12
            else:
                apy, volatility = 0.05, 0.10
            
            predictions[strategy] = {
                'apy': apy,
                'volatility': volatility,
                'confidence': 0.85,
                'horizon_days': horizon_days
            }
        
        return jsonify({
            'predictions': predictions,
            'timestamp': str(np.datetime64('now'))
        })
    
    except Exception as e:
        return jsonify({'error': str(e)}), 500


@app.route('/retrain', methods=['POST'])
def retrain():
    """Trigger model retraining"""
    # TODO: Implement retraining logic
    return jsonify({
        'status': 'retraining_started',
        'message': 'Model retraining has been queued'
    })


@app.route('/model/info', methods=['GET'])
def model_info():
    """Get model information"""
    return jsonify({
        'model_type': 'LSTM',
        'input_size': 10,
        'hidden_size': 128,
        'num_layers': 2,
        'output_size': 2,
        'device': str(device),
        'parameters': sum(p.numel() for p in model.parameters()) if model else 0
    })


if __name__ == '__main__':
    # Load model on startup
    load_model()
    
    # Start server
    port = int(os.getenv('ML_API_PORT', 5000))
    debug = os.getenv('DEBUG', 'false').lower() == 'true'
    
    print(f"Starting ML API service on port {port}...")
    app.run(host='0.0.0.0', port=port, debug=debug)
