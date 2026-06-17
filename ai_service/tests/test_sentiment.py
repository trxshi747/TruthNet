"""
Tests pour models/sentiment.py
"""

import pytest
from models.sentiment import (
    analyze_sentiment,
    analyze_batch,
    aggregate_sentiment,
    _get_pipeline,
    _LABEL_MAP,
)


def test_get_pipeline_cached():
    """Vérifie que le pipeline est chargé en cache"""
    pipeline1 = _get_pipeline()
    pipeline2 = _get_pipeline()
    assert pipeline1 is pipeline2


def test_analyze_sentiment_positive(mock_sentiment_pipeline):
    """Test analyse sentiment positif"""
    result = analyze_sentiment("I love this!")

    assert result["label"] == "positive"
    assert result["confidence"] > 0
    assert "scores" in result
    assert "negativity_degree" in result
    assert "positivity_degree" in result


def test_analyze_sentiment_empty_text():
    """Test analyse avec texte vide"""
    result = analyze_sentiment("")

    assert result["label"] == "neutral"
    assert result["confidence"] == 1.0
    assert result["scores"]["neutral"] == 1.0


def test_analyze_sentiment_short_text():
    """Test analyse avec texte très court"""
    result = analyze_sentiment("Ok")

    assert result["label"] in ["positive", "neutral", "negative"]
    assert "scores" in result


def test_analyze_batch(mock_sentiment_pipeline):
    """Test analyse en batch"""
    texts = ["Great!", "Bad!", "Okay."]
    results = analyze_batch(texts)

    assert len(results) == 3
    for result in results:
        assert "label" in result
        assert "scores" in result


def test_aggregate_sentiment():
    """Test agrégation des résultats de sentiment"""
    results = [
        {"label": "positive", "scores": {"positive": 0.9, "neutral": 0.1, "negative": 0.0}, "negativity_degree": "low"},
        {"label": "negative", "scores": {"positive": 0.1, "neutral": 0.2, "negative": 0.7}, "negativity_degree": "high"},
        {"label": "neutral", "scores": {"positive": 0.3, "neutral": 0.5, "negative": 0.2}, "negativity_degree": "low"},
    ]

    aggregate = aggregate_sentiment(results)

    assert aggregate["total"] == 3
    assert aggregate["positive"] == 1
    assert aggregate["negative"] == 1
    assert aggregate["neutral"] == 1
    assert "negativity_breakdown" in aggregate
    assert "avg_scores" in aggregate


def test_aggregate_sentiment_empty():
    """Test agrégation avec liste vide"""
    aggregate = aggregate_sentiment([])

    assert aggregate["total"] == 0
    assert aggregate["positive"] == 0
    assert aggregate["negative"] == 0
    assert aggregate["neutral"] == 0


def test_sentiment_degree_thresholds():
    """Test des seuils de degré de négativité"""
    from models.sentiment import _negativity_degree

    assert _negativity_degree(0.9) == "extreme"
    assert _negativity_degree(0.7) == "high"
    assert _negativity_degree(0.5) == "moderate"
    assert _negativity_degree(0.2) == "low"


def test_label_mapping():
    """Test du mapping des labels"""
    assert _LABEL_MAP["LABEL_0"] == "negative"
    assert _LABEL_MAP["LABEL_1"] == "neutral"
    assert _LABEL_MAP["LABEL_2"] == "positive"