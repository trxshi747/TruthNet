# ── Stage 1: base image ───────────────────────────────────────────────────────
FROM python:3.11-slim

# Keeps Python from generating .pyc files and enables stdout/stderr logging
ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1

WORKDIR /app

# System deps needed by PyTorch / tokenizers
RUN apt-get update && apt-get install -y --no-install-recommends \
        build-essential \
        curl \
    && rm -rf /var/lib/apt/lists/*

# ── Install Python deps ────────────────────────────────────────────────────────
COPY requirements.txt .
RUN pip install --upgrade pip && \
    pip install --no-cache-dir -r requirements.txt

# ── Pre-download HuggingFace models at build time ─────────────────────────────
# This way the image is self-contained and cold starts are instant
RUN python -c "\
from transformers import AutoTokenizer, AutoModelForSequenceClassification; \
AutoTokenizer.from_pretrained('cardiffnlp/twitter-roberta-base-sentiment-latest'); \
AutoModelForSequenceClassification.from_pretrained('cardiffnlp/twitter-roberta-base-sentiment-latest'); \
AutoTokenizer.from_pretrained('martin-ha/toxic-comment-model'); \
AutoModelForSequenceClassification.from_pretrained('martin-ha/toxic-comment-model'); \
print('✅ Models downloaded')"

# ── Copy source ────────────────────────────────────────────────────────────────
COPY . .

EXPOSE 8000

CMD ["python", "main.py"]