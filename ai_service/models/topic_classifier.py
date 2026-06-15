"""
Topic Classification Module — HuggingFace Zero-Shot
Uses facebook/bart-large-mnli
"""

import logging
from functools import lru_cache
from transformers import pipeline

logger = logging.getLogger(__name__)

# ─── Model loading ────────────────────────────────────────────────────────────

@lru_cache(maxsize=1)
def _get_pipeline():
    """
    Loads the zero-shot classification pipeline from HuggingFace.
    This is cached so it only runs once on startup.
    """
    logger.info("⚡ Loading topic classification model (zero-shot)...")
    # Use the correct pipeline for this model type
    return pipeline("zero-shot-classification", model="facebook/bart-large-mnli")

# ─── Classification logic ─────────────────────────────────────────────────────

# Define the candidate labels for our topic universe
CANDIDATE_LABELS = [
    "Politics", "Technology", "Health", "Business", "Sports", 
    "Entertainment", "Science", "World News", "Environment", "Education"
]

def classify_topic(text: str) -> dict:
    """
    Classifies a text into one of the CANDIDATE_LABELS using a zero-shot model.
    """
    if not text or not text.strip():
        return {"label": "N/A", "score": 0.0}

    classifier = _get_pipeline()
    
    # Zero-shot pipeline requires the text and the candidate labels
    result = classifier(text, CANDIDATE_LABELS)
    
    # The output is a dict with sequence, labels, and scores.
    # We return the top label and its score.
    top_label = result['labels'][0]
    top_score = result['scores'][0]

    return {
        "label": top_label,
        "score": round(top_score, 4),
    }

def analyze_batch(texts: list[str]) -> list[dict]:
    """
    Classifies a batch of texts.
    """
    classifier = _get_pipeline()
    
    # The pipeline can handle a list of texts efficiently
    results = classifier(texts, CANDIDATE_LABELS)
    
    # Ensure results is a list even for a single text input
    if not isinstance(results, list):
        results = [results]

    return [
        {
            "label": res['labels'][0],
            "score": round(res['scores'][0], 4)
        } 
        for res in results
    ]

def aggregate_topics(results: list[dict]) -> dict:
    """
    Aggregates topic analysis results from a batch.
    """
    if not results:
        return {}

    topic_counts = {label: 0 for label in CANDIDATE_LABELS}
    total = len(results)

    for res in results:
        label = res.get("label")
        if label in topic_counts:
            topic_counts[label] += 1
            
    # Also provide the distribution as a percentage
    distribution = {
        label: round((count / total) * 100, 2) 
        for label, count in topic_counts.items()
    }

    return {
        "topic_counts": topic_counts,
        "distribution_percent": distribution
    }

# Pre-warm the model on import
try:
    _get_pipeline()
    logger.info("✅ Topic classification model ready.")
except Exception as e:
    logger.error(f"Failed to load topic classification model: {e}")
    # This will prevent the app from starting if the model is broken, which is good.

