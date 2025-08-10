FROM runpod/pytorch:2.8.0-py3.11-cuda12.8.1-cudnn-devel-ubuntu22.04

RUN curl -fsSL https://deb.nodesource.com/setup_current.x | bash - \
 && apt-get install -y nodejs

RUN python -m pip install --upgrade pip

ADD . /asd/
RUN chmod +x /asd/src/setup.sh
ENV N8N_USER_FOLDER=/workspace/.n8n

EXPOSE 8188
EXPOSE 8888
EXPOSE 5678

ENTRYPOINT ["/asd/src/setup.sh"]
