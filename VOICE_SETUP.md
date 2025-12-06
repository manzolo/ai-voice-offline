# Voice Profile Setup Guide

This guide will help you set up your voice profile for voice cloning in the AI Voice Assistant.

## Method 1: Containerized Recording (Recommended)

This method runs everything in a Docker container - no host packages needed!

```bash
make setup-voice
```

The container will:
1. Build automatically with all required audio packages
2. Access your microphone through Docker device mapping
3. Guide you through recording 3 voice samples
4. Save samples to `voice-profiles/default/`

### Troubleshooting Audio Access

If you get audio device errors, the script now **auto-detects** supported sample rates and will try common rates like 48000Hz or 44100Hz.

**Quick debug command:**
```bash
make debug-audio
```
This shows available audio devices and tests container access.

**Common issues:**

**1. "Invalid sample rate" error**
- ✅ **FIXED**: Script now auto-detects supported rates
- Records at device's native rate (48kHz, 44.1kHz, etc.)
- Automatically resamples to 24kHz for XTTS v2

**2. "No audio device found"**
```bash
# Check if device exists
ls /dev/snd/

# List available devices
arecord -l
```

**3. "Permission denied" on /dev/snd**
```bash
# Add your user to audio group
sudo usermod -a -G audio $USER
# Log out and back in
```

**4. For PulseAudio systems:**
```bash
# Make sure PulseAudio is running
pulseaudio --check
```

**5. Still having issues?**
Use Method 2 (manual upload) - it's simple and works everywhere!

## Method 2: Manual Upload (Alternative)

If containerized recording doesn't work, you can record on any device and upload:

### Step 1: Record Audio Samples

Record 3-5 clips of yourself speaking (2-3 seconds each):

**On Your Phone:**
- Use any voice recorder app
- Speak clearly and naturally
- Export as WAV or MP3

**On Your Computer:**
- Use Audacity, QuickTime, or any audio recorder
- Settings: 24kHz sample rate (or any rate, will be converted)
- Speak clearly in a quiet environment

### Step 2: Prepare Files

Samples should be:
- **Duration**: 2-3 seconds each
- **Format**: WAV preferred (MP3 also works)
- **Content**: Natural speech, varying intonation
- **Quality**: Clear audio, minimal background noise

### Step 3: Place Files

Name your files and place them in `voice-profiles/default/`:

```
voice-profiles/default/
├── sample_1.wav
├── sample_2.wav
└── sample_3.wav
```

### Step 4: Verify

Run the upload command to verify:

```bash
make setup-voice-upload
```

## What to Say When Recording

Here are suggested phrases (but you can say anything):

1. **Sample 1**: "Hello, this is a test of my voice for cloning."
2. **Sample 2**: "I'm creating a custom voice profile for the AI assistant."
3. **Sample 3**: "How are you doing today? I hope you're having a great time!"

**Tips:**
- Speak naturally, as if talking to a friend
- Vary your intonation across samples
- Use consistent volume and distance from mic
- Record in a quiet location

## Technical Requirements

### For Containerized Recording:
- Docker with audio device access (`/dev/snd`)
- Linux: PulseAudio or ALSA
- Microphone connected and working

### For Manual Upload:
- Audio files in WAV format (24kHz recommended)
- Or MP3 files (will be converted automatically)
- 3-5 samples, 2-3 seconds each

## Verification

After setup, verify your voice profile:

```bash
# Check if samples exist
ls -lh voice-profiles/default/

# Should show:
# sample_1.wav
# sample_2.wav
# sample_3.wav
```

## Using Your Voice Profile

Once set up, your voice profile is automatically used by the conversation service.

The setting is in `.env`:
```bash
VOICE_PROFILE=default
```

To create multiple profiles (e.g., for different family members):

1. Create new directory: `mkdir -p voice-profiles/alice`
2. Place samples in `voice-profiles/alice/`
3. Change `.env`: `VOICE_PROFILE=alice`
4. Restart services: `make restart`

## Quality Tips

For best voice cloning results:

✅ **Do:**
- Record in a quiet room
- Speak naturally and clearly
- Use consistent microphone distance
- Vary intonation across samples
- Include some emotion/personality

❌ **Don't:**
- Whisper or shout
- Record with background noise
- Use robotic/monotone voice
- Speak too fast or too slow
- Use inconsistent volume

## Troubleshooting

### "No audio device found"
- **Solution**: Use Method 2 (manual upload)
- Or check if your mic is connected: `arecord -l`

### "Audio too quiet"
- Speak louder or move closer to mic
- Check microphone volume in system settings

### "No speech detected"
- Ensure you're speaking during recording
- Check if microphone is muted

### Voice cloning quality is poor
- Re-record with better quality samples
- Ensure quiet environment
- Speak more naturally (not monotone)
- Try recording more samples (4-5 instead of 3)

## Next Steps

After setting up your voice profile:

1. Start services: `make up-gpu`
2. Pull Ollama model: `make pull-ollama-model`
3. Open conversation UI: http://localhost:8080
4. Start talking!

## Advanced: Custom Sample Rate

If you need a specific sample rate, you can convert existing files:

```bash
# Convert MP3 to 24kHz WAV
ffmpeg -i input.mp3 -ar 24000 -ac 1 sample_1.wav

# Convert any audio to correct format
ffmpeg -i input.m4a -ar 24000 -ac 1 sample_2.wav
```

## Support

If you encounter issues:

1. Check logs: `make logs-conversation`
2. Test TTS service: `make test-tts`
3. Verify samples exist: `ls voice-profiles/default/`
4. Check container: `docker ps | grep conversation`

For more help, see the main README.md or open an issue on GitHub.
