from transformers import pipeline
from functools import lru_cache
import logging

logger = logging.getLogger(**name**)

_MODEL_ID = "MoritzLaurer/mDeBERTa-v3-base-mnli-xnli"

TOPICS = [
"politics",
"sports",
"technology",
"science",
"health",
"business",
"education",
"entertainment",
"gaming",
"religion",
]

@lru_cache(maxsize=1)
def _get_pipeline():
    logger.info(f"Loading topic classifier: {_MODEL_ID}")

    return pipeline(
        "zero-shot-classification",
        model=_MODEL_ID,
        device="cpu",
    )

def classify_topic(text: str) -> dict:
"""
Returns:

{
    "topic": "technology",
    "confidence": 0.95,
    "top_predictions": [
        {"topic": "...", "score": ...}
    ]
}
"""

    if not text or not text.strip():
        return {
            "topic": "unknown",
            "confidence": 0.0,
            "top_predictions": [],
        }

    clf = _get_pipeline()

    result = clf(
        text[:512],
        candidate_labels=TOPICS,
        multi_label=False,
    )

    return {
        "topic": result["labels"][0],
        "confidence": round(result["scores"][0], 4),
        "top_predictions": [
            {
                "topic": label,
                "score": round(score, 4),
            }
            for label, score in zip(
                result["labels"][:3],
                result["scores"][:3],
            )
        ],
    }

def analyze_batch(texts: list[str]) -> list[dict]:
    return [classify_topic(t) for t in texts]

def aggregate_topics(results: list[dict]) -> dict:
    if not results:
        return {
        "total": 0,
        "topic_counts": {},
        }

    counts = {}

    for item in results:
        topic = item["topic"]
        counts[topic] = counts.get(topic, 0) + 1

    return {
        "total": len(results),
        "topic_counts": counts,
    }
