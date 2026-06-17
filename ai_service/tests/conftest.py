"""
Configuration des tests — Fixtures partagées
"""

import pytest
from fastapi.testclient import TestClient
from unittest.mock import AsyncMock, MagicMock, patch

# Importer l'application FastAPI
from main import app
from models import fact_check, sentiment, toxicity, topic_classifier


@pytest.fixture
def client():
    """Client de test FastAPI"""
    return TestClient(app)


@pytest.fixture
def mock_sentiment_pipeline():
    """Mock du pipeline de sentiment"""
    with patch('models.sentiment._get_pipeline') as mock:
        pipeline = MagicMock()
        pipeline.return_value = [
            {"label": "LABEL_2", "score": 0.95},
            {"label": "LABEL_1", "score": 0.03},
            {"label": "LABEL_0", "score": 0.02},
        ]
        mock.return_value = pipeline
        yield mock


@pytest.fixture
def mock_toxicity_pipeline():
    """Mock du pipeline de toxicité"""
    with patch('models.toxicity._get_pipeline') as mock:
        pipeline = MagicMock()
        pipeline.return_value = [
            {"label": "toxic", "score": 0.85},
            {"label": "severe_toxic", "score": 0.12},
            {"label": "obscene", "score": 0.05},
            {"label": "threat", "score": 0.01},
            {"label": "insult", "score": 0.10},
            {"label": "identity_hate", "score": 0.02},
        ]
        mock.return_value = pipeline
        yield mock


@pytest.fixture
def mock_topic_classifier():
    """Mock du classificateur de topics"""
    with patch('models.topic_classifier._get_pipeline') as mock:
        pipeline = MagicMock()
        pipeline.return_value = {
            "labels": ["Technology", "Science", "Business"],
            "scores": [0.85, 0.10, 0.05],
        }
        mock.return_value = pipeline
        yield mock


@pytest.fixture
def mock_gemini_model():
    """Mock du modèle Gemini pour fact_check"""
    with patch('models.fact_check.model') as mock_model:
        mock_response = MagicMock()
        mock_response.text = '''
        {
            "summary": "Claim is verified",
            "type": "claim",
            "truth_score": 0.85,
            "verdict": "Verified",
            "explanation": "The claim is supported by multiple sources",
            "sources": ["https://source1.com"],
            "is_publishable": true
        }
        '''
        mock_model.generate_content.return_value = mock_response
        yield mock_model


@pytest.fixture
def sample_text():
    """Texte de test pour les analyses"""
    return "This is a sample text for testing the AI models."


@pytest.fixture
def sample_texts():
    """Liste de textes de test"""
    return [
        "I love this product!",
        "This is terrible.",
        "The weather is okay today.",
        "You are stupid.",
        "Great job everyone!",
    ]