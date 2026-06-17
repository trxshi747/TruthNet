"""
Tests pour models/fact_check.py
"""

import pytest
from unittest.mock import patch, AsyncMock, MagicMock
from models.fact_check import verify_claim, model


@pytest.mark.asyncio
async def test_verify_claim_no_model():
    """Test vérification sans modèle configuré"""
    with patch('models.fact_check.model', None):
        result = await verify_claim("Test claim", None, False)

        assert result["success"] == False
        assert result["truth_score"] == 0.5
        assert result["explanation"] == "Service unavailable."


@pytest.mark.asyncio
async def test_verify_claim_short_text():
    """Test vérification avec texte trop court"""
    result = await verify_claim("Hi", None, False)

    assert result["success"] == False
    assert result["truth_score"] == 0.5
    assert result["message"] == "Text too short to verify without media."


@pytest.mark.asyncio
async def test_verify_claim_success(mock_gemini_model):
    """Test vérification réussie"""
    with patch('models.fact_check.model', mock_gemini_model):
        result = await verify_claim("This is a factual claim", None, False)

        assert result["success"] == True
        assert "truth_score" in result
        assert "verdict" in result
        assert "explanation" in result
        assert "sources" in result


@pytest.mark.asyncio
async def test_verify_claim_with_image(mock_gemini_model):
    """Test vérification avec image"""
    with patch('models.fact_check.model', mock_gemini_model):
        result = await verify_claim("Image description", "/uploads/image.jpg", False)

        assert result["success"] == True


@pytest.mark.asyncio
async def test_verify_claim_image_only():
    """Test vérification avec image uniquement"""
    with patch('models.fact_check.model') as mock_model:
        mock_response = MagicMock()
        mock_response.text = '''
        {
            "summary": "Image analysis complete",
            "type": "claim",
            "truth_score": 0.70,
            "verdict": "Verified",
            "explanation": "The image appears authentic",
            "sources": [],
            "is_publishable": true
        }
        '''
        mock_model.generate_content.return_value = mock_response

        result = await verify_claim("[IMAGE_ONLY_POST]", "/uploads/image.jpg", False)

        assert result["success"] == True


@pytest.mark.asyncio
async def test_verify_claim_gemini_error():
    """Test erreur Gemini"""
    with patch('models.fact_check.model') as mock_model:
        mock_model.generate_content.side_effect = Exception("API Error")

        result = await verify_claim("Test claim", None, False)

        assert result["success"] == False
        assert "message" in result


@pytest.mark.asyncio
async def test_verify_claim_invalid_json_response():
    """Test réponse JSON invalide de Gemini"""
    with patch('models.fact_check.model') as mock_model:
        mock_response = MagicMock()
        mock_response.text = "Invalid JSON response"
        mock_model.generate_content.return_value = mock_response

        result = await verify_claim("Test claim", None, False)

        assert result["success"] == False