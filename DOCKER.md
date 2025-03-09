# Docker Setup for Spark-TTS

This document explains how to build and run the Spark-TTS application using Docker, with support for both CPU-only and GPU-accelerated environments.

## Prerequisites

- [Docker](https://docs.docker.com/get-docker/)
- For GPU support: 
  - [NVIDIA Container Toolkit (nvidia-docker2)](https://docs.nvidia.com/datacenter/cloud-native/container-toolkit/install-guide.html)
  - NVIDIA drivers compatible with CUDA 12.1

## Building the Docker Image

### CPU Version (Default)

To build the standard CPU-only version:

```bash
docker build -t spark-tts .
```

### GPU Version

To build the GPU-enabled version:

```bash
docker build -t spark-tts-gpu -f Dockerfile .
```

Note: The GPU version requires internet connectivity to download the CUDA-enabled PyTorch packages.

## Running the Container

```

### With GPU Support

```bash
docker run -it --gpus all -p 7860:7860 spark-tts
```

### Model Download

The container will automatically download the Spark-TTS-0.5B model from HuggingFace when it starts. 
If you want to use a custom model, you can mount it as a volume:

```bash
# For CPU version
docker run -it -p 7860:7860 -v /path/to/your/models:/app/pretrained_models/custom-model spark-tts

# For GPU version
docker run -it --gpus all -p 7860:7860 -v /path/to/your/models:/app/pretrained_models/custom-model spark-tts
```

### Environment Variables and Volumes

- `-p 7860:7860`: Maps the Gradio web interface port to your host
- You can mount the results directory: `-v /path/to/save/results:/app/example/results` to persist generated audio


## GitHub Actions

The GitHub Actions workflow will build the Docker image. The images will be published to GitHub Container Registry with appropriate tags.

You can pull the latest image using:

```bash
docker pull ghcr.io/OWNER/Spark-TTS:latest

```

Replace `OWNER` with the GitHub username or organization name.

## Troubleshooting

1. **Network Issues**: If you encounter network timeouts when building the image, try:
   - Check your internet connection and DNS settings
   - Use a VPN if your network restricts Docker Hub access
   - Try the offline setup method described above

2. **CUDA/GPU Issues**: 
   - Verify that your NVIDIA drivers are compatible with CUDA 12.1
   - Check that the NVIDIA Container Toolkit is correctly installed with `nvidia-smi` within the container
   
3. **Permissions Issues**:
   - For permission issues accessing mounted volumes, ensure the directories have appropriate read/write permissions

4. **Model Download Issues**:
   - If you're having trouble downloading the model, check your internet connection
   - Ensure you have access to the HuggingFace repository
   - You can pre-download the model and mount it as a volume
