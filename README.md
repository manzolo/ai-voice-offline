# 🎙️ AI Voice Conversation Offline

[![Docker](https://img.shields.io/badge/Docker-Ready-blue?logo=docker)](https://www.docker.com/)
[![CUDA](https://img.shields.io/badge/CUDA-Enabled-green?logo=nvidia)](https://developer.nvidia.com/cuda-zone)
[![License](https://img.shields.io/badge/License-MPL%202.0-orange)](LICENSE)

**Local GPU-accelerated AI voice conversation system with voice cloning capabilities.**

Have natural conversations with AI using your own voice. Complete privacy - runs entirely on your hardware with no cloud services, no API keys, no subscriptions.

---
<img width="916" height="528" alt="immagine" src="https://github.com/user-attachments/assets/184abc8c-064b-44d8-9248-c24fce314fdc" />

<img width="945" height="576" alt="immagine" src="https://github.com/user-attachments/assets/b38a8345-41fa-46c0-9245-91a1e11a8608" />


<a href="https://www.buymeacoffee.com/manzolo">
  <img src=".github/blue-button.png" alt="Buy Me A Coffee" width="200">
</a>

## ✨ Features

### 🤖 AI Voice Conversations
- **Natural Dialogue**: Speak to AI and hear responses in natural voice
- **Voice Cloning**: AI responds using your own voice or any custom voice profile
- **Multilingual**: Supports 16+ languages for both input and output
- **Offline-First**: All processing happens locally on your hardware

### 🗣️ Text-to-Speech (XTTS v2)
- **16+ Languages**: Italian, English, Spanish, French, German, Portuguese, and more
- **Voice Cloning**: Clone any voice with just 3-5 audio samples
- **GPU Accelerated**: Fast generation with NVIDIA CUDA
- **High Quality**: Professional-grade voice synthesis

### 🎧 Speech-to-Text (Faster-Whisper)
- **State-of-the-art Accuracy**: Whisper Large-v3 model
- **Multi-format Support**: Audio and video files
- **Real-time Processing**: GPU-accelerated transcription
- **OpenAI Compatible**: Drop-in replacement for OpenAI Whisper API

### 🧠 Local LLM (Ollama)
- **Privacy-Focused**: Conversations stay on your machine
- **Optimized Models**: TinyLlama (1.1B) optimized for 8GB VRAM systems
- **Extensible**: Support for larger models (Llama, Mistral, etc.)
- **Fast Responses**: GPU-accelerated inference

### 🌐 Web Interface
- **Multilingual UI**: 16+ languages
- **Responsive Design**: Works on desktop and mobile
- **Real-time Interaction**: Record, process, and play responses
- **Conversation History**: Track your dialogue with AI

---

## 🚀 Quick Start

### Prerequisites
- Docker and Docker Compose
- **For GPU mode**: NVIDIA GPU with CUDA support + NVIDIA Container Toolkit
- **For CPU mode**: Any system (no GPU required, but slower)
- **Recommended**: 8GB+ VRAM for GPU mode, 16GB+ RAM for CPU mode

### Installation

1. **Clone the repository**:
   ```bash
   git clone https://github.com/manzolo/ai-voice-offline.git
   cd ai-voice-offline
   ```

2. **Choose your mode**:

   **GPU Mode (Recommended - Requires NVIDIA GPU)**:
   ```bash
   make setup-gpu
   ```

   **CPU Mode (Slower - No GPU Required)**:
   ```bash
   make setup
   ```

   This will:
   - Build Docker images
   - Download AI models (~8GB total: TTS, STT, and LLM)
   - Start all services
   - Initialize the web interface

3. **Download the LLM model**:
   ```bash
   make pull-ollama-model
   ```
   This downloads TinyLlama (1.1B parameters, ~600MB)

4. **Setup voice cloning** (optional):
   ```bash
   make setup-voice
   ```
   This guides you through recording voice samples for cloning your voice.

   Alternatively, manually upload WAV files:
   ```bash
   make setup-voice-upload
   ```

5. **Access the application**:
   - **Web UI**: http://localhost:8080
   - **Conversation API**: http://localhost:9877
   - **TTS API**: http://localhost:9876
   - **STT API**: http://localhost:10300
   - **Ollama API**: http://localhost:11434

### CPU vs GPU Mode

| Feature | CPU Mode | GPU Mode |
|---------|----------|----------|
| **Command** | `make up` | `make up-gpu` |
| **Speed** | Slower (30-60s per exchange) | Fast (3-10s per exchange) |
| **Requirements** | Any system | NVIDIA GPU + CUDA |
| **VRAM/RAM** | 16GB+ RAM | 8GB+ VRAM |
| **Quality** | Identical | Identical |

**Switching modes**: Simply stop services with `make down` and start with the desired mode.

---

## 📖 Usage

### Web Interface

1. Open http://localhost:8080 in your browser
2. Select your language
3. **For voice conversation**:
   - Click the microphone to record your question
   - Wait for AI to process (STT → LLM → TTS)
   - Listen to the AI's voice response
4. **For text conversation**:
   - Type your message
   - Get text or voice responses

### Conversation API

#### Voice Conversation (Audio → AI → Audio)
```bash
curl -X POST http://localhost:9877/api/conversation \
  -F "audio=@question.wav" \
  -F "language=en" \
  --output response.wav
```

#### Text Conversation (Text → AI → Audio)
```bash
curl -X POST http://localhost:9877/api/conversation/text \
  -H "Content-Type: application/json" \
  -d '{
    "text": "What is the weather like today?",
    "language": "en"
  }' \
  --output response.wav
```

See [API_EXAMPLES.md](API_EXAMPLES.md) for more examples.

---

## ⚙️ Configuration

Edit `.env` to customize settings:

```env
# Language & Voice
DEFAULT_LANGUAGE=en           # Default: English (en, it, es, fr, de, pt, etc.)
DEFAULT_SPEAKER=male          # male or female (for non-cloned voices)

# Voice Cloning
VOICE_PROFILE=default         # Voice profile to use (from voice-profiles/)

# Ports
TTS_PORT=9876                 # Text-to-Speech service
STT_PORT=10300                # Speech-to-Text service
OLLAMA_PORT=11434             # Ollama LLM service
CONVERSATION_PORT=9877        # Conversation orchestrator

# GPU
CUDA_VISIBLE_DEVICES=0        # GPU device ID

# AI Models
WHISPER_MODEL=large-v3        # large-v3, medium, small
OLLAMA_MODEL=tinyllama:1.1b   # tinyllama:1.1b, llama2:7b, mistral:7b, etc.

# Timeouts (seconds)
STT_TIMEOUT=120               # Speech-to-text timeout
OLLAMA_TIMEOUT=90             # LLM response timeout
TTS_TIMEOUT=180               # Text-to-speech timeout (voice cloning needs more time)
```

---

## 🛠️ Makefile Commands

| Command | Description |
|---------|-------------|
| `make setup` | Initial setup (CPU mode) |
| `make setup-gpu` | Initial setup (GPU mode - requires NVIDIA GPU) |
| `make up` | Start services in CPU mode |
| `make up-gpu` | Start services in GPU mode |
| `make down` | Stop all services |
| `make restart` | Restart services |
| `make logs` | View all logs |
| `make logs-conversation` | View conversation service logs |
| `make logs-tts` | View TTS logs |
| `make logs-whisper` | View STT logs |
| `make logs-ollama` | View Ollama LLM logs |
| `make status` | Check service status |
| `make pull-ollama-model` | Download TinyLlama model |
| `make setup-voice` | Setup voice cloning (containerized recording) |
| `make setup-voice-upload` | Upload pre-recorded voice samples |
| `make debug-audio` | Debug audio device access |
| `make check-services` | Check if all services are ready |
| `make test-conversation` | Test conversation API health |
| `make test-ollama` | Test Ollama API |
| `make clean` | Remove containers |
| `make clean-all` | Remove everything (including models) |

Run `make help` for the complete list.

---

## 📁 Project Structure

```
ai-voice-offline/
├── docker-compose.yml          # CPU mode orchestration
├── docker-compose.gpu.yml      # GPU mode orchestration
├── Makefile                    # Automation commands
├── .env                        # Configuration
├── tts-service/               # Custom TTS server with voice cloning
│   ├── Dockerfile
│   ├── app.py                 # FastAPI server
│   └── requirements.txt
├── conversation-service/      # Conversation orchestrator
│   ├── Dockerfile
│   ├── app.py                 # STT → LLM → TTS pipeline
│   └── requirements.txt
├── web-conversation/          # Web interface
│   └── index.html             # Single-page conversation app
├── voice-profiles/            # Voice cloning samples
│   └── default/               # Default voice profile
├── scripts/                   # Voice recording utilities
│   ├── Dockerfile
│   └── setup_voice_profile.py
├── tts_models/                # TTS model cache (auto-created)
├── whisper-cache/             # Whisper model cache (auto-created)
└── ollama-models/             # Ollama model cache (auto-created)
```

---

## 🎤 Voice Cloning Guide

### Option 1: Containerized Recording (Recommended)

```bash
make setup-voice
```

This launches a containerized recording session that:
1. Detects your microphone
2. Guides you through recording 3-5 voice samples
3. Saves samples to `voice-profiles/default/`

### Option 2: Manual Upload

Record 3-5 audio samples (2-3 seconds each) on your phone or computer:
- Clear audio with no background noise
- Natural speaking voice
- Different sentences for variety

Then:
```bash
# Place WAV files in voice-profiles/default/
cp sample_1.wav voice-profiles/default/
cp sample_2.wav voice-profiles/default/
cp sample_3.wav voice-profiles/default/

# Verify setup
make setup-voice-upload
```

### Troubleshooting Audio

If microphone access fails:
```bash
make debug-audio  # Diagnose audio device issues
```

---

## 🌍 Supported Languages

**TTS (XTTS v2)**: English, Italian, Spanish, French, German, Portuguese, Polish, Turkish, Russian, Dutch, Czech, Arabic, Chinese, Japanese, Hungarian, Korean

**STT (Whisper)**: 99+ languages including all above

**LLM**: Depends on model (TinyLlama supports English primarily)

---

## 🧪 Testing

Run automated tests:
```bash
make check-services      # Check all services are healthy
make test-conversation   # Test conversation API
make test-ollama         # Test Ollama LLM
```

---

## 🐛 Troubleshooting

### Services won't start
```bash
# Check container status
make status

# View logs
make logs

# Check specific service
make logs-conversation
make logs-tts
make logs-whisper
make logs-ollama

# Restart services
make restart
```

### GPU not detected
```bash
# Verify NVIDIA runtime
docker run --rm --gpus all nvidia/cuda:12.1.0-base-ubuntu22.04 nvidia-smi

# Check CUDA in containers
docker exec xtts nvidia-smi
docker exec faster-whisper nvidia-smi
```

### Models not downloading
- Ensure you have internet connectivity
- Check disk space (need ~8GB free)
- Models download on first use, be patient
- For Ollama: run `make pull-ollama-model` explicitly

### Conversation is slow
- Use GPU mode for 10x speedup
- Reduce model sizes in `.env`:
  - `WHISPER_MODEL=medium` (instead of large-v3)
  - `OLLAMA_MODEL=tinyllama:1.1b` (already optimized)
- Increase timeouts if requests fail

### Voice cloning not working
- Ensure voice samples are in `voice-profiles/default/`
- Samples should be WAV format, 24kHz, 2-3 seconds each
- Need at least 3 samples for good quality
- Check TTS logs: `make logs-tts`

---

## 📊 Performance

**Full Conversation Cycle (Audio → Response)**:
- **GPU mode**: 3-10 seconds
  - STT: ~1-2s
  - LLM: ~1-3s
  - TTS: ~1-5s
- **CPU mode**: 30-60 seconds
  - STT: ~10-20s
  - LLM: ~5-10s
  - TTS: ~15-30s

**Recommended Hardware**:
- GPU: NVIDIA RTX 3060 or better (8GB+ VRAM)
- CPU: Modern multi-core processor
- RAM: 16GB+ for CPU mode, 8GB+ for GPU mode
- Storage: 10GB+ free space

---

## 🤝 Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

---

## 📝 License

This project uses:
- **Coqui TTS**: Mozilla Public License 2.0
- **Faster-Whisper**: MIT License
- **Ollama**: MIT License

See individual components for their respective licenses.

---

## 🙏 Acknowledgments

- [Coqui TTS](https://github.com/coqui-ai/TTS) - Text-to-Speech with voice cloning
- [Faster-Whisper](https://github.com/SYSTRAN/faster-whisper) - Speech-to-Text engine
- [Ollama](https://ollama.ai/) - Local LLM runtime
- [XTTS v2](https://huggingface.co/coqui/XTTS-v2) - Multilingual voice cloning model

---

**Made with ❤️ for the open-source community**
