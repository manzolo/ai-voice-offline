# AI Voice Offline - API Examples

## Configuration

Edit the `.env` file to change default settings:
```env
DEFAULT_LANGUAGE=it
DEFAULT_SPEAKER=male
TTS_PORT=9876
STT_PORT=10300
```

## Text-to-Speech API (XTTS)

**Endpoint:** `POST http://localhost:9876/api/tts`

### Example 1: Simple TTS (uses defaults from .env)
```bash
curl -X POST http://localhost:9876/api/tts \
  -H "Content-Type: application/json" \
  -d '{"text": "Ciao! Questo è un test"}' \
  --output output.wav
```

### Example 2: Italian Male Voice
```bash
curl -X POST http://localhost:9876/api/tts \
  -H "Content-Type: application/json" \
  -d '{
    "text": "Buongiorno! Come stai oggi?",
    "language": "it",
    "speaker": "male"
  }' \
  --output italian_male.wav
```

### Example 3: Italian Female Voice
```bash
curl -X POST http://localhost:9876/api/tts \
  -H "Content-Type: application/json" \
  -d '{
    "text": "Ciao! Benvenuto nel nostro sistema.",
    "language": "it",
    "speaker": "female"
  }' \
  --output italian_female.wav
```

### Example 4: English Male Voice
```bash
curl -X POST http://localhost:9876/api/tts \
  -H "Content-Type: application/json" \
  -d '{
    "text": "Hello! This is a test of the English voice.",
    "language": "en",
    "speaker": "male"
  }' \
  --output english_male.wav
```

### Example 5: English Female Voice
```bash
curl -X POST http://localhost:9876/api/tts \
  -H "Content-Type: application/json" \
  -d '{
    "text": "Welcome to our text to speech system!",
    "language": "en",
    "speaker": "female"
  }' \
  --output english_female.wav
```

### Python Example
```python
import requests

response = requests.post(
    "http://localhost:9876/api/tts",
    json={
        "text": "Ciao! Questo è un test di sintesi vocale.",
        "language": "it",
        "speaker": "male"
    }
)

with open("output.wav", "wb") as f:
    f.write(response.content)
```

### JavaScript Example
```javascript
fetch("http://localhost:9876/api/tts", {
  method: "POST",
  headers: {"Content-Type": "application/json"},
  body: JSON.stringify({
    text: "Ciao! Questo è un test.",
    language: "it",
    speaker: "female"
  })
})
.then(response => response.blob())
.then(blob => {
  const url = URL.createObjectURL(blob);
  const audio = new Audio(url);
  audio.play();
});
```

## Speech-to-Text API (Faster-Whisper)

**Endpoint:** `POST http://localhost:10300/v1/audio/transcriptions`

### Example: Transcribe Audio File
```bash
curl -X POST http://localhost:10300/v1/audio/transcriptions \
  -H "Content-Type: multipart/form-data" \
  -F "file=@your_audio_file.mp3" \
  -F "model=large-v3" \
  -F "language=it"
```

### Python Example
```python
import requests

with open("audio_file.mp3", "rb") as f:
    response = requests.post(
        "http://localhost:10300/v1/audio/transcriptions",
        files={"file": f},
        data={"model": "large-v3", "language": "it"}
    )

print(response.json())
```

## System Status

### Check TTS Server Status
```bash
curl http://localhost:9876/
```

Response:
```json
{
  "status": "running",
  "model": "xtts_v2",
  "gpu": true,
  "supported_languages": ["en", "it", "es", "fr", "de", "pt", "pl", "tr", "ru", "nl", "cs", "ar", "zh-cn", "ja"],
  "speakers": ["male", "female"]
}
```

## Supported Languages

XTTS v2 supports:
- **en** - English
- **it** - Italian
- **es** - Spanish
- **fr** - French
- **de** - German
- **pt** - Portuguese
- **pl** - Polish
- **tr** - Turkish
- **ru** - Russian
- **nl** - Dutch
- **cs** - Czech
- **ar** - Arabic
- **zh-cn** - Chinese
- **ja** - Japanese
