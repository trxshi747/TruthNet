import google.generativeai as genai
import os
from dotenv import load_dotenv
import logging

# Suppress warnings from the genai library if any
logging.basicConfig(level=logging.ERROR)

# Load environment variables from .env file in the current directory
load_dotenv()

api_key = os.getenv("GEMINI_API_KEY")

if not api_key:
    print("""
ERROR: GEMINI_API_KEY not found in your .env file.
Please make sure the .env file exists in the 'ai_service' directory and contains your key.
""")
else:
    try:
        genai.configure(api_key=api_key)
        print("""
--- Gemini Models Available To You ---""")
        
        found_models = False
        for m in genai.list_models():
            if 'generateContent' in m.supported_generation_methods:
                print(m.name)
                found_models = True
        
        if not found_models:
            print("No models found that support 'generateContent'. There might be an issue with your API key permissions.")
            
        print("""--------------------------------------
""")
        print("Please copy the list of models above (e.g., 'models/gemini-1.5-pro-latest') and paste it back to me.")

    except Exception as e:
        print(f"""
An error occurred while trying to list the models: {e}
Please check if your API key is valid and has the correct permissions.
""")
