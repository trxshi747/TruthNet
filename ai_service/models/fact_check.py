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
    You are a verification agent for TruthNet, a news analysis platform. Your mission is to analyze the content below (text and/or media) using up-to-the-minute, internet-wide web searches to provide a factual accuracy assessment.

    CRITICAL MANDATE:
    1. REAL-TIME WEB SEARCH: You MUST use your most current web search capabilities to find reputable primary sources (news agencies, scientific journals, official sites) to verify the claim. Your knowledge must be as close to real-time as possible.
    2. HOLISTIC ANALYSIS: Treat the text and media as a single unit. The media's content dictates the post's type if it contains a verifiable claim (e.g., a real-world scene, object, or event).
    3. SOURCE CITATION: You MUST cite your primary sources.

    CONTENT TO ANALYZE:
    - TEXT: "{text if not is_image_only else 'No text provided, analyze the media content only.'}"
    - MEDIA: {"[Image/Video attached]" if image_url else "[No media attached]"}

    You MUST return ONLY a valid JSON object with this exact structure:
    {{
      "summary": "A concise, one or two-sentence summary of the claim and your final verdict.",
      "type": "claim",
      "truth_score": 0.0,
      "verdict": "Unverified",
      "explanation": "Conclusion on how text and media correlate, supported by the sources.",
      "sources": [
        "https://www.source1.com",
        "https://www.source2.com"
      ],
      "is_publishable": true
    }}
    
    IMPORTANT: The "explanation" field MUST be a single string, NOT a nested object.
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
        # Use the exact model list provided by the user's environment
        models_to_try = [
            'models/gemini-3.1-pro-preview',
            'models/gemini-3-pro-preview',
            'models/gemini-2.5-pro',
            'models/gemini-pro-latest',
            'models/gemini-3.5-flash',
            'models/gemini-3.1-flash-lite',
            'models/gemini-2.5-flash',
            'models/gemini-flash-latest',
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
        
        import re
        import json
        
        try:
            raw_text = response.text
        except ValueError:
            raise Exception("AI response blocked. The content may have triggered safety filters.")
            
        # Aggressively clean the response text to extract just the JSON
        clean_text = raw_text.strip()
        
        # Remove markdown code blocks if present
        if clean_text.startswith("```json"):
            clean_text = clean_text[7:]
        elif clean_text.startswith("```"):
            clean_text = clean_text[3:]
            
        if clean_text.endswith("```"):
            clean_text = clean_text[:-3]
            
        clean_text = clean_text.strip()
        
        # Find the first { and last } to isolate the JSON object
        start_idx = clean_text.find('{')
        end_idx = clean_text.rfind('}')
        
        if start_idx != -1 and end_idx != -1 and end_idx > start_idx:
            clean_text = clean_text[start_idx:end_idx + 1]
            
        try:
            result = json.loads(clean_text)
        except json.JSONDecodeError as e:
            logger.error(f"JSON Parse Error: {e}. Raw AI response was: {raw_text}")
            raise Exception("The AI returned a malformed response. Please try again.")
            
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
