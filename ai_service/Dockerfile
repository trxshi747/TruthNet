FROM python:3.11-slim

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    TRANSFORMERS_CACHE=/app/.cache/huggingface \
    CUDA_VISIBLE_DEVICES=""

WORKDIR /app

RUN apt-get update && apt-get install -y --no-install-recommends \
        curl \
    && rm -rf /var/lib/apt/lists/*

# ── Step 1: install CPU-only torch from PyTorch's own index ──────────────────
# This fetches the +cpu wheel (~250MB) instead of the default CUDA one (~1.5GB)
RUN pip install --upgrade pip && \
    pip install --no-cache-dir \
        torch==2.3.0 \
        --index-url https://download.pytorch.org/whl/cpu

# ── Step 2: install everything else from PyPI ─────────────────────────────────
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY requirements-test.txt .
RUN pip install --no-cache-dir -r requirements-test.txt

# ── Step 3: bake HuggingFace models into the image ───────────────────────────
RUN python - <<EOF
from transformers import AutoTokenizer, AutoModelForSequenceClassification

print('Downloading sentiment model...')
AutoTokenizer.from_pretrained('cardiffnlp/twitter-roberta-base-sentiment-latest')
AutoModelForSequenceClassification.from_pretrained('cardiffnlp/twitter-roberta-base-sentiment-latest')

print('Downloading toxicity model...')
AutoTokenizer.from_pretrained('martin-ha/toxic-comment-model')
AutoModelForSequenceClassification.from_pretrained('martin-ha/toxic-comment-model')

print('Downloading topic classifier...')
AutoTokenizer.from_pretrained('facebook/bart-large-mnli')
AutoModelForSequenceClassification.from_pretrained('facebook/bart-large-mnli')

print('All models ready.')
EOF

COPY . .

EXPOSE 8000

CMD ["python", "main.py"]