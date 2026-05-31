"""
Sentiment Analysis — cardiffnlp/twitter-roberta-base-sentiment-latest
Labels : LABEL_0 = Negative | LABEL_1 = Neutral | LABEL_2 = Positive
"""

from transformers import pipeline, AutoTokenizer, AutoModelForSequenceClassification
from functools import lru_cache
import torch
import logging

logger = logging.getLogger(__name__)

# ── Model ID ──────────────────────────────────────────────────────────────────
_MODEL_ID = "cardiffnlp/twitter-roberta-base-sentiment-latest"

# Label mapping from model output → human-readable
_LABEL_MAP = {
    "LABEL_0": "negative",
    "LABEL_1": "neutral",
    "LABEL_2": "positive",
    # Some versions of the model use explicit names
    "negative": "negative",
    "neutral":  "neutral",
    "positive": "positive",
}

# Degree thresholds for negativity severity
_NEGATIVITY_DEGREE = [
    (0.85, "extreme"),
    (0.65, "high"),
    (0.40, "moderate"),
    (0.00, "low"),
]


@lru_cache(maxsize=1)
def _get_pipeline():
    """Load model once and cache it in memory."""
    logger.info(f"Loading sentiment model: {_MODEL_ID}")
    tokenizer = AutoTokenizer.from_pretrained(_MODEL_ID)
    model = AutoModelForSequenceClassification.from_pretrained(_MODEL_ID)
    return pipeline(
        "sentiment-analysis",
        model=model,
        tokenizer=tokenizer,
        top_k=None,
        device="cpu",     # explicit CPU — no CUDA needed
        truncation=True,
        max_length=512,
    )


def _negativity_degree(score: float) -> str:
    for threshold, label in _NEGATIVITY_DEGREE:
        if score >= threshold:
            return label
    return "low"


def analyze_sentiment(text: str) -> dict:
    """
    Analyse the sentiment of a single text.

    Returns:
    {
        "label":              "positive" | "neutral" | "negative",
        "confidence":         0.0-1.0,
        "scores": {
            "positive": 0.0-1.0,
            "neutral":  0.0-1.0,
            "negative": 0.0-1.0,
        },
        "negativity_degree":  "low" | "moderate" | "high" | "extreme",
        "positivity_degree":  "low" | "moderate" | "high" | "extreme",
    }
    """
    clf = _get_pipeline()

    if not text or not text.strip():
        return _neutral_result()

    # Run inference — returns list of {label, score} for all classes
    raw: list[dict] = clf(text[:512])[0]

    # Normalise labels
    scores = {}
    for item in raw:
        mapped = _LABEL_MAP.get(item["label"], item["label"])
        scores[mapped] = round(item["score"], 4)

    # Ensure all keys present
    for key in ("positive", "neutral", "negative"):
        scores.setdefault(key, 0.0)

    # Dominant label
    dominant = max(scores, key=lambda k: scores[k])
    confidence = scores[dominant]

    return {
        "label":             dominant,
        "confidence":        round(confidence, 4),
        "scores":            scores,
        "negativity_degree": _negativity_degree(scores["negative"]),
        "positivity_degree": _negativity_degree(scores["positive"]),
    }


def analyze_batch(texts: list[str]) -> list[dict]:
    """Analyse multiple texts efficiently in one batch."""
    return [analyze_sentiment(t) for t in texts]


def aggregate_sentiment(results: list[dict]) -> dict:
    """
    Aggregate a list of per-comment results into platform-level stats.

    Returns:
    {
        "positive": int,
        "neutral":  int,
        "negative": int,
        "total":    int,
        "avg_scores": { "positive": float, "neutral": float, "negative": float },
        "negativity_breakdown": { "low": int, "moderate": int, "high": int, "extreme": int }
    }
    """
    if not results:
        return {
            "positive": 0, "neutral": 0, "negative": 0, "total": 0,
            "avg_scores": {"positive": 0.0, "neutral": 0.0, "negative": 0.0},
            "negativity_breakdown": {"low": 0, "moderate": 0, "high": 0, "extreme": 0},
        }

    counts     = {"positive": 0, "neutral": 0, "negative": 0}
    sum_scores = {"positive": 0.0, "neutral": 0.0, "negative": 0.0}
    neg_breakdown = {"low": 0, "moderate": 0, "high": 0, "extreme": 0}

    for r in results:
        counts[r["label"]] += 1
        for k in sum_scores:
            sum_scores[k] += r["scores"].get(k, 0.0)
        neg_breakdown[r["negativity_degree"]] += 1

    n = len(results)
    return {
        **counts,
        "total": n,
        "avg_scores": {k: round(v / n, 4) for k, v in sum_scores.items()},
        "negativity_breakdown": neg_breakdown,
    }


def _neutral_result() -> dict:
    return {
        "label":             "neutral",
        "confidence":        1.0,
        "scores":            {"positive": 0.0, "neutral": 1.0, "negative": 0.0},
        "negativity_degree": "low",
        "positivity_degree": "low",
    }