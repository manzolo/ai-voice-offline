# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

AI Voice Conversation Offline is a local GPU-accelerated voice conversation system that integrates Speech-to-Text, Large Language Model, and Text-to-Speech services. The system enables natural voice conversations with AI, including voice cloning capabilities. Everything runs completely offline using Docker containers, with no cloud dependencies.

**Key Technologies:**
- **TTS**: Coqui TTS with XTTS v2 model (multilingual voice synthesis + voice cloning)
- **STT**: Faster-Whisper (large-v3 model by default)
- **LLM**: Ollama (TinyLlama 1.1B by default, extensible to other models)
- **Conversation Service**: FastAPI orchestrator that chains STT → LLM → TTS
- **Web UI**: Single-page HTML/JavaScript application for conversation interface
- **Infrastructure**: Docker Compose with CPU and GPU modes

## Architecture

The system consists of five Docker containers:

### 1. **xtts** (tts-service/)
Custom-built FastAPI service for text-to-speech with voice cloning

- Runs on port 9876 (configurable via TTS_PORT)
- Uses Coqui TTS library with XTTS v2 model
- Supports 16+ languages with male/female voice options
- Voice cloning using samples from `./voice-profiles` directory
- Models cached in `./tts_models` mounted to `/root/.local/share/tts`
- GPU detection via `torch.cuda.is_available()`
- API endpoint: `/api/tts`

### 2. **faster-whisper**
Pre-built STT service (fedirz/faster-whisper-server)

- Runs on port 10300 (configurable via STT_PORT)
- OpenAI-compatible API endpoint at `/v1/audio/transcriptions`
- Health check at `/health`
- Models cached in `./whisper-cache` mounted to `/root/.cache/huggingface`
- Image variant changes between CPU (`latest-cpu`) and GPU (`latest-cuda`)

### 3. **ollama**
Local LLM runtime (ollama/ollama)

- Runs on port 11434 (configurable via OLLAMA_PORT)
- Default model: TinyLlama 1.1B (optimized for 8GB VRAM)
- Models cached in `./ollama-models` mounted to `/root/.ollama`
- API endpoint: `/api/generate` (Ollama API format)
- GPU-accelerated when available
- Extensible to larger models (Llama2, Mistral, etc.)

### 4. **conversation**
Custom conversation orchestrator service (conversation-service/)

- Runs on port 9877 (configurable via CONVERSATION_PORT)
- Orchestrates the full conversation pipeline: Audio → STT → LLM → TTS → Audio
- FastAPI application with endpoints:
  - `/api/conversation` - Voice input to voice output
  - `/api/conversation/text` - Text input to voice output
  - `/health` - Health check
- Manages timeouts and error handling for each service
- Passes voice profile configuration to TTS service
- Depends on: xtts, faster-whisper, ollama

### 5. **web-conversation**
Static file server (Python http.server)

- Runs on port 8080
- Serves `web-conversation/index.html` - single-page conversation app
- Multilingual UI (16+ languages)
- Features:
  - Voice recording via browser MediaRecorder API
  - Text input for typed conversations
  - Audio playback of AI responses
  - Conversation history display
  - Language selection
- Communicates with conversation service at http://localhost:9877

### CPU vs GPU Architecture

The project has **dual deployment modes** controlled by separate compose files:

**CPU mode**: `docker-compose.yml`
- Uses `WHISPER__INFERENCE__DEVICE=cpu`
- Whisper image: `fedirz/faster-whisper-server:latest-cpu`
- No GPU resource reservations
- Slower (30-60s per conversation cycle) but works on any system

**GPU mode**: `docker-compose.gpu.yml`
- Uses `WHISPER__INFERENCE__DEVICE=cuda`
- Whisper image: `fedirz/faster-whisper-server:latest-cuda`
- Requires Docker GPU support (deploy.resources.reservations)
- Sets `CUDA_VISIBLE_DEVICES` environment variable
- GPU resources allocated to: xtts, faster-whisper, ollama
- 10-30x faster processing (3-10s per conversation cycle)

The TTS server's Dockerfile is based on `nvidia/cuda:12.1.0-cudnn8-runtime-ubuntu22.04` and automatically detects GPU availability at runtime.

## Common Development Commands

### Setup and Start
```bash
make setup        # Initial setup - CPU mode (builds, downloads models, starts services)
make setup-gpu    # Initial setup - GPU mode (requires NVIDIA GPU + Docker GPU support)
make up           # Start services in CPU mode
make up-gpu       # Start services in GPU mode
make down         # Stop all services (both CPU and GPU)
```

### Model Management
```bash
make pull-ollama-model  # Download TinyLlama model (~600MB)
```

### Voice Cloning Setup
```bash
make setup-voice         # Containerized voice recording (interactive)
make setup-voice-upload  # Manual upload of pre-recorded samples
make debug-audio         # Debug microphone access issues
```

### Development
```bash
make build               # Rebuild Docker images after code changes
make restart             # Restart all running containers
make logs                # View all service logs (follow mode)
make logs-tts            # View TTS server logs only
make logs-whisper        # View STT server logs only
make logs-ollama         # View Ollama LLM logs only
make logs-conversation   # View conversation service logs only
make status              # Check container status and volume usage
```

### Testing
```bash
make check-services      # Check all services are healthy
make test-conversation   # Test conversation API health
make test-ollama         # Test Ollama API
```

### Cleanup
```bash
make clean              # Stop and remove containers
make clean-all          # Remove everything including downloaded models (~8GB)
```

## Configuration

All configuration is in `.env` (created from `.env.example` during setup):

**Key Environment Variables:**
- `DEFAULT_LANGUAGE`: Two-letter language code (en, it, es, fr, de, pt, etc.)
- `DEFAULT_SPEAKER`: "male" or "female" (for non-cloned voices)
- `VOICE_PROFILE`: Voice profile directory name (default: "default")
- `TTS_PORT`, `STT_PORT`, `OLLAMA_PORT`, `CONVERSATION_PORT`: Service port mappings
- `WHISPER_MODEL`: Model size (large-v3, medium, small, etc.)
- `OLLAMA_MODEL`: LLM model (tinyllama:1.1b, llama2:7b, mistral:7b, etc.)
- `CUDA_VISIBLE_DEVICES`: GPU device ID (0 by default, only for GPU mode)
- `STT_TIMEOUT`, `OLLAMA_TIMEOUT`, `TTS_TIMEOUT`: Service timeouts in seconds

## Code Organization

### TTS Service (tts-service/)
- `app.py`: FastAPI application
  - Endpoint: `/api/tts` - Synthesize speech
    - Request model: TTSRequest (text, language, speaker, voice_profile)
    - Response: WAV audio bytes (24kHz, via soundfile)
    - Speaker mapping: "male" → "Andrew Chipper", "female" → "Claribel Dervla"
    - Voice cloning: Reads samples from `/app/voice-profiles/{profile_name}/`
  - Root endpoint `/` returns status, GPU info, supported languages, and speaker map
- `Dockerfile`: Multi-stage build with CUDA runtime
  - Requires: espeak-ng, ffmpeg, libsndfile1
  - Runs on port 5002 internally (mapped to TTS_PORT externally)
- `requirements.txt`: Python dependencies (TTS, fastapi, uvicorn, soundfile, torch)

### Conversation Service (conversation-service/)
- `app.py`: FastAPI orchestrator
  - Endpoint: `/api/conversation` - Full voice conversation
    - Accepts: multipart/form-data with audio file
    - Returns: WAV audio response
    - Pipeline: STT → LLM → TTS
  - Endpoint: `/api/conversation/text` - Text to voice
    - Accepts: JSON with text field
    - Returns: WAV audio response
    - Pipeline: LLM → TTS
  - Endpoint: `/health` - Health check
  - Environment variables:
    - `STT_URL`: Whisper service URL (internal: http://faster-whisper:8000)
    - `OLLAMA_URL`: Ollama service URL (internal: http://ollama:11434)
    - `TTS_URL`: TTS service URL (internal: http://xtts:5002)
    - `OLLAMA_MODEL`, `VOICE_PROFILE`, `DEFAULT_LANGUAGE`
    - `STT_TIMEOUT`, `OLLAMA_TIMEOUT`, `TTS_TIMEOUT`
- `Dockerfile`: Python FastAPI container
- `requirements.txt`: Python dependencies (fastapi, requests, httpx, etc.)

### Web Interface (web-conversation/)
- `index.html`: Single-file SPA with embedded CSS and JavaScript
  - Multilingual UI (16 languages) with i18n translations
  - Voice recording via MediaRecorder API
  - Text input for typed conversations
  - Audio playback using HTML5 Audio API
  - Conversation history display
  - Language selector
  - Dark theme (GitHub-inspired colors)
  - Direct fetch() calls to http://localhost:9877

### Voice Recording Scripts (scripts/)
- `Dockerfile`: Container for voice recording
  - Includes: python3, sounddevice, scipy, numpy
  - Requires: /dev/snd device access for microphone
- `setup_voice_profile.py`: Interactive voice recording script
  - Records 3-5 voice samples (2-3 seconds each)
  - Detects supported sample rates
  - Saves to `/app/voice-profiles/default/`
  - Validates audio quality

## API Endpoints

### Conversation API
```
POST http://localhost:9877/api/conversation
Content-Type: multipart/form-data

audio: <audio file>
language: en  // optional

Response: audio/wav (binary)
```

```
POST http://localhost:9877/api/conversation/text
Content-Type: application/json

{
  "text": "What is the weather like?",
  "language": "en"  // optional
}

Response: audio/wav (binary)
```

### TTS API
```
POST http://localhost:9876/api/tts
Content-Type: application/json

{
  "text": "Text to synthesize",
  "language": "en",        // optional, defaults to DEFAULT_LANGUAGE
  "speaker": "male",       // optional: "male" or "female", defaults to DEFAULT_SPEAKER
  "voice_profile": "default"  // optional: voice profile name for cloning
}

Response: audio/wav (binary)
```

### STT API (OpenAI-compatible)
```
POST http://localhost:10300/v1/audio/transcriptions
Content-Type: multipart/form-data

file: <audio/video file>
model: large-v3  // optional
language: en     // optional

Response: JSON with transcription
```

### Ollama API
```
POST http://localhost:11434/api/generate
Content-Type: application/json

{
  "model": "tinyllama:1.1b",
  "prompt": "What is the weather?",
  "stream": false
}

Response: JSON with generated text
```

### Health Checks
- Conversation: `GET http://localhost:9877/health`
- TTS: `GET http://localhost:9876/` (returns JSON with model info)
- STT: `GET http://localhost:10300/health`
- Ollama: `GET http://localhost:11434/api/tags`

## Model Management

**TTS Models (tts_models/):**
- Downloaded on first use by Coqui TTS library
- XTTS v2 is the primary model (~2GB)
- Models persist in Docker volume mount

**STT Models (whisper-cache/):**
- Downloaded on first container start by faster-whisper
- large-v3 model is default (~3GB)
- Cached in HuggingFace format

**LLM Models (ollama-models/):**
- Downloaded via `make pull-ollama-model` or `docker exec ollama ollama pull <model>`
- TinyLlama 1.1B is default (~600MB)
- Larger models available: llama2:7b (~4GB), mistral:7b (~4GB), etc.

**Voice Profiles (voice-profiles/):**
- User-recorded or uploaded WAV files for voice cloning
- Structure: `voice-profiles/{profile_name}/sample_*.wav`
- Default profile: `voice-profiles/default/`
- Requirements: 3-5 samples, 24kHz WAV, 2-3 seconds each

**Total disk space needed:** ~8GB for all models + voice profiles

## Development Workflow

1. **Modifying TTS service:**
   - Edit `tts-service/app.py` or `tts-service/requirements.txt`
   - Run `make build` to rebuild the container
   - Run `make restart` to apply changes

2. **Modifying conversation service:**
   - Edit `conversation-service/app.py` or `conversation-service/requirements.txt`
   - Run `make build` to rebuild the container
   - Run `make restart` to apply changes

3. **Modifying web interface:**
   - Edit `web-conversation/index.html`
   - Changes are live (no rebuild needed, just refresh browser)

4. **Changing configuration:**
   - Edit `.env`
   - Run `make restart` to apply

5. **Switching between CPU and GPU:**
   - Run `make down` to stop current services
   - Run `make up` (CPU) or `make up-gpu` (GPU)

6. **Adding/changing voice profiles:**
   - Run `make setup-voice` for new recording
   - Or manually add WAV files to `voice-profiles/{profile_name}/`
   - Update `VOICE_PROFILE` in `.env`
   - Restart services with `make restart`

7. **Changing LLM model:**
   - Pull new model: `docker exec ollama ollama pull <model>`
   - Update `OLLAMA_MODEL` in `.env`
   - Restart conversation service: `docker compose restart conversation`

## Troubleshooting

**Container won't start:**
- Check logs: `make logs` or service-specific logs
- Verify ports not in use: `docker compose ps` and `netstat -tuln | grep <port>`
- Ensure all environment variables are set in `.env`

**GPU not detected:**
- Verify NVIDIA runtime: `docker run --rm --gpus all nvidia/cuda:12.1.0-base-ubuntu22.04 nvidia-smi`
- Check container GPU access: `docker exec xtts nvidia-smi`
- Ensure `docker-compose.gpu.yml` is being used
- Check `CUDA_VISIBLE_DEVICES` setting

**Models not downloading:**
- Check internet connectivity
- Ensure ~8GB disk space available
- Models download on first use, be patient (can take 10-20 minutes)
- For Ollama: explicitly run `make pull-ollama-model`
- Check logs for download progress

**Conversation is slow:**
- Use GPU mode for 10-30x speedup
- Reduce model sizes: `WHISPER_MODEL=medium`, use TinyLlama
- Increase timeouts if requests are failing
- Check `make logs` for bottlenecks

**Voice cloning not working:**
- Ensure samples exist in `voice-profiles/{VOICE_PROFILE}/`
- Samples must be WAV format, 24kHz preferred
- Need at least 3 samples for acceptable quality
- Check TTS logs: `make logs-tts`
- Verify `VOICE_PROFILE` environment variable is correct

**Web interface can't connect to conversation API:**
- Verify containers are running: `make status`
- Check browser console for errors
- Ensure conversation service is healthy: `make test-conversation`
- Check logs: `make logs-conversation`

**Microphone not accessible for voice recording:**
- Run `make debug-audio` to diagnose
- Ensure `/dev/snd` exists on host
- Try `make setup-voice-upload` as alternative
- Check Docker has device access permissions

## Testing Notes

- Use `make check-services` to verify all services are responding
- `make test-conversation` checks conversation service health endpoint
- `make test-ollama` verifies Ollama is running and has models
- Full conversation testing requires web UI or curl with audio files
- Monitor logs during testing: `make logs`

## Important Implementation Details

1. **Conversation Pipeline**: The conversation service orchestrates three API calls sequentially:
   - Audio file → STT service → transcribed text
   - Transcribed text → Ollama → AI response text
   - AI response text → TTS service → audio response
   Each step has configurable timeouts to handle slow processing.

2. **Voice Cloning**: Voice profiles are passed to TTS via the `voice_profile` parameter. The TTS service loads WAV samples from `/app/voice-profiles/{profile}/` and uses them for voice cloning.

3. **Speaker Selection**: For non-cloned voices, TTS API accepts "male" or "female", mapped to XTTS v2's built-in speakers. Don't use internal speaker names directly.

4. **Language Codes**: Use two-letter ISO codes (en, it, es) or specific variants (zh-cn). Language must match across STT, LLM context, and TTS.

5. **Audio Format**: All services use 24kHz WAV format (XTTS v2 native rate). The conversation service maintains this format throughout the pipeline.

6. **CORS**: All services have CORS fully enabled (`allow_origins=["*"]`). This allows the web UI to make direct requests.

7. **Timeouts**: Each service has separate timeout configuration:
   - STT_TIMEOUT: 120s (accounts for model loading on first request)
   - OLLAMA_TIMEOUT: 90s (depends on prompt length and model size)
   - TTS_TIMEOUT: 180s (voice cloning requires more time)

8. **Volume Mounts**: Critical directories for persistence:
   - `tts_models`: Coqui TTS model cache (~2GB)
   - `whisper-cache`: Whisper model cache (~3GB)
   - `ollama-models`: LLM model cache (~600MB-4GB+)
   - `voice-profiles`: User voice samples (minimal size)

9. **GPU Memory**: VRAM requirements for GPU mode:
   - XTTS v2: ~2GB VRAM
   - Whisper large-v3: ~3GB VRAM
   - TinyLlama 1.1B: ~2GB VRAM
   - Total: ~7-8GB VRAM recommended

10. **Service Dependencies**: The conversation service depends on all three backend services (xtts, faster-whisper, ollama). If any backend is down, conversation requests will fail.
