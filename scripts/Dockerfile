FROM python:3.10-slim

# Install audio dependencies
RUN apt-get update && apt-get install -y \
    portaudio19-dev \
    libasound2-dev \
    && rm -rf /var/lib/apt/lists/*

# Install Python packages
RUN pip install --no-cache-dir \
    sounddevice==0.4.6 \
    soundfile==0.12.1 \
    numpy==1.24.3

# Set working directory
WORKDIR /app

# Copy the setup script
COPY setup_voice_profile.py .

# Make it executable
RUN chmod +x setup_voice_profile.py

# Run the script
ENTRYPOINT ["python3", "setup_voice_profile.py"]
