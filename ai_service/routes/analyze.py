"""
FastAPI router — /analyze/*
All analysis endpoints consumed by the Node.js bridge.
"""

from fastapi import APIRouter, HTTPException
from pydantic import BaseModel, Field
import logging

from models.sentiment import (
    analyze_sentiment,
    analyze_batch as sentiment_batch,
    aggregate_sentiment,
)
from models.toxicity import (
    analyze_toxicity,
    analyze_batch as toxicity_batch,
    aggregate_toxicity,
)
from models.fact_check import verify_claim

from models.topic_classifier import (
    classify_topic,
    analyze_batch as topic_batch,
    aggregate_topics,
)

logger = logging.getLogger(__name__)
router = APIRouter(prefix="/analyze", tags=["Analysis"])


# ─── Request / Response schemas ───────────────────────────────────────────────

class SingleTextRequest(BaseModel):
    text: str = Field(..., min_length=1, max_length=5000)
    image_url: str | None = None
    is_video: bool = False

class BatchTextRequest(BaseModel):
    texts: list[str] = Field(..., min_items=1, max_items=500)

class CommentData(BaseModel):
    id:   str
    text: str

class CommentsRequest(BaseModel):
    """Used by the batch-analyze-comments endpoint — includes IDs for mapping."""
    comments: list[CommentData] = Field(..., min_items=1, max_items=500)


# ─── Single-text endpoints ────────────────────────────────────────────────────

@router.post("/sentiment")
async def analyze_sentiment_endpoint(body: SingleTextRequest):
    """
    Analyse the sentiment of a single text.
    Returns label (positive/neutral/negative), confidence, all scores,
    and negativity/positivity degree.
    """
    try:
        result = analyze_sentiment(body.text)
        return {"success": True, "result": result}
    except Exception as e:
        logger.error(f"Sentiment analysis error: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@router.post("/toxicity")
async def analyze_toxicity_endpoint(body: SingleTextRequest):
    """
    Analyse the toxicity of a single text.
    Returns is_toxic flag, toxic_score, degree, per-category flags.
    """
    try:
        result = analyze_toxicity(body.text)
        return {"success": True, "result": result}
    except Exception as e:
        logger.error(f"Toxicity analysis error: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@router.post("/full")
async def analyze_full_endpoint(body: SingleTextRequest):
    """
    Run BOTH sentiment and toxicity analysis on a single text.
    Convenient for real-time comment moderation.
    """
    try:
        sentiment = analyze_sentiment(body.text)
        toxicity  = analyze_toxicity(body.text)
        topic = classify_topic(body.text)
        return {
            "success":   True,
            "text":      body.text[:100] + ("…" if len(body.text) > 100 else ""),
            "sentiment": sentiment,
            "toxicity":  toxicity,
            "topic": topic,
        }
    except Exception as e:
        logger.error(f"Full analysis error: {e}")
        raise HTTPException(status_code=500, detail=str(e))

@router.post("/topic")
async def analyze_topic_endpoint(body: SingleTextRequest):
"""
Analyse the topic of a single text.
"""

try:
    result = classify_topic(body.text)

    return {
        "success": True,
        "result": result,
    }

except Exception as e:
    logger.error(f"Topic analysis error: {e}")
    raise HTTPException(status_code=500, detail=str(e))


@router.post("/verify")
async def verify_claim_endpoint(body: SingleTextRequest):
    """
    Verify a claim using Gemini 1.5 Flash.
    Returns truth_score, verdict, and explanation.
    """
    try:
        result = await verify_claim(body.text, body.image_url, body.is_video)
        return result
    except Exception as e:
        logger.error(f"Verification error: {e}")
        raise HTTPException(status_code=500, detail=str(e))


# ─── Batch endpoints ──────────────────────────────────────────────────────────

@router.post("/batch/sentiment")
async def batch_sentiment(body: BatchTextRequest):
    """Analyse sentiment of multiple texts. Returns per-text results + aggregate."""
    try:
        results   = sentiment_batch(body.texts)
        aggregate = aggregate_sentiment(results)
        return {"success": True, "results": results, "aggregate": aggregate}
    except Exception as e:
        logger.error(f"Batch sentiment error: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@router.post("/batch/toxicity")
async def batch_toxicity(body: BatchTextRequest):
    """Analyse toxicity of multiple texts. Returns per-text results + aggregate."""
    try:
        results   = toxicity_batch(body.texts)
        aggregate = aggregate_toxicity(results)
        return {"success": True, "results": results, "aggregate": aggregate}
    except Exception as e:
        logger.error(f"Batch toxicity error: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@router.post("/batch/comments")
async def batch_analyze_comments(body: CommentsRequest):
    """
    Main endpoint called by Node.js bridge.
    Analyses all comments by ID, returns:
    - per_comment: list of {id, sentiment, toxicity}
    - aggregate: combined sentiment + toxicity platform stats
    """
    try:
        texts = [c.text for c in body.comments]
        ids   = [c.id   for c in body.comments]

        sentiment_results = sentiment_batch(texts)
        toxicity_results  = toxicity_batch(texts)

        per_comment = [
            {
                "id":        ids[i],
                "sentiment": sentiment_results[i],
                "toxicity":  toxicity_results[i],
            }
            for i in range(len(ids))
        ]

        return {
            "success":     True,
            "per_comment": per_comment,
            "aggregate": {
                "sentiment": aggregate_sentiment(sentiment_results),
                "toxicity":  aggregate_toxicity(toxicity_results),
            },
        }
    except Exception as e:
        logger.error(f"Batch comments analysis error: {e}")
        raise HTTPException(status_code=500, detail=str(e))


# ─── Dashboard summary endpoint ───────────────────────────────────────────────

@router.post("/dashboard-summary")
async def dashboard_summary(body: BatchTextRequest):
    """
    Designed for the admin dashboard.
    Given a list of recent comment texts, returns:
    - Sentiment distribution (positive/neutral/negative counts + avg scores)
    - Toxicity distribution (toxic_count, degree_breakdown, category_counts)
    - Top concern flags
    """
    try:
        s_results = sentiment_batch(body.texts)
        t_results = toxicity_batch(body.texts)
        topic_results = topic_batch(body.texts)

        s_agg = aggregate_sentiment(s_results)
        t_agg = aggregate_toxicity(t_results)
        topic_agg = aggregate_topics(topic_results)

        # Top toxicity categories (sorted by count desc)
        top_categories = sorted(
            t_agg["category_counts"].items(),
            key=lambda x: x[1],
            reverse=True,
        )[:5]

        return {
            "success":  True,
            "total":    len(body.texts),
            "sentiment": s_agg,
            "toxicity":  t_agg,
            "topics": topic_agg,

            "top_toxic_categories": [
                {"category": cat, "count": cnt}
                for cat, cnt in top_categories
            ],
        }
    except Exception as e:
        logger.error(f"Dashboard summary error: {e}")
        raise HTTPException(status_code=500, detail=str(e))