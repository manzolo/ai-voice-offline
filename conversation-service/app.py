"""
Conversation Orchestration Service for AI Voice Tools
Chains STT → Ollama LLM → TTS for voice-based conversations
"""

from fastapi import FastAPI, UploadFile, Form, HTTPException, File
from fastapi.responses import JSONResponse
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
import httpx
import json
import asyncio
import base64
import logging
import os
from typing import Optional

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

app = FastAPI(title="Conversation Service", version="1.0.0")

# CORS configuration
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=False,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Service URLs (internal Docker network)
STT_URL = os.getenv("STT_URL", "http://faster-whisper:8000/v1/audio/transcriptions")
OLLAMA_URL = os.getenv("OLLAMA_URL", "http://ollama:11434")
TTS_URL = os.getenv("TTS_URL", "http://xtts:5002/api/tts")

# Configuration
OLLAMA_MODEL = os.getenv("OLLAMA_MODEL", "tinyllama:1.1b")
VOICE_PROFILE = os.getenv("VOICE_PROFILE", "default")
DEFAULT_LANGUAGE = os.getenv("DEFAULT_LANGUAGE", "en")

# Timeouts (in seconds)
STT_TIMEOUT = float(os.getenv("STT_TIMEOUT", "120"))
OLLAMA_TIMEOUT = float(os.getenv("OLLAMA_TIMEOUT", "90"))
TTS_TIMEOUT = float(os.getenv("TTS_TIMEOUT", "180"))

# System prompts (Friendly & Conversational) - Language-specific
SYSTEM_PROMPTS = {
    "en": """You are a friendly and helpful AI assistant. Be warm, engaging,
and conversational in your responses. Use natural language and feel free to add
personality to your answers while staying helpful and accurate. Keep your responses
concise but informative - typically a few sentences unless more detail is requested.""",
    
    "it": """Sei un assistente AI amichevole e disponibile. Sii caloroso, coinvolgente
e colloquiale nelle tue risposte. Usa un linguaggio naturale e sentiti libero di aggiungere
personalità alle tue risposte rimanendo utile e preciso. Mantieni le tue risposte
concise ma informative - tipicamente alcune frasi a meno che non sia richiesto più dettaglio.""",
    
    "es": """Eres un asistente de IA amigable y servicial. Sé cálido, atractivo
y conversacional en tus respuestas. Usa lenguaje natural y siéntete libre de agregar
personalidad a tus respuestas mientras te mantienes útil y preciso. Mantén tus respuestas
concisas pero informativas - típicamente unas pocas oraciones a menos que se solicite más detalle.""",
    
    "fr": """Vous êtes un assistant IA amical et serviable. Soyez chaleureux, engageant
et conversationnel dans vos réponses. Utilisez un langage naturel et n'hésitez pas à ajouter
de la personnalité à vos réponses tout en restant utile et précis. Gardez vos réponses
concises mais informatives - généralement quelques phrases sauf si plus de détails sont demandés.""",
    
    "de": """Sie sind ein freundlicher und hilfsbereiter KI-Assistent. Seien Sie warmherzig, einnehmend
und gesprächig in Ihren Antworten. Verwenden Sie natürliche Sprache und fügen Sie gerne
Persönlichkeit zu Ihren Antworten hinzu, während Sie hilfreich und genau bleiben. Halten Sie Ihre Antworten
prägnant aber informativ - typischerweise ein paar Sätze, es sei denn, mehr Details werden ausdrücklich gewünscht.""",
    
    "pt": """Você é um assistente de IA amigável e prestativo. Seja caloroso, envolvente
e conversacional em suas respostas. Use linguagem natural e sinta-se livre para adicionar
personalidade às suas respostas enquanto permanece útil e preciso. Mantenha suas respostas
concisas mas informativas - tipicamente algumas frases a menos que mais detalhes sejam solicitados."""
}

# Response model
class ConversationResponse(BaseModel):
    transcription: str
    response_text: str
    audio_base64: str


@app.get("/")
async def root():
    """Health check and service info."""
    return {
        "service": "conversation-orchestration",
        "version": "1.0.0",
        "status": "running",
        "config": {
            "ollama_model": OLLAMA_MODEL,
            "voice_profile": VOICE_PROFILE,
            "language": DEFAULT_LANGUAGE,
            "timeouts": {
                "stt": STT_TIMEOUT,
                "ollama": OLLAMA_TIMEOUT,
                "tts": TTS_TIMEOUT
            }
        }
    }


@app.get("/health")
async def health():
    """Health check endpoint."""
    return {"status": "healthy"}


@app.post("/api/conversation", response_model=ConversationResponse)
async def conversation(
    audio: UploadFile = File(...),
    context: str = Form("[]"),
    language: Optional[str] = Form(None),
    model: Optional[str] = Form(None)
):
    """
    Main conversation endpoint.

    Accepts audio input and conversation context, returns transcription,
    AI response text, and synthesized audio.

    Args:
        audio: Audio file (WAV, MP3, etc.)
        context: JSON array of conversation history (optional)
        language: Language code (optional, defaults to env DEFAULT_LANGUAGE)
        model: Ollama model name (optional, defaults to env OLLAMA_MODEL)

    Returns:
        JSON with transcription, response_text, and audio_base64
    """

    # Use provided language or default
    lang = language or DEFAULT_LANGUAGE
    # Use provided model or default
    selected_model = model or OLLAMA_MODEL

    logger.info(f"Using model: {selected_model}, language: {lang}")

    try:
        logger.info("=== Starting conversation processing ===")

        # ===== STEP 1: STT (Speech-to-Text) =====
        logger.info("Step 1: Transcribing audio with STT...")
        try:
            async with httpx.AsyncClient(timeout=STT_TIMEOUT) as client:
                # Read audio file
                audio_content = await audio.read()

                # Prepare multipart form data
                files = {"file": (audio.filename or "audio.wav", audio_content, audio.content_type or "audio/wav")}
                data = {
                    "model": "medium",
                    "response_format": "json",
                    "language": lang
                }

                stt_response = await client.post(STT_URL, files=files, data=data)
                stt_response.raise_for_status()

                transcription = stt_response.json().get("text", "").strip()
                logger.info(f"  ✓ Transcription: '{transcription}'")

        except httpx.TimeoutException:
            raise HTTPException(503, "STT service timeout. Please try again.")
        except httpx.HTTPStatusError as e:
            logger.error(f"STT service error: {e}")
            raise HTTPException(502, f"STT service error: {e.response.status_code}")
        except Exception as e:
            logger.error(f"STT unexpected error: {str(e)}")
            raise HTTPException(500, f"STT error: {str(e)}")

        if not transcription:
            raise HTTPException(400, "No speech detected in audio. Please try again.")

        # ===== STEP 2: Ollama (LLM) =====
        logger.info("Step 2: Generating response with Ollama...")
        try:
            # Parse conversation history
            try:
                history = json.loads(context) if context else []
            except json.JSONDecodeError:
                logger.warning("Invalid context JSON, starting fresh")
                history = []

            # Add user message
            history.append({"role": "user", "content": transcription})

            # Maintain only last 20 messages (10 turns) + system prompt
            if len(history) > 20:
                history = history[-20:]
                logger.info(f"  Trimmed history to last 20 messages")

            # Build messages with system prompt (use language-specific prompt)
            system_prompt = SYSTEM_PROMPTS.get(lang, SYSTEM_PROMPTS["en"])
            messages = [{"role": "system", "content": system_prompt}] + history

            async with httpx.AsyncClient(timeout=OLLAMA_TIMEOUT) as client:
                # Use Ollama's chat completion API
                ollama_payload = {
                    "model": selected_model,
                    "messages": messages,
                    "stream": False,
                    "options": {
                        "temperature": 0.7,
                        "top_p": 0.9
                    }
                }

                # Try chat completions API first (newer)
                try:
                    ollama_response = await client.post(
                        f"{OLLAMA_URL}/v1/chat/completions",
                        json=ollama_payload,
                        headers={"Content-Type": "application/json"}
                    )
                    ollama_response.raise_for_status()
                    result = ollama_response.json()
                    response_text = result["choices"][0]["message"]["content"]
                except Exception as e:
                    # Fallback to legacy generate API
                    logger.info("  Chat API failed, trying generate API...")
                    ollama_payload_legacy = {
                        "model": selected_model,
                        "prompt": f"System: {system_prompt}\n\nUser: {transcription}\n\nAssistant:",
                        "stream": False
                    }
                    ollama_response = await client.post(
                        f"{OLLAMA_URL}/api/generate",
                        json=ollama_payload_legacy
                    )
                    ollama_response.raise_for_status()
                    response_text = ollama_response.json()["response"]

                response_text = response_text.strip()
                logger.info(f"  ✓ Response: '{response_text[:100]}...'")

        except httpx.TimeoutException:
            raise HTTPException(503, "LLM timeout. Try a simpler question.")
        except httpx.HTTPStatusError as e:
            logger.error(f"Ollama service error: {e}")
            raise HTTPException(502, f"LLM service error: {e.response.status_code}")
        except Exception as e:
            logger.error(f"Ollama unexpected error: {str(e)}")
            raise HTTPException(500, f"LLM error: {str(e)}")

        if not response_text:
            raise HTTPException(500, "LLM returned empty response")

        # ===== STEP 3: TTS (Text-to-Speech with Voice Cloning) =====
        logger.info("Step 3: Synthesizing speech with TTS...")
        logger.info(f"  TTS request: {len(response_text)} chars, language={lang}, profile={VOICE_PROFILE}")
        try:
            async with httpx.AsyncClient(timeout=TTS_TIMEOUT) as client:
                tts_payload = {
                    "text": response_text,
                    "language": lang,
                    "voice_profile": VOICE_PROFILE
                }

                tts_response = await client.post(
                    TTS_URL,
                    json=tts_payload,
                    headers={"Content-Type": "application/json"}
                )
                tts_response.raise_for_status()

                audio_wav = tts_response.content
                audio_base64 = base64.b64encode(audio_wav).decode('utf-8')
                logger.info(f"  ✓ Generated {len(audio_wav)} bytes of audio")

        except httpx.TimeoutException:
            logger.error(f"TTS timeout after {TTS_TIMEOUT} seconds")
            raise HTTPException(503, f"TTS timeout after {TTS_TIMEOUT}s. Increase TTS_TIMEOUT in .env if needed.")
        except httpx.HTTPStatusError as e:
            logger.error(f"TTS service HTTP error: {e.response.status_code}")
            logger.error(f"TTS response body: {e.response.text}")
            raise HTTPException(502, f"TTS service error: {e.response.status_code}")
        except Exception as e:
            logger.error(f"TTS unexpected error: {str(e)}", exc_info=True)
            raise HTTPException(500, f"TTS error: {str(e)}")

        # ===== SUCCESS =====
        logger.info("=== Conversation processing complete ===")

        return ConversationResponse(
            transcription=transcription,
            response_text=response_text,
            audio_base64=audio_base64
        )

    except HTTPException:
        # Re-raise HTTP exceptions
        raise
    except Exception as e:
        # Catch-all for unexpected errors
        logger.error(f"Unexpected error in conversation: {str(e)}", exc_info=True)
        raise HTTPException(500, f"Internal server error: {str(e)}")


if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=5003)
