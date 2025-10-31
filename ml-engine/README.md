# Aegis Yield ML Engine

Python-based machine learning engine for yield prediction and portfolio optimization.

## 📁 Directory Structure

```
ml-engine/
├── data/                # Data storage
│   ├── raw/            # Raw historical data
│   └── processed/      # Processed training data
├── models/             # Trained model artifacts
│   ├── lstm_v1.pth     # PyTorch LSTM model
│   └── scaler.joblib   # Feature scaler
├── scripts/            # Training and evaluation scripts
│   ├── train.py
│   ├── evaluate.py
│   └── predict.py
├── api/                # ML API service
│   ├── ml_service.py
│   └── schemas.py
├── src/                # Source code
│   ├── models/
│   ├── preprocessing/
│   └── utils/
└── requirements.txt
```

## 🚀 Getting Started

### Prerequisites

- Python 3.10 or higher
- pip or conda

### Installation

```bash
# Create virtual environment
python -m venv venv
source venv/bin/activate  # On Windows: venv\Scripts\activate

# Install dependencies
pip install -r requirements.txt
```

### Training

```bash
# Train LSTM model
python scripts/train.py --epochs 100 --batch-size 32

# Evaluate model
python scripts/evaluate.py --model models/lstm_v1.pth
```

### Running the API

```bash
# Start Flask API
python api/ml_service.py

# Or use FastAPI with uvicorn
uvicorn api.ml_service:app --reload --port 5000
```

## 🧠 Model Architecture

### LSTM Prediction Model

The model predicts future APY and volatility for each strategy:

**Input Features:**
- Historical APY (7-day window)
- Protocol TVL
- Market volatility
- Gas prices
- External market indicators

**Output:**
- Predicted APY (next 7 days)
- Predicted volatility
- Confidence intervals

**Architecture:**
```
Input Layer (n_features)
    ↓
LSTM Layer (128 units)
    ↓
Dropout (0.2)
    ↓
LSTM Layer (64 units)
    ↓
Dropout (0.2)
    ↓
Dense Layer (32 units, ReLU)
    ↓
Output Layer (2 units: APY, Volatility)
```

## 📊 Data Pipeline

1. **Data Collection** - Fetch historical data from blockchain and APIs
2. **Preprocessing** - Clean, normalize, and create features
3. **Training** - Train LSTM model on historical data
4. **Validation** - Validate on held-out test set
5. **Deployment** - Save model and serve via API

## 🔬 Features

- **Time Series Forecasting** - LSTM-based APY prediction
- **Risk Modeling** - Volatility and drawdown estimation
- **Feature Engineering** - Technical indicators and market signals
- **Model Versioning** - Track and compare model versions
- **API Service** - REST API for predictions

## 📝 API Endpoints

### POST /predict
Predict future APY and volatility for strategies

**Request:**
```json
{
  "strategies": ["aave", "lido", "delta"],
  "horizon_days": 7
}
```

**Response:**
```json
{
  "predictions": {
    "aave": {"apy": 0.052, "volatility": 0.08},
    "lido": {"apy": 0.041, "volatility": 0.06},
    "delta": {"apy": 0.085, "volatility": 0.12}
  }
}
```

## 🧪 Testing

```bash
# Run all tests
pytest

# Run with coverage
pytest --cov=src --cov-report=html
```

## 📝 License

MIT License
