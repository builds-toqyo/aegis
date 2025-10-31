"""
Data loading and preprocessing utilities
"""

import pandas as pd
import numpy as np
from typing import Dict, List, Tuple


def load_historical_data(strategy: str, days: int = 365) -> pd.DataFrame:
    """
    Load historical data for a strategy
    
    Args:
        strategy: Strategy name (e.g., 'aave', 'lido', 'delta')
        days: Number of days of historical data
    
    Returns:
        DataFrame with historical metrics
    """
    # TODO: Implement actual data loading from database or API
    # For now, generate synthetic data
    
    dates = pd.date_range(end=pd.Timestamp.now(), periods=days, freq='D')
    
    data = pd.DataFrame({
        'date': dates,
        'apy': np.random.uniform(0.03, 0.08, days),
        'tvl': np.random.uniform(1e6, 1e9, days),
        'volatility': np.random.uniform(0.05, 0.15, days),
        'gas_price': np.random.uniform(10, 100, days),
        'eth_price': np.random.uniform(1500, 2500, days),
    })
    
    return data


def create_features(df: pd.DataFrame) -> pd.DataFrame:
    """
    Create features for ML model
    
    Args:
        df: Raw data DataFrame
    
    Returns:
        DataFrame with engineered features
    """
    df = df.copy()
    
    # Rolling statistics
    df['apy_ma_7'] = df['apy'].rolling(window=7).mean()
    df['apy_ma_30'] = df['apy'].rolling(window=30).mean()
    df['volatility_ma_7'] = df['volatility'].rolling(window=7).mean()
    
    # Momentum features
    df['apy_momentum'] = df['apy'].pct_change(periods=7)
    df['tvl_momentum'] = df['tvl'].pct_change(periods=7)
    
    # Volatility features
    df['apy_std_7'] = df['apy'].rolling(window=7).std()
    df['apy_std_30'] = df['apy'].rolling(window=30).std()
    
    # Drop NaN values
    df = df.dropna()
    
    return df


def prepare_sequences(
    data: np.ndarray,
    sequence_length: int = 7,
    target_columns: List[int] = [0, 1]
) -> Tuple[np.ndarray, np.ndarray]:
    """
    Prepare sequences for LSTM training
    
    Args:
        data: Input data array
        sequence_length: Length of input sequences
        target_columns: Indices of target columns
    
    Returns:
        Tuple of (X, y) arrays
    """
    X, y = [], []
    
    for i in range(len(data) - sequence_length):
        X.append(data[i:i + sequence_length])
        y.append(data[i + sequence_length, target_columns])
    
    return np.array(X), np.array(y)


def normalize_data(
    train_data: np.ndarray,
    test_data: np.ndarray = None
) -> Tuple[np.ndarray, np.ndarray, object]:
    """
    Normalize data using StandardScaler
    
    Args:
        train_data: Training data
        test_data: Test data (optional)
    
    Returns:
        Tuple of (normalized_train, normalized_test, scaler)
    """
    from sklearn.preprocessing import StandardScaler
    
    scaler = StandardScaler()
    train_normalized = scaler.fit_transform(train_data)
    
    test_normalized = None
    if test_data is not None:
        test_normalized = scaler.transform(test_data)
    
    return train_normalized, test_normalized, scaler
