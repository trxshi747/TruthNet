"""
Tests pour models/toxicity.py
"""

import pytest
from models.toxicity import (
    analyze_toxicity,
    analyze_batch,
    aggregate_toxicity,
    _get_pipeline,
    _degree,
    _SEVERE_LABELS,
    _SEVERE_THRESHOLD,
)


def test_get_pipeline_cached():
    """Vérifie que le pipeline de toxicité est en cache"""
    pipeline1 = _get_pipeline()
    pipeline2 = _get_pipeline()
    assert pipeline1 is pipeline2


def test_analyze_toxicity_toxic(mock_toxicity_pipeline):
    """Test analyse toxicité avec contenu toxique"""
    result = analyze_toxicity("You are an idiot!")

    assert result["is_toxic"] == True
    assert result["toxic_score"] > 0.5
    assert "degree" in result
    assert "flags" in result
    assert "categories" in result


def test_analyze_toxicity_clean():
    """Test analyse toxicité avec contenu propre"""
    result = analyze_toxicity("Hello, how are you?")

    assert result["is_toxic"] == False


def test_analyze_toxicity_empty_text():
    """Test analyse toxicité avec texte vide"""
    result = analyze_toxicity("")

    assert result["is_toxic"] == False
    assert result["toxic_score"] == 0.0
    assert result["degree"] == "low"
    assert result["flags"] == {}


def test_degree_function():
    """Test de la fonction de degré"""
    assert _degree(0.85) == "extreme"
    assert _degree(0.60) == "high"
    assert _degree(0.35) == "moderate"
    assert _degree(0.10) == "low"


def test_severe_labels_presence():
    """Vérifie que les labels sévères sont définis"""
    assert "severe_toxic" in _SEVERE_LABELS
    assert "threat" in _SEVERE_LABELS
    assert "identity_hate" in _SEVERE_LABELS
    assert _SEVERE_THRESHOLD == 0.40


def test_analyze_batch_toxicity(mock_toxicity_pipeline):
    """Test analyse toxicité en batch"""
    texts = ["Bad!", "Good!", "Clean!"]
    results = analyze_batch(texts)

    assert len(results) == 3
    for result in results:
        assert "is_toxic" in result
        assert "toxic_score" in result
        assert "degree" in result


def test_aggregate_toxicity():
    """Test agrégation des résultats de toxicité"""
    results = [
        {"is_toxic": True, "toxic_score": 0.85, "degree": "high", "categories": ["toxic", "insult"]},
        {"is_toxic": False, "toxic_score": 0.10, "degree": "low", "categories": []},
        {"is_toxic": True, "toxic_score": 0.60, "degree": "moderate", "categories": ["toxic"]},
    ]

    aggregate = aggregate_toxicity(results)

    assert aggregate["total"] == 3
    assert aggregate["toxic_count"] == 2
    assert aggregate["clean_count"] == 1
    assert aggregate["toxic_rate"] == 2/3
    assert aggregate["degree_breakdown"]["low"] == 1
    assert aggregate["degree_breakdown"]["moderate"] == 1
    assert aggregate["degree_breakdown"]["high"] == 1


def test_aggregate_toxicity_empty():
    """Test agrégation avec liste vide"""
    aggregate = aggregate_toxicity([])

    assert aggregate["total"] == 0
    assert aggregate["toxic_count"] == 0
    assert aggregate["clean_count"] == 0
    assert aggregate["toxic_rate"] == 0.0


def test_toxicity_category_counts():
    """Test des comptages de catégories"""
    results = [
        {"is_toxic": True, "toxic_score": 0.8, "degree": "high", "categories": ["toxic", "insult"]},
        {"is_toxic": True, "toxic_score": 0.7, "degree": "high", "categories": ["toxic", "obscene"]},
        {"is_toxic": False, "toxic_score": 0.1, "degree": "low", "categories": []},
    ]

    aggregate = aggregate_toxicity(results)

    assert aggregate["category_counts"]["toxic"] == 2
    assert aggregate["category_counts"]["insult"] == 1
    assert aggregate["category_counts"]["obscene"] == 1