"""
Training script for LSTM yield prediction model
"""

import argparse
import os
import sys
from pathlib import Path

import numpy as np
import pandas as pd
import torch
import torch.nn as nn
from torch.utils.data import DataLoader, TensorDataset
from sklearn.preprocessing import StandardScaler
import joblib

# Add parent directory to path
sys.path.append(str(Path(__file__).parent.parent))

from src.models.lstm_model import LSTMPredictor
from src.preprocessing.data_loader import load_historical_data
from src.utils.metrics import calculate_metrics


def parse_args():
    parser = argparse.ArgumentParser(description='Train LSTM model')
    parser.add_argument('--epochs', type=int, default=100, help='Number of epochs')
    parser.add_argument('--batch-size', type=int, default=32, help='Batch size')
    parser.add_argument('--learning-rate', type=float, default=0.001, help='Learning rate')
    parser.add_argument('--hidden-size', type=int, default=128, help='LSTM hidden size')
    parser.add_argument('--num-layers', type=int, default=2, help='Number of LSTM layers')
    parser.add_argument('--sequence-length', type=int, default=7, help='Sequence length')
    parser.add_argument('--output-dir', type=str, default='models', help='Output directory')
    return parser.parse_args()


def prepare_data(data, sequence_length=7):
    """Prepare sequences for LSTM training"""
    X, y = [], []
    
    for i in range(len(data) - sequence_length):
        X.append(data[i:i + sequence_length])
        y.append(data[i + sequence_length])
    
    return np.array(X), np.array(y)


def train_model(args):
    print("Loading historical data...")
    # TODO: Implement actual data loading
    # For now, generate synthetic data
    n_samples = 1000
    n_features = 10
    data = np.random.randn(n_samples, n_features)
    
    # Prepare sequences
    X, y = prepare_data(data, args.sequence_length)
    
    # Split train/test
    split_idx = int(0.8 * len(X))
    X_train, X_test = X[:split_idx], X[split_idx:]
    y_train, y_test = y[:split_idx], y[split_idx:]
    
    # Normalize features
    scaler = StandardScaler()
    X_train_scaled = scaler.fit_transform(X_train.reshape(-1, n_features)).reshape(X_train.shape)
    X_test_scaled = scaler.transform(X_test.reshape(-1, n_features)).reshape(X_test.shape)
    
    # Convert to tensors
    X_train_tensor = torch.FloatTensor(X_train_scaled)
    y_train_tensor = torch.FloatTensor(y_train)
    X_test_tensor = torch.FloatTensor(X_test_scaled)
    y_test_tensor = torch.FloatTensor(y_test)
    
    # Create data loaders
    train_dataset = TensorDataset(X_train_tensor, y_train_tensor)
    train_loader = DataLoader(train_dataset, batch_size=args.batch_size, shuffle=True)
    
    # Initialize model
    device = torch.device('cuda' if torch.cuda.is_available() else 'cpu')
    model = LSTMPredictor(
        input_size=n_features,
        hidden_size=args.hidden_size,
        num_layers=args.num_layers,
        output_size=n_features
    ).to(device)
    
    # Loss and optimizer
    criterion = nn.MSELoss()
    optimizer = torch.optim.Adam(model.parameters(), lr=args.learning_rate)
    
    # Training loop
    print(f"Training on {device}...")
    for epoch in range(args.epochs):
        model.train()
        total_loss = 0
        
        for batch_X, batch_y in train_loader:
            batch_X, batch_y = batch_X.to(device), batch_y.to(device)
            
            # Forward pass
            outputs = model(batch_X)
            loss = criterion(outputs, batch_y)
            
            # Backward pass
            optimizer.zero_grad()
            loss.backward()
            optimizer.step()
            
            total_loss += loss.item()
        
        avg_loss = total_loss / len(train_loader)
        
        if (epoch + 1) % 10 == 0:
            print(f'Epoch [{epoch+1}/{args.epochs}], Loss: {avg_loss:.4f}')
    
    # Evaluate
    model.eval()
    with torch.no_grad():
        test_outputs = model(X_test_tensor.to(device))
        test_loss = criterion(test_outputs, y_test_tensor.to(device))
        print(f'Test Loss: {test_loss.item():.4f}')
    
    # Save model and scaler
    os.makedirs(args.output_dir, exist_ok=True)
    model_path = os.path.join(args.output_dir, 'lstm_v1.pth')
    scaler_path = os.path.join(args.output_dir, 'scaler.joblib')
    
    torch.save(model.state_dict(), model_path)
    joblib.dump(scaler, scaler_path)
    
    print(f"Model saved to {model_path}")
    print(f"Scaler saved to {scaler_path}")


if __name__ == '__main__':
    args = parse_args()
    train_model(args)
