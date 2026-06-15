"""
Fact-Checking Module — Google Gemini 1.5 Flash
Used to verify claims against worldwide web data.
"""

import os
import logging
import google.generativeai as genai
from dotenv import load_dotenv

load_dotenv(dotenv_path="ai_service/.env")

# .env doit etre à la racine du projet
# load_dotenv()

logger = logging.getLogger(__name__)

# Configure Gemini
GEMINI_API_KEY = os.getenv("GEMINI_API_KEY")
print("Gemini API Key:", os.getenv("GEMINI_API_KEY"))

if GEMINI_API_KEY:
    genai.configure(api_key=GEMINI_API_KEY)
    # Using 'gemini-1.5-flash' is standard, but some environments prefer the long name
    # or have versioning issues. We try to be specific.
    model = genai.GenerativeModel('gemini-1.5-flash')
else:
    logger.warning("GEMINI_API_KEY not found in environment. Fact-checking will be disabled.")
    model = None

async def verify_claim(text: str, image_url: str | None = None, is_video: bool = False) -> dict:
    """
    Verifies a text claim using Gemini's knowledge and web search grounding capabilities.
    If image_url is provided, it performs multimodal analysis.
    """
    if not model:
        return {
            "success": False,
            "message": "Fact-checking service is not configured (missing API Key).",
            "truth_score": 0.5,
            "explanation": "Service unavailable."
        }

    # If no media is provided, we need at least some text to verify
    if not image_url and (not text or len(text.strip()) < 5):
        return {
            "success": False,
            "message": "Text too short to verify without media.",
            "truth_score": 0.5,
            "explanation": "N/A"
        }

    # If media is provided but text is empty, we handle the [IMAGE_ONLY_POST] placeholder
    is_image_only = "[IMAGE_ONLY_POST]" in text or not text.strip()
    
    prompt = f"""
    Analyze the following content for factual accuracy. You are a TruthNet Verification Agent.
    
    CRITICAL MANDATE:
    1. You are performing CROSS-MODAL VERIFICATION. 
    2. If an image or video is attached, you MUST analyze it deeply.
    3. If the image shows a real-world scene, an object (like a vehicle), a headline, or an event, the post is a "claim" (verifiable information).
    4. Casual text like "new info!" or "look at this!" does NOT make the post "Social" if the image contains news or factual content.
    5. You MUST NEVER classify a post with an informative image as "Social" or "Opinion".

    CONTENT TO ANALYZE:
    TEXT: "{text if not is_image_only else 'No text provided, analyze the media content only.'}"
    MEDIA: {"[Image/Video attached]" if image_url else "[No media attached]"}
    
    CLASSIFICATION CRITERIA:
    1. "Verifiable Claim": ANY post with an image of a scene, object, or event, OR text making a statement about facts.
    2. "Social/Opinion": ONLY if BOTH text and image are purely personal/emotional with NO factual or news-related content.
    3. "Nonsense/Gibberish": Completely incoherent content.

    SCORING LOGIC:
    - Evaluate the factual integrity of the information presented in the image or text.
    - If the image shows a specific event or object (like a military vehicle in a conflict zone), verify its authenticity and context.
    - Informal text ("new info!") should result in a 0% informative weight, but the image's content must provide the final Truth Score.

    You MUST provide a JSON response with:
    1. "type": "claim" (unless purely social or nonsense).
    2. "truth_score": float 0.0 to 1.0 (based on the facts found in text/image).
    3. "verdict": One of ["Verified", "Partially True", "False", "Unverified", "Social", "Nonsense"].
    4. "explanation": Use this EXACT segmented format:
       TEXT ANALYSIS: [Describe the text and its lack of or presence of info]
       MEDIA ANALYSIS: [Perform a deep analysis of the image/video content. What is seen? What does it imply? Is it verified news?]
       COMBINED VERDICT: [Synthesize why the score was given based on both parts.]
    5. "is_publishable": Boolean. False if "nonsense" or if "claim" has truth_score < 0.3.
    
    Return ONLY valid JSON.
    """

    content_parts = [prompt]

    # Handle Multimodal Input
    if image_url:
        try:
            import httpx
            
            # URLs to try (ordered by likelihood in Windows/Docker dev environments)
            possible_bases = [
                os.getenv("BACKEND_URL"),
                "http://localhost:3000",
                "http://127.0.0.1:3000",
                "http://host.docker.internal:3000"
            ]
            # Remove None and duplicates
            possible_bases = list(dict.fromkeys([b for b in possible_bases if b]))

            media_downloaded = False
            for base in possible_bases:
                try:
                    full_url = f"{base}{image_url}" if image_url.startswith('/') else image_url
                    logger.info(f"Attempting download from: {full_url}")
                    async with httpx.AsyncClient() as client:
                        resp = await client.get(full_url, timeout=5.0)
                        if resp.status_code == 200:
                            mime_type = resp.headers.get("content-type", "image/jpeg")
                            content_parts.append({
                                "mime_type": mime_type,
                                "data": resp.content
                            })
                            logger.info(f"Successfully downloaded media from {base}")
                            media_downloaded = True
                            break
                except Exception as e:
                    logger.warning(f"Failed download from {base}: {e}")

            if not media_downloaded:
                logger.error(f"FATAL: Could not download media {image_url} from any source.")
        except Exception as outer_err:
            logger.error(f"Outer error in media processing: {outer_err}")

    # Final prompt adjustment if media failed
    if image_url and len(content_parts) == 1:
        content_parts[0] += "\n\nCRITICAL WARNING: THE IMAGE FAILED TO LOAD. DO NOT RETURN 100% TRUTH SCORE OR 'SOCIAL'. Instead, classify as 'Unverified' and explain that the image content could not be accessed but is likely meant to be a news claim based on the context."

    try:
        # List of models based on your 2026 environment's available models
        models_to_try = [
            'gemini-1.5-pro',
            'gemini-pro-latest',
            'gemini-2.5-pro',
            'gemini-2.5-flash',
            'gemini-1.5-flash',
            'gemini-flash-latest',
            'gemini-2.0-flash'
        ]
        
        response = None
        last_err = None

        for model_name in models_to_try:
            try:
                target_model = model_name if model_name.startswith('models/') else f"models/{model_name}"
                temp_model = genai.GenerativeModel(target_model)
                
                # generate_content accepts a list of parts for multimodal
                response = temp_model.generate_content(content_parts)
                
                if response:
                    logger.info(f"Successfully used model: {target_model}")
                    break
            except Exception as e:
                last_err = e
                err_str = str(e).lower()
                if "404" in err_str or "not found" in err_str or "429" in err_str or "quota" in err_str:
                    logger.warning(f"Model {model_name} failed ({err_str}), trying next...")
                    continue
                else:
                    raise e
        
        if not response:
            raise last_err or Exception("All Gemini models failed or reached quota limits.")
        
        # Simple cleanup of common LLM markdown output
        raw_text = response.text.replace("```json", "").replace("```", "").strip()
        
        import json
        result = json.loads(raw_text)
        return {
            "success": True,
            **result
        }
    except Exception as e:
        logger.error(f"Gemini Verification Error: {e}")
        return {
            "success": False,
            "message": str(e),
            "truth_score": 0.5,
            "explanation": "An error occurred during verification."
        }
