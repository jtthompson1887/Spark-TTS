FROM python:3.10-slim

WORKDIR /app

# Set environment variables to disable CUDA completely
ENV CUDA_VISIBLE_DEVICES="-1"
ENV TORCH_CUDA_ARCH_LIST="None"
ENV USE_CUDA="0" 

# Install system dependencies
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    build-essential \
    libsndfile1 \
    ffmpeg \
    git \
    wget \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Copy requirements.txt first to leverage Docker cache
COPY requirements.txt .

# Install Python dependencies without cuda support
RUN pip install --no-cache-dir -r requirements.txt

# Install huggingface_hub for model download
RUN pip install --no-cache-dir huggingface_hub

# Copy the application code
COPY . .

# Create model directory structure
RUN mkdir -p pretrained_models/Spark-TTS-0.5B

# Create a patch to disable CUDA checks in torch
RUN echo 'import torch\n\
import types\n\
def _is_available(*args, **kwargs):\n\
    return False\n\
torch.cuda.is_available = _is_available\n\
# Also patch device_count to return 0\n\
def _device_count(*args, **kwargs):\n\
    return 0\n\
torch.cuda.device_count = _device_count\n\
# Also patch torch._C._cuda_getDeviceCount\n\
def _cuda_getDeviceCount(*args, **kwargs):\n\
    return 0\n\
if hasattr(torch._C, "_cuda_getDeviceCount"):\n\
    torch._C._cuda_getDeviceCount = _cuda_getDeviceCount' > /app/patch_torch.py

# Create startup script
RUN echo '#!/bin/bash' > /app/start.sh && \
    echo '# Try to download model' >> /app/start.sh && \
    echo 'python3 <<EOF' >> /app/start.sh && \
    echo 'from huggingface_hub import snapshot_download' >> /app/start.sh && \
    echo 'import sys, os' >> /app/start.sh && \
    echo 'try:' >> /app/start.sh && \
    echo '    snapshot_download("SparkAudio/Spark-TTS-0.5B", local_dir="pretrained_models/Spark-TTS-0.5B")' >> /app/start.sh && \
    echo 'except Exception as e:' >> /app/start.sh && \
    echo '    print(f"Warning: Failed to download model: {e}", file=sys.stderr)' >> /app/start.sh && \
    echo '    print("Continuing without model download. Please mount a local model directory.", file=sys.stderr)' >> /app/start.sh && \
    echo 'EOF' >> /app/start.sh && \
    echo '# Check if model files exist' >> /app/start.sh && \
    echo 'if [ ! -f /app/pretrained_models/Spark-TTS-0.5B/config.yaml ]; then' >> /app/start.sh && \
    echo '    echo "Error: Model files not found. Please ensure the model is downloaded or mounted." >&2' >> /app/start.sh && \
    echo '    echo "You can mount a local model directory using: -v /path/to/model:/app/pretrained_models/Spark-TTS-0.5B"' >> /app/start.sh && \
    echo '    echo "Keeping container alive for debugging..."' >> /app/start.sh && \
    echo '    tail -f /dev/null' >> /app/start.sh && \
    echo 'else' >> /app/start.sh && \
    echo '    # Use CPU mode with torch patching to disable CUDA completely' >> /app/start.sh && \
    echo '    export PYTHONPATH=/app:$PYTHONPATH' >> /app/start.sh && \
    echo '    python -c "import patch_torch"' >> /app/start.sh && \
    echo '    python webui.py --server_name 0.0.0.0 --server_port 7860 --device -1' >> /app/start.sh && \
    echo 'fi' >> /app/start.sh && \
    chmod +x /app/start.sh

# Expose the port for the Gradio server
EXPOSE 7860

# Command to run the startup script
CMD ["/app/start.sh"]
