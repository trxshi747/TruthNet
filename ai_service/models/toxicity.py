"""
Toxicity Analysis — martin-ha/toxic-comment-model
Multi-label classifier:
  toxic | severe_toxic | obscene | threat | insult | identity_hate
"""

from transformers import pipeline, AutoTokenizer, AutoModelForSequenceClassification
from functools import lru_cache
import torch
import logging

logger = logging.getLogger(__name__)

_MODEL_ID = "martin-ha/toxic-comment-model"

# Degree thresholds
_DEGREE_THRESHOLDS = [
    (0.80, "extreme"),
    (0.55, "high"),
    (0.30, "moderate"),
    (0.00, "low"),
]

# Which labels indicate severe concern (any one of these above threshold → flag)
_SEVERE_LABELS = {"severe_toxic", "threat", "identity_hate"}
_SEVERE_THRESHOLD = 0.40


@lru_cache(maxsize=1)
def _get_pipeline():
    logger.info(f"Loading toxicity model: {_MODEL_ID}")
    tokenizer = AutoTokenizer.from_pretrained(_MODEL_ID)
    model = AutoModelForSequenceClassification.from_pretrained(_MODEL_ID)
    return pipeline(
        "text-classification",
        model=model,
        tokenizer=tokenizer,
        top_k=None,
        device="cpu",     # explicit CPU — no CUDA needed
        truncation=True,
        max_length=512,
    )


def _degree(score: float) -> str:
    for threshold, label in _DEGREE_THRESHOLDS:
        if score >= threshold:
            return label
    return "low"


def format_single_raw_result(raw: list[dict]) -> dict:
    """Helper to format HuggingFace raw multi-label output."""
    # Build scores dict
    scores: dict[str, float] = {}
    for item in raw:
        label = item["label"].lower().replace("-", "_")
        scores[label] = round(item["score"], 4)

    # Main toxicity score
    toxic_score = scores.get("toxic", 0.0)
    is_toxic    = toxic_score > 0.50

    # Flags dict (exclude main "toxic" key)
    flags = {k: v for k, v in scores.items() if k != "toxic"}

    # Severe flag check
    has_severe = any(
        flags.get(label, 0.0) >= _SEVERE_THRESHOLD
        for label in _SEVERE_LABELS
    )

    # Active categories (any label scoring above moderate threshold)
    active_threshold = 0.30
    categories = [
        label for label, score in {**scores}.items()
        if score >= active_threshold
    ]

    return {
        "is_toxic":        is_toxic,
        "toxic_score":     toxic_score,
        "degree":          _degree(toxic_score),
        "flags":           flags,
        "has_severe_flag": has_severe,
        "categories":      categories,
    }


def analyze_toxicity(text: str) -> dict:
    """
    Analyse toxicity of a single text.
    """
    clf = _get_pipeline()

    if not text or not text.strip():
        return _clean_result()

    raw: list[dict] = clf(text[:512])[0]
    return format_single_raw_result(raw)


def analyze_batch(texts: list[str]) -> list[dict]:
    """Analyse plusieurs textes de manière vectorisée et performante."""
    clf = _get_pipeline()
    if not texts:
        return []
        
    # Tronquer chaque texte à 512 caractères proprement avant l'envoi
    cleaned_texts = [t[:512] if t else "" for t in texts]
    
    # Envoi direct de la liste au pipeline (HuggingFace traite cela en batch matriciel au niveau CPU/GPU)
    raw_results = clf(cleaned_texts)
    
    # Il ne te reste plus qu'à formater la liste de résultats reçue
    formatted_results = []
    for raw in raw_results:
        formatted_results.append(format_single_raw_result(raw))
        
    return formatted_results

def aggregate_toxicity(results: list[dict]) -> dict:
    """
    Aggregate per-comment toxicity into platform-level stats.

    Returns:
    {
        "total":          int,
        "toxic_count":    int,
        "clean_count":    int,
        "toxic_rate":     float,   # 0.0-1.0
        "avg_toxic_score": float,
        "degree_breakdown": { "low": int, "moderate": int, "high": int, "extreme": int },
        "severe_flag_count": int,
        "category_counts": { "severe_toxic": int, "obscene": int, ... }
    }
    """
    if not results:
        return {
            "total": 0, "toxic_count": 0, "clean_count": 0,
            "toxic_rate": 0.0, "avg_toxic_score": 0.0,
            "degree_breakdown": {"low": 0, "moderate": 0, "high": 0, "extreme": 0},
            "severe_flag_count": 0,
            "category_counts": {},
        }

    n            = len(results)
    toxic_count  = sum(1 for r in results if r["is_toxic"])
    score_sum    = sum(r["toxic_score"] for r in results)
    severe_count = sum(1 for r in results if r["has_severe_flag"])

    degree_breakdown = {"low": 0, "moderate": 0, "high": 0, "extreme": 0}
    category_counts: dict[str, int] = {}

    for r in results:
        degree_breakdown[r["degree"]] += 1
        for cat in r.get("categories", []):
            category_counts[cat] = category_counts.get(cat, 0) + 1

    return {
        "total":            n,
        "toxic_count":      toxic_count,
        "clean_count":      n - toxic_count,
        "toxic_rate":       round(toxic_count / n, 4),
        "avg_toxic_score":  round(score_sum / n, 4),
        "degree_breakdown": degree_breakdown,
        "severe_flag_count": severe_count,
        "category_counts":  category_counts,
    }


def _clean_result() -> dict:
    return {
        "is_toxic":        False,
        "toxic_score":     0.0,
        "degree":          "low",
        "flags":           {},
        "has_severe_flag": False,
        "categories":      [],
    }
