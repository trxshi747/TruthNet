"""
Tests pour les routes FastAPI (routes/analyze.py)
"""

import pytest
from unittest.mock import patch


class TestAnalyzeRoutes:

    def test_health_endpoint(self, client):
        """Test endpoint /health"""
        response = client.get("/health")
        assert response.status_code == 200
        assert response.json()["status"] == "ok"
        assert response.json()["service"] == "TruthNet AI"

    def test_analyze_sentiment_success(self, client, mock_sentiment_pipeline):
        """Test analyse sentiment réussie"""
        response = client.post("/analyze/sentiment", json={
            "text": "I love this product!"
        })

        assert response.status_code == 200
        data = response.json()
        assert data["success"] == True
        assert "result" in data
        assert data["result"]["label"] == "positive"

    def test_analyze_sentiment_empty_text(self, client):
        """Test analyse sentiment avec texte vide"""
        response = client.post("/analyze/sentiment", json={
            "text": ""
        })

        # Devrait retourner neutral
        assert response.status_code == 200
        data = response.json()
        assert data["success"] == True
        assert data["result"]["label"] == "neutral"

    def test_analyze_toxicity_success(self, client, mock_toxicity_pipeline):
        """Test analyse toxicité réussie"""
        response = client.post("/analyze/toxicity", json={
            "text": "You are stupid!"
        })

        assert response.status_code == 200
        data = response.json()
        assert data["success"] == True
        assert "result" in data

    def test_analyze_full_success(self, client, mock_sentiment_pipeline, mock_toxicity_pipeline):
        """Test analyse complète réussie"""
        response = client.post("/analyze/full", json={
            "text": "This is a test."
        })

        assert response.status_code == 200
        data = response.json()
        assert data["success"] == True
        assert "sentiment" in data
        assert "toxicity" in data

    def test_analyze_topic_success(self, client, mock_topic_classifier):
        """Test analyse topic réussie"""
        response = client.post("/analyze/topic", json={
            "text": "This is about technology."
        })

        assert response.status_code == 200
        data = response.json()
        assert data["success"] == True
        assert "result" in data

    def test_analyze_verify_success(self, client):
        """Test vérification réussie"""
        with patch('models.fact_check.verify_claim') as mock_verify:
            mock_verify.return_value = {
                "success": True,
                "truth_score": 0.85,
                "verdict": "Verified",
                "explanation": "Claim is verified",
                "sources": []
            }

            response = client.post("/analyze/verify", json={
                "text": "The Earth is round"
            })

            assert response.status_code == 200
            data = response.json()
            assert data["success"] == True

    def test_batch_sentiment(self, client, mock_sentiment_pipeline):
        """Test batch sentiment"""
        response = client.post("/analyze/batch/sentiment", json={
            "texts": ["Great!", "Bad!", "Okay."]
        })

        assert response.status_code == 200
        data = response.json()
        assert data["success"] == True
        assert len(data["results"]) == 3
        assert "aggregate" in data

    def test_batch_toxicity(self, client, mock_toxicity_pipeline):
        """Test batch toxicity"""
        response = client.post("/analyze/batch/toxicity", json={
            "texts": ["Bad!", "Good!", "Clean!"]
        })

        assert response.status_code == 200
        data = response.json()
        assert data["success"] == True
        assert len(data["results"]) == 3
        assert "aggregate" in data

    def test_batch_comments(self, client, mock_sentiment_pipeline, mock_toxicity_pipeline):
        """Test batch comments"""
        response = client.post("/analyze/batch/comments", json={
            "comments": [
                {"id": "1", "text": "Great post!"},
                {"id": "2", "text": "Terrible!"},
                {"id": "3", "text": "Interesting."}
            ]
        })

        assert response.status_code == 200
        data = response.json()
        assert data["success"] == True
        assert len(data["per_comment"]) == 3
        assert "aggregate" in data

    def test_dashboard_summary(self, client, mock_sentiment_pipeline, mock_toxicity_pipeline):
        """Test dashboard summary"""
        response = client.post("/analyze/dashboard-summary", json={
            "texts": ["Great!", "Bad!", "Okay."]
        })

        assert response.status_code == 200
        data = response.json()
        assert data["success"] == True
        assert "sentiment" in data
        assert "toxicity" in data
        assert "total" in data

    def test_analyze_sentiment_invalid_text(self, client):
        """Test sentiment avec texte invalide"""
        response = client.post("/analyze/sentiment", json={
            "text": "a" * 6000  # trop long
        })

        # Le modèle devrait tronquer automatiquement, donc pas d'erreur
        assert response.status_code == 200

    def test_analyze_batch_empty(self, client):
        """Test batch avec liste vide"""
        response = client.post("/analyze/batch/sentiment", json={
            "texts": []
        })

        # Va retourner un résultat vide
        assert response.status_code == 200
        data = response.json()
        assert data["success"] == True
        assert len(data["results"]) == 0