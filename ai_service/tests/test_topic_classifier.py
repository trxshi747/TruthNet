"""
Tests pour models/topic_classifier.py
"""

import pytest
from models.topic_classifier import (
    classify_topic,
    analyze_batch,
    aggregate_topics,
    _get_pipeline,
    CANDIDATE_LABELS,
)


def test_get_pipeline_cached():
    """Vérifie que le pipeline est chargé en cache"""
    pipeline1 = _get_pipeline()
    pipeline2 = _get_pipeline()
    assert pipeline1 is pipeline2


def test_classify_topic(mock_topic_classifier):
    """Test classification de topic"""
    result = classify_topic("This is a text about technology and AI.")

    assert "label" in result
    assert "score" in result
    assert isinstance(result["label"], str)
    assert isinstance(result["score"], float)


def test_classify_topic_empty_text():
    """Test classification avec texte vide"""
    result = classify_topic("")

    assert result["label"] == "N/A"
    assert result["score"] == 0.0


def test_classify_topic_short_text():
    """Test classification avec texte très court"""
    result = classify_topic("AI")

    # Le résultat doit être valide
    assert "label" in result
    assert "score" in result


def test_analyze_batch(mock_topic_classifier):
    """Test classification en batch"""
    texts = ["Politics discussion", "Tech news", "Health update"]
    results = analyze_batch(texts)

    assert len(results) == 3
    for result in results:
        assert "label" in result
        assert "score" in result


def test_aggregate_topics():
    """Test agrégation des topics"""
    results = [
        {"label": "Technology", "score": 0.85},
        {"label": "Technology", "score": 0.75},
        {"label": "Health", "score": 0.90},
        {"label": "Politics", "score": 0.80},
    ]

    aggregate = aggregate_topics(results)

    assert "topic_counts" in aggregate
    assert "distribution_percent" in aggregate
    assert aggregate["topic_counts"]["Technology"] == 2
    assert aggregate["topic_counts"]["Health"] == 1
    assert aggregate["topic_counts"]["Politics"] == 1


def test_aggregate_topics_empty():
    """Test agrégation avec liste vide"""
    aggregate = aggregate_topics([])

    assert aggregate == {}


def test_candidate_labels():
    """Vérifie que les labels candidats sont définis"""
    assert "Politics" in CANDIDATE_LABELS
    assert "Technology" in CANDIDATE_LABELS
    assert "Health" in CANDIDATE_LABELS
    assert "Science" in CANDIDATE_LABELS
    assert len(CANDIDATE_LABELS) > 5