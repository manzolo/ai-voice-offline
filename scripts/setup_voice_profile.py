#!/usr/bin/env python3
"""
Voice Profile Setup Script for AI Voice Offline
Records audio samples for voice cloning with XTTS v2
"""

import os
import sys
import json
from datetime import datetime

try:
    import sounddevice as sd
    import soundfile as sf
    import numpy as np
except ImportError:
    print("Error: Required packages not installed.")
    print("Please install them with: pip install sounddevice soundfile numpy")
    sys.exit(1)


def list_audio_devices():
    """List available audio input devices."""
    print("\n📱 Available audio input devices:")
    devices = sd.query_devices()
    for i, device in enumerate(devices):
        if device['max_input_channels'] > 0:
            print(f"  [{i}] {device['name']} (inputs: {device['max_input_channels']})")
    return devices


def select_device():
    """Let user select an audio input device."""
    devices = list_audio_devices()
    while True:
        try:
            device_id = input("\nSelect device ID (or press Enter for default): ").strip()
            if device_id == "":
                return None  # Use default
            device_id = int(device_id)
            if 0 <= device_id < len(devices) and devices[device_id]['max_input_channels'] > 0:
                return device_id
            print("Invalid device ID. Please try again.")
        except ValueError:
            print("Please enter a valid number.")


def get_supported_samplerate(device=None):
    """
    Detect a supported sample rate for the audio device.

    Returns:
        Supported sample rate (Hz)
    """
    # Try common sample rates in order of preference
    test_rates = [48000, 44100, 22050, 16000, 8000]

    for rate in test_rates:
        try:
            # Test if this rate works by trying to open a stream
            sd.check_input_settings(device=device, channels=1, dtype='float32', samplerate=rate)
            print(f"   ✓ Using sample rate: {rate}Hz")
            return rate
        except Exception:
            continue

    # Fallback to 44100 if nothing works
    print(f"   ⚠️  Using fallback rate: 44100Hz")
    return 44100


def resample_audio(audio, orig_rate, target_rate=24000):
    """
    Resample audio to target rate using simple interpolation.

    Args:
        audio: numpy array with audio data
        orig_rate: Original sample rate
        target_rate: Target sample rate (24000 for XTTS v2)

    Returns:
        Resampled audio array
    """
    if orig_rate == target_rate:
        return audio

    # Calculate new length
    duration = len(audio) / orig_rate
    new_length = int(duration * target_rate)

    # Linear interpolation (simple but effective)
    old_indices = np.linspace(0, len(audio) - 1, len(audio))
    new_indices = np.linspace(0, len(audio) - 1, new_length)
    resampled = np.interp(new_indices, old_indices, audio.flatten())

    return resampled.reshape(-1, 1)


def record_sample(duration=3, device=None):
    """
    Record an audio sample at device's supported rate.

    Args:
        duration: Recording duration in seconds
        device: Audio input device ID (None for default)

    Returns:
        (audio, samplerate) tuple
    """
    print(f"\n🎙️  Recording for {duration} seconds... Speak clearly now!")
    print("   (Speak naturally, as if having a conversation)")

    try:
        # Auto-detect supported sample rate
        samplerate = get_supported_samplerate(device)

        audio = sd.rec(
            int(duration * samplerate),
            samplerate=samplerate,
            channels=1,
            dtype='float32',
            device=device
        )
        sd.wait()  # Wait for recording to complete
        print("   ✓ Recording complete!")
        return audio, samplerate
    except Exception as e:
        print(f"   ✗ Recording failed: {str(e)}")
        return None, None


def validate_audio(audio):
    """
    Validate audio quality.

    Args:
        audio: numpy array with audio data

    Returns:
        (is_valid, message) tuple
    """
    # Check for empty audio
    if audio is None or len(audio) == 0:
        return False, "Empty audio"

    # Check volume level (RMS)
    rms = np.sqrt(np.mean(audio**2))
    if rms < 0.01:
        return False, "Audio too quiet (speak louder or move closer to mic)"

    # Check for clipping
    max_amplitude = np.max(np.abs(audio))
    if max_amplitude > 0.95:
        return False, "Audio clipping detected (speak softer or move away from mic)"

    # Check for silence (at least some variation)
    if max_amplitude < 0.05:
        return False, "No clear speech detected"

    # Calculate SNR estimate (very basic)
    # Assume bottom 10% of amplitude is noise
    sorted_abs = np.sort(np.abs(audio.flatten()))
    noise_level = np.mean(sorted_abs[:len(sorted_abs)//10])
    signal_level = rms

    if signal_level / (noise_level + 1e-10) < 3:
        return False, "Audio too noisy (find quieter location)"

    return True, "OK"


def play_audio(audio, samplerate):
    """Play back recorded audio."""
    try:
        print("   ▶️  Playing back recording...")
        sd.play(audio, samplerate)
        sd.wait()
        print("   ✓ Playback complete")
        return True
    except Exception as e:
        print(f"   ✗ Playback failed: {str(e)}")
        return False


def main():
    print("=" * 60)
    print(" 🎤 AI Voice Offline - Voice Profile Setup")
    print("=" * 60)
    print("\nThis script will help you create a voice profile for voice cloning.")
    print("You'll record 3-5 short audio samples (2-3 seconds each).")
    print("\nTips for best results:")
    print("  • Find a quiet location")
    print("  • Speak naturally and clearly")
    print("  • Use consistent volume and distance from microphone")
    print("  • Vary your intonation across samples")

    # Select audio device
    device = select_device()

    # Get profile name
    print("\n" + "=" * 60)
    profile_name = input("📁 Profile name (press Enter for 'default'): ").strip()
    if not profile_name:
        profile_name = "default"

    # Validate profile name
    if not profile_name.replace("_", "").replace("-", "").isalnum():
        print("❌ Invalid profile name. Use only letters, numbers, hyphens, and underscores.")
        sys.exit(1)

    # Create profile directory
    # Check if running in container (has /app/voice-profiles mount)
    if os.path.exists("/app/voice-profiles"):
        profile_dir = os.path.join("/app/voice-profiles", profile_name)
        print(f"🐳 Running in container mode")
    else:
        # Running on host
        script_dir = os.path.dirname(os.path.abspath(__file__))
        project_root = os.path.dirname(script_dir)
        profile_dir = os.path.join(project_root, "voice-profiles", profile_name)
        print(f"💻 Running on host")

    print(f"📂 Profile directory will be: {profile_dir}")
    print(f"📂 Directory exists: {os.path.exists(profile_dir)}")
    print(f"📂 Parent directory exists: {os.path.exists(os.path.dirname(profile_dir))}")

    if os.path.exists(profile_dir) and os.listdir(profile_dir):
        overwrite = input(f"\n⚠️  Profile '{profile_name}' already exists. Overwrite? (y/N): ").lower()
        if overwrite != 'y':
            print("Aborted.")
            sys.exit(0)

    os.makedirs(profile_dir, exist_ok=True)
    print(f"✅ Profile directory ready: {profile_dir}")

    # Record samples
    print("\n" + "=" * 60)
    print("📝 Sample recording prompts:")
    prompts = [
        "Hello, this is a test of my voice for cloning.",
        "I'm creating a custom voice profile for the AI assistant.",
        "The quick brown fox jumps over the lazy dog.",
        "How are you doing today? I hope you're having a great time!",
        "This technology is amazing and I'm excited to try it out."
    ]

    samples = []
    target_samples = 3

    print(f"\nWe'll record {target_samples} samples. You can re-record any sample if needed.\n")

    i = 0
    while len(samples) < target_samples:
        print("=" * 60)
        print(f"🎬 Sample {len(samples) + 1}/{target_samples}")
        print(f"📝 Suggested text: \"{prompts[i % len(prompts)]}\"")
        print("(You can say anything, this is just a suggestion)")

        input("\n   Press Enter when ready to record...")

        # Record
        audio, orig_rate = record_sample(duration=3, device=device)
        if audio is None:
            continue

        # Validate
        valid, msg = validate_audio(audio)
        if not valid:
            print(f"   ⚠️  Quality issue: {msg}")
            retry = input("   Retry this sample? (Y/n): ").lower()
            if retry != 'n':
                continue
        else:
            print(f"   ✓ Quality: {msg}")

        # Playback
        playback = input("   Listen to playback? (Y/n): ").lower()
        if playback != 'n':
            play_audio(audio, orig_rate)

        # Confirm
        accept = input("   Accept this sample? (Y/n): ").lower()
        if accept != 'n':
            # Resample to 24kHz for XTTS v2
            if orig_rate != 24000:
                print(f"   🔄 Resampling from {orig_rate}Hz to 24000Hz...")
                audio = resample_audio(audio, orig_rate, 24000)

            filename = os.path.join(profile_dir, f"sample_{len(samples) + 1}.wav")
            print(f"   💾 Writing to: {filename}")
            sf.write(filename, audio, 24000)
            print(f"   ✅ File saved successfully")
            print(f"   ℹ️  File exists: {os.path.exists(filename)}")
            print(f"   ℹ️  File size: {os.path.getsize(filename)} bytes")
            samples.append(filename)
        else:
            print("   ↺  Recording another take...")

        i += 1

    # Create profile metadata
    metadata = {
        "profile_name": profile_name,
        "created_at": datetime.now().isoformat(),
        "num_samples": len(samples),
        "sample_rate": 24000,
        "duration_per_sample": 3,
        "samples": [os.path.basename(s) for s in samples]
    }

    metadata_file = os.path.join(profile_dir, "profile.json")
    with open(metadata_file, 'w') as f:
        json.dump(metadata, f, indent=2)
    print(f"\n📄 Saved metadata: {metadata_file}")

    # Final summary
    print("\n" + "=" * 60)
    print("✅ Voice profile setup complete!")
    print("=" * 60)
    print(f"📁 Profile: {profile_name}")
    print(f"📊 Samples: {len(samples)}")
    print(f"📂 Location: {profile_dir}")
    print("\nYour voice profile is ready to use in conversation mode!")
    print(f"To use it, set VOICE_PROFILE={profile_name} in your .env file.")
    print("\nNext steps:")
    print("  1. Start the services: make up-gpu")
    print("  2. Pull the Ollama model: make pull-ollama-model")
    print("  3. Open the conversation interface: http://localhost:8080")


if __name__ == "__main__":
    try:
        main()
    except KeyboardInterrupt:
        print("\n\n⚠️  Interrupted by user. Exiting...")
        sys.exit(0)
    except Exception as e:
        print(f"\n❌ Error: {str(e)}")
        import traceback
        traceback.print_exc()
        sys.exit(1)
