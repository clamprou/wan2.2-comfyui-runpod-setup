#!/usr/bin/env bash
echo "▶ Starting setup.sh..."

set -e  # stop on first error
set -x  # Print all commands as they're executed
set -o pipefail # catch errors in pipes

# ────────────────────────────────────────────────────────────
# CONFIG
BASE=/workspace/ComfyUI
MODELS_DIR="$BASE/models"
CUSTOM="$BASE/custom_nodes"
echo "▶ Using base directory: $BASE"
# ────────────────────────────────────────────────────────────

# WAN 2.1 model assets
download () {
  URL=$1
  DEST=$2
  mkdir -p "$(dirname "$DEST")"
  if [ -f "$DEST" ]; then
    echo "✔ $(basename "$DEST") already exists"
  else
    echo "▶ Downloading $(basename "$DEST") …"
    wget -q --show-progress -O "$DEST" "$URL"
  fi
}

# ────────────────────────────────────────────────────────────
# Helper function for custom nodes
clone_and_install () {
  REPO=$1
  TARGET=$2
  if [ ! -d "$TARGET/.git" ]; then
    echo "▶ Cloning $REPO …"
    git clone --depth 1 "$REPO" "$TARGET"
  else
    echo "✔ $REPO already present; pulling latest …"
    git -C "$TARGET" pull --ff-only
  fi
  pip install --quiet -r "$TARGET/requirements.txt"
}

clone_and_install_interpol () {
  REPO=$1
  TARGET=$2
  if [ ! -d "$TARGET/.git" ]; then
    echo "▶ Cloning $REPO …"
    git clone --depth 1 "$REPO" "$TARGET"
  else
    echo "✔ $REPO already present; pulling latest …"
    git -C "$TARGET" pull --ff-only
  fi
  python "$CUSTOM/comfyui-frame-interpolation/install.py"  || true
}
# ────────────────────────────────────────────────────────────

# ComfyUI and Custom nodes installation
clone_and_install https://github.com/comfyanonymous/ComfyUI.git "$BASE"
clone_and_install https://github.com/ltdrdata/ComfyUI-Manager "$CUSTOM/comfyui-manager"
clone_and_install_interpol https://github.com/Fannovel16/ComfyUI-Frame-Interpolation "$CUSTOM/comfyui-frame-interpolation"
clone_and_install https://github.com/Kosinkadink/ComfyUI-VideoHelperSuite "$CUSTOM/comfyui-videohelpersuite"
clone_and_install https://github.com/city96/ComfyUI-GGUF "$CUSTOM/ComfyUI-GGUF"

download https://huggingface.co/Comfy-Org/Wan_2.2_ComfyUI_Repackaged/resolve/main/split_files/diffusion_models/wan2.2_ti2v_5B_fp16.safetensors  \
         "$MODELS_DIR/diffusion_models/wan2.2_ti2v_5B_fp16.safetensors"

download https://huggingface.co/Comfy-Org/Wan_2.1_ComfyUI_repackaged/resolve/main/split_files/text_encoders/umt5_xxl_fp8_e4m3fn_scaled.safetensors \
         "$MODELS_DIR/text_encoders/umt5_xxl_fp8_e4m3fn_scaled.safetensors"

download https://huggingface.co/Comfy-Org/Wan_2.1_ComfyUI_repackaged/resolve/main/split_files/clip_vision/clip_vision_h.safetensors \
         "$MODELS_DIR/clip_vision/clip_vision_h.safetensors"

download https://huggingface.co/Comfy-Org/Wan_2.2_ComfyUI_Repackaged/resolve/main/split_files/vae/wan2.2_vae.safetensors \
         "$MODELS_DIR/vae/wan2.2_vae.safetensors"

# Copy WAN2.2 workflow JSON into user/default/workflows
WORKFLOW_SRC="/asd/src/video_wan2_2_5B_ti2v.json"
WORKFLOW_DEST="$BASE/user/default/workflows/video_wan2_2_5B_ti2v.json"

mkdir -p "$(dirname "$WORKFLOW_DEST")"

if [ -f "$WORKFLOW_SRC" ]; then
  if [ ! -f "$WORKFLOW_DEST" ]; then
    echo "▶ Copying video_wan2_2_5B_ti2v.json workflow to default location …"
    cp "$WORKFLOW_SRC" "$WORKFLOW_DEST"
  else
    echo "✅ video_wan2_2_5B_ti2v.json already exists at destination, skipping copy."
  fi
else
  echo "⚠ video_wan2_2_5B_ti2v.json not found at $WORKFLOW_SRC"
fi

echo "▶ Starting Jupyter …"
jupyter notebook --ip=0.0.0.0 --port=8888 --allow-root --NotebookApp.token='' --NotebookApp.password='' &

echo "▶ Starting n8n …"
mkdir -p /workspace/.n8n
npm install -g n8n
n8n start --tunnel &

# ────────────────────────────────────────────────────────────
# Launch ComfyUI (Gradio) – listens on 0.0.0.0 for Docker/RunPod
echo "▶ Starting ComfyUI …"
exec python "$BASE/main.py" --listen 0.0.0.0