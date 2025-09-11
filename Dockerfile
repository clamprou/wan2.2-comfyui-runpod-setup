FROM runpod/pytorch:2.8.0-py3.11-cuda12.8.1-cudnn-devel-ubuntu22.04

RUN apt-get update && \
    apt-get install -y \
    ffmpeg \
    jq \
    && rm -rf /var/lib/apt/lists/*

RUN curl -fsSL https://deb.nodesource.com/setup_current.x | bash - \
 && apt-get install -y nodejs

RUN python -m pip install --upgrade pip

ADD . /asd/
RUN chmod +x /asd/src/setup.sh
ENV N8N_USER_FOLDER=/workspace
ENV N8N_DEFAULT_BINARY_DATA_MODE=filesystem
ENV N8N_HOST=0.0.0.0
ENV N8N_PORT=5678
ENV N8N_RUNNERS_ENABLED=true

EXPOSE 8188
EXPOSE 8888
EXPOSE 5678

ENTRYPOINT ["/asd/src/setup.sh"]
