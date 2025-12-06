.PHONY: help setup setup-gpu build up up-gpu down restart logs status clean clean-all
.PHONY: test-ollama test-conversation pull-ollama-model check-services
.PHONY: logs-tts logs-whisper logs-ollama logs-conversation
.PHONY: setup-voice setup-voice-upload debug-audio

# Default target
help:
	@echo "AI Voice Offline - Conversation Service"
	@echo ""
	@echo "🚀 Quick Start:"
	@echo "  make setup          - Initial setup (CPU mode)"
	@echo "  make setup-gpu      - Initial setup (GPU mode)"
	@echo ""
	@echo "Setup & Build:"
	@echo "  make build          - Build Docker images"
	@echo ""
	@echo "Start Services:"
	@echo "  make up             - Start all services (CPU mode)"
	@echo "  make up-gpu         - Start all services (GPU mode)"
	@echo ""
	@echo "Stop Services:"
	@echo "  make down           - Stop all services"
	@echo ""
	@echo "Operations:"
	@echo "  make restart        - Restart all services"
	@echo "  make logs           - Show logs (all services)"
	@echo "  make logs-tts       - Show TTS logs"
	@echo "  make logs-whisper   - Show Whisper logs"
	@echo "  make logs-ollama    - Show Ollama logs"
	@echo "  make logs-conversation - Show conversation service logs"
	@echo "  make status         - Show container status"
	@echo ""
	@echo "Cleanup:"
	@echo "  make clean          - Stop services and remove containers"
	@echo "  make clean-all      - Remove everything (containers + volumes + models)"
	@echo ""
	@echo "Testing:"
	@echo "  make test-ollama       - Test Ollama API"
	@echo "  make test-conversation - Test conversation API"
	@echo "  make check-services    - Check if all services are ready"
	@echo ""
	@echo "Ollama:"
	@echo "  make pull-ollama-model - Download TinyLlama model"
	@echo ""
	@echo "Voice Setup:"
	@echo "  make setup-voice        - Setup voice profile for cloning (containerized)"
	@echo "  make setup-voice-upload - Alternative: Upload pre-recorded samples"
	@echo "  make debug-audio        - Debug audio devices (if recording fails)"

# Initial setup - CPU mode (default)
setup:
	@echo "🚀 Starting initial setup (CPU mode)..."
	@if [ ! -f .env ]; then \
		echo "📝 Creating .env from .env.example..."; \
		cp .env.example .env; \
	else \
		echo "✅ .env file already exists"; \
	fi
	@echo "📦 Building Docker images..."
	docker compose build
	@echo "🔧 Creating necessary directories..."
	@mkdir -p tts_models whisper-cache voice-profiles ollama-models
	@echo "🚀 Starting services (CPU mode)..."
	docker compose up -d
	@echo "⏳ Waiting for services to initialize (60s)..."
	@sleep 60
	@echo "✅ Setup complete! Services are running in CPU mode."
	@echo ""
	@echo "🌐 Web Interface:"
	@echo "  - Conversation: http://localhost:8080"
	@echo ""
	@echo "💡 Next steps:"
	@echo "  1. Run 'make pull-ollama-model' to download the LLM"
	@echo "  2. Run 'make setup-voice' to configure voice cloning"
	@echo "  3. Visit http://localhost:8080 to start chatting"
	@echo ""
	@echo "📊 Check status with: make status"

# Initial setup - GPU mode
setup-gpu:
	@echo "🚀 Starting initial setup (GPU mode)..."
	@if [ ! -f .env ]; then \
		echo "📝 Creating .env from .env.example..."; \
		cp .env.example .env; \
	else \
		echo "✅ .env file already exists"; \
	fi
	@echo "📦 Building Docker images..."
	docker compose -f docker-compose.gpu.yml build
	@echo "🔧 Creating necessary directories..."
	@mkdir -p tts_models whisper-cache voice-profiles ollama-models
	@echo "🚀 Starting services (GPU mode)..."
	docker compose -f docker-compose.gpu.yml up -d
	@echo "⏳ Waiting for services to initialize (60s)..."
	@sleep 60
	@echo "✅ Setup complete! Services are running in GPU mode."
	@echo ""
	@echo "🌐 Web Interface:"
	@echo "  - Conversation: http://localhost:8080"
	@echo ""
	@echo "💡 Next steps:"
	@echo "  1. Run 'make pull-ollama-model' to download the LLM"
	@echo "  2. Run 'make setup-voice' to configure voice cloning"
	@echo "  3. Visit http://localhost:8080 to start chatting"
	@echo ""
	@echo "📊 Check status with: make status"

# Build images
build:
	docker compose build

# Start services (CPU mode - default)
up:
	@echo "🚀 Starting all services in CPU mode..."
	docker compose up -d

# Start services (GPU mode)
up-gpu:
	@echo "🚀 Starting all services in GPU mode..."
	docker compose -f docker-compose.gpu.yml up -d

# Stop services
down:
	@echo "🛑 Stopping all services..."
	@docker compose down 2>/dev/null || true
	@docker compose -f docker-compose.gpu.yml down 2>/dev/null || true

# Restart services
restart:
	docker compose restart

# Show all logs
logs:
	docker compose logs -f

# Show TTS logs
logs-tts:
	@echo "📋 TTS Service Logs:"
	@docker compose logs -f xtts

# Show Whisper logs
logs-whisper:
	@echo "📋 Whisper Service Logs:"
	@docker compose logs -f faster-whisper

# Show Ollama logs
logs-ollama:
	@echo "📋 Ollama Service Logs:"
	@docker compose logs -f ollama

# Show conversation service logs
logs-conversation:
	@echo "📋 Conversation Service Logs:"
	@docker compose logs -f conversation

# Show container status
status:
	@echo "📊 Container Status:"
	@docker compose ps
	@echo ""
	@echo "💾 Volume Usage:"
	@du -sh tts_models whisper-cache ollama-models voice-profiles 2>/dev/null || echo "No volumes found"

# Stop and remove containers
clean:
	@echo "🧹 Stopping and removing containers..."
	@docker compose down 2>/dev/null || true
	@docker compose -f docker-compose.gpu.yml down 2>/dev/null || true
	@echo "✅ Cleanup complete"

# Remove everything including models
clean-all:
	@echo "⚠️  WARNING: This will remove all containers, volumes, and downloaded models!"
	@echo "Press Ctrl+C to cancel, or wait 5 seconds to continue..."
	@sleep 5
	@echo "🧹 Removing all containers and volumes..."
	@docker compose down -v 2>/dev/null || true
	@docker compose -f docker-compose.gpu.yml down -v 2>/dev/null || true
	@echo "🧹 Removing all volume directories..."
	@rm -rf tts_models whisper-cache ollama-models voice-profiles
	@echo "✅ Complete cleanup done"

# Pull Ollama model
pull-ollama-model:
	@echo "📥 Pulling Ollama model (tinyllama:1.1b)..."
	@docker exec ollama ollama pull tinyllama:1.1b

# Test Ollama API
test-ollama:
	@echo "🧪 Testing Ollama API..."
	@curl -s http://localhost:11434/api/tags && \
		echo "✅ Ollama service is healthy" || \
		echo "❌ Ollama service is not responding"

# Test conversation API
test-conversation:
	@echo "🧪 Testing Conversation API..."
	@curl -s http://localhost:9877/health && \
		echo "✅ Conversation service is healthy" || \
		echo "❌ Conversation service is not responding"

# Check all services are ready
check-services:
	@echo "🔍 Checking all services..."
	@echo ""
	@echo "📊 TTS Service (http://localhost:9876):"
	@TTS_STATUS=$$(curl -s -w "\n%{http_code}" http://localhost:9876/ 2>/dev/null); \
	if [ "$$(echo "$$TTS_STATUS" | tail -n1)" = "200" ]; then \
		echo "  ✅ Status: Running"; \
		echo "$$TTS_STATUS" | head -n-1 | python3 -c "import sys, json; data=json.load(sys.stdin); print(f\"  🎤 Model: {data.get('model', 'unknown')}\"); print(f\"  🚀 GPU: {'Enabled' if data.get('gpu') else 'Disabled'}\"); print(f\"  🌍 Languages: {len(data.get('supported_languages', []))} supported\"); print(f\"  👥 Speakers: {', '.join(data.get('speakers', [])[:4])}{'...' if len(data.get('speakers', [])) > 4 else ''}\")"; \
	else \
		echo "  ❌ Not responding"; \
	fi
	@echo ""
	@echo "📊 STT Service (http://localhost:10300):"
	@STT_STATUS=$$(curl -s -w "\n%{http_code}" http://localhost:10300/health 2>/dev/null); \
	if [ "$$(echo "$$STT_STATUS" | tail -n1)" = "200" ]; then \
		echo "  ✅ Status: Running"; \
		echo "  🎧 Model: Whisper (Faster-Whisper)"; \
	else \
		echo "  ❌ Not responding"; \
	fi
	@echo ""
	@echo "📊 Ollama Service (http://localhost:11434):"
	@OLLAMA_STATUS=$$(curl -s -w "\n%{http_code}" http://localhost:11434/api/tags 2>/dev/null); \
	if [ "$$(echo "$$OLLAMA_STATUS" | tail -n1)" = "200" ]; then \
		echo "  ✅ Status: Running"; \
		echo "$$OLLAMA_STATUS" | head -n-1 | python3 -c "import sys, json; data=json.load(sys.stdin); models=data.get('models', []); print(f\"  🧠 Loaded models: {len(models)}\"); [print(f\"     - {m['name']} ({m['details'].get('parameter_size', 'unknown')} params, {round(m['size']/1024/1024/1024, 2)}GB)\") for m in models[:3]]; print(f\"     ... and {len(models)-3} more\") if len(models) > 3 else None"; \
	else \
		echo "  ❌ Not responding"; \
		echo "  💡 Run: make pull-ollama-model"; \
	fi
	@echo ""
	@echo "📊 Conversation Service (http://localhost:9877):"
	@CONV_STATUS=$$(curl -s -w "\n%{http_code}" http://localhost:9877/health 2>/dev/null); \
	if [ "$$(echo "$$CONV_STATUS" | tail -n1)" = "200" ]; then \
		echo "  ✅ Status: Healthy"; \
		echo "  🔄 Pipeline: STT → LLM → TTS"; \
	else \
		echo "  ❌ Not responding"; \
	fi
	@echo ""
	@echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
	@ALL_UP=true; \
	for port in 9876 10300 11434 9877; do \
		curl -s -o /dev/null -w "%{http_code}" http://localhost:$$port 2>/dev/null | grep -q "200" || ALL_UP=false; \
	done; \
	if [ "$$ALL_UP" = "true" ]; then \
		echo "✅ All services are ready!"; \
		echo "🌐 Open web interface: http://localhost:8080"; \
	else \
		echo "⚠️  Some services are not ready"; \
		echo "💡 Wait 30-60 seconds for model loading, then retry"; \
		echo "💡 Check logs with: make logs"; \
		exit 1; \
	fi

# Setup voice profile (runs in container)
setup-voice:
	@echo "🎤 Setting up voice profile..."
	@echo "📦 Building voice recording container..."
	@docker build -t ai-voice-offline-recorder -f scripts/Dockerfile scripts/
	@echo "🎙️  Starting voice recording session..."
	@echo "⚠️  If audio device access fails, use 'make setup-voice-upload' instead"
	@echo ""
	@if [ -d "/run/user/$(shell id -u)/pulse" ]; then \
		echo "🔊 Using PulseAudio..."; \
		docker run -it --rm \
			--device /dev/snd \
			-v $(PWD)/voice-profiles:/app/voice-profiles \
			-e PULSE_SERVER=unix:/run/user/$(shell id -u)/pulse/native \
			-v /run/user/$(shell id -u)/pulse:/run/user/$(shell id -u)/pulse \
			ai-voice-offline-recorder; \
	else \
		echo "🔊 Using ALSA (direct device access)..."; \
		docker run -it --rm \
			--device /dev/snd \
			-v $(PWD)/voice-profiles:/app/voice-profiles \
			--group-add audio \
			ai-voice-offline-recorder; \
	fi

# Debug audio devices
debug-audio:
	@echo "🔍 Debugging audio devices..."
	@echo ""
	@echo "=== Host Audio Devices ==="
	@echo "ALSA devices:"
	@-arecord -l 2>/dev/null || echo "  (arecord not installed)"
	@echo ""
	@echo "Sound devices:"
	@-ls -la /dev/snd/ 2>/dev/null || echo "  /dev/snd not found"
	@echo ""
	@echo "=== Container Audio Test ==="
	@docker build -q -t ai-voice-offline-recorder -f scripts/Dockerfile scripts/
	@docker run --rm --device /dev/snd ai-voice-offline-recorder python3 -c "\
		import sounddevice as sd; \
		print('Available audio devices:'); \
		print(sd.query_devices()); \
		print('\\nDefault input device:', sd.default.device[0]); \
		print('Supported sample rates will be detected during recording.'); \
	" || echo "❌ Container cannot access audio devices"
	@echo ""
	@echo "💡 If no devices found, try 'make setup-voice-upload' for manual upload"

# Alternative: Upload pre-recorded voice samples
setup-voice-upload:
	@echo "📁 Setting up voice profile from uploaded files..."
	@echo ""
	@echo "Please place 3-5 WAV files (24kHz, 2-3 seconds each) in:"
	@echo "  $(PWD)/voice-profiles/default/"
	@echo ""
	@echo "Sample files should be named:"
	@echo "  - sample_1.wav"
	@echo "  - sample_2.wav"
	@echo "  - sample_3.wav"
	@echo ""
	@echo "You can record these on your phone or computer, then transfer them."
	@echo "Make sure they are clear recordings of your voice speaking naturally."
	@echo ""
	@read -p "Press Enter once you've placed the files..." dummy
	@if [ -f "$(PWD)/voice-profiles/default/sample_1.wav" ]; then \
		echo "✅ Found voice samples!"; \
		ls -lh $(PWD)/voice-profiles/default/*.wav; \
	else \
		echo "❌ No voice samples found. Please add WAV files first."; \
	fi
