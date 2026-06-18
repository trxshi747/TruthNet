"""
TruthNet AI Service — FastAPI
Runs on port 8000, called internally by Node.js (port 3000).
"""

import logging
import os
from contextlib import asynccontextmanager

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from dotenv import load_dotenv

from routes.analyze import router as analyze_router

from models.topic_classifier import (_get_pipeline as load_topic_classifier)

load_dotenv()
logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s  %(levelname)-8s  %(name)s — %(message)s",
)
logger = logging.getLogger(__name__)


# ─── Lifespan: warm-up models on startup ─────────────────────────────────────
@asynccontextmanager
async def lifespan(app: FastAPI):
    logger.info("⚡ Warming up AI models…")
    # Import triggers the @lru_cache load — models are downloaded once and cached
    from models.sentiment import _get_pipeline as load_sentiment
    from models.toxicity  import _get_pipeline as load_toxicity
    load_sentiment()
    load_toxicity()
    load_topic_classifier()

    logger.info("✅ Models ready")
    yield
    logger.info("🔴 AI service shutting down")


# ─── App ──────────────────────────────────────────────────────────────────────
app = FastAPI(
    title="TruthNet AI Service",
    version="1.0.0",
    description="Sentiment & toxicity analysis powered by HuggingFace Transformers",
    lifespan=lifespan,
)

# CORS — only allow local Node.js bridge and dev origins
allowed_origins = os.getenv("ALLOWED_ORIGINS", "http://localhost:3000").split(",")

app.add_middleware(
    CORSMiddleware,
    allow_origins=allowed_origins,
    allow_credentials=True,
    allow_methods=["POST", "GET"],
    allow_headers=["*"],
)

# ─── Routers ──────────────────────────────────────────────────────────────────
app.include_router(analyze_router, prefix="/analyze")


# ─── Health check ─────────────────────────────────────────────────────────────
@app.get("/health")
async def health():
    return {"status": "ok", "service": "TruthNet AI"}


# ─── Entry point ─────────────────────────────────────────────────────────────
if __name__ == "__main__":
    import uvicorn
    uvicorn.run(
        "main:app",
        host="0.0.0.0",
        port=int(os.getenv("AI_PORT", 8000)),
        reload=os.getenv("ENV", "production") == "development",
        workers=1,          # keep 1 worker so model cache is shared
    )