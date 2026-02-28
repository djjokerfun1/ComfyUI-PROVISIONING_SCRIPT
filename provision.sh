#!/usr/bin/env bash
set -euo pipefail

log(){ echo -e "[provision] $*"; }
is_true(){ [[ "${1:-}" =~ ^([Tt]rue|1|[Yy]es|[Oo]n)$ ]]; }

WORKSPACE="${WORKSPACE:-/workspace}"
COMFYUI_DIR="${COMFYUI_DIR:-$WORKSPACE/ComfyUI}"
MODELS_DIR="${MODELS_DIR:-$COMFYUI_DIR/models}"

DIFFUSION="$MODELS_DIR/diffusion_models"
UNET="$MODELS_DIR/unet"
VAE="$MODELS_DIR/vae"
CLIP="$MODELS_DIR/clip"
LORAS="$MODELS_DIR/loras"
CHECKPOINTS="$MODELS_DIR/checkpoints"

mkdir -p "$DIFFUSION" "$UNET" "$VAE" "$CLIP" "$LORAS" "$CHECKPOINTS"

# RunPod-like toggles (you can set these in Vast env vars too)
download_480p_native_models="${download_480p_native_models:-false}"
download_720p_native_models="${download_720p_native_models:-false}"
download_wan_fun_and_sdxl_helper="${download_wan_fun_and_sdxl_helper:-false}"
download_vace="${download_vace:-false}"

# Backward aliases you used
download_wan22="${download_wan22:-false}"
download_wan_animate="${download_wan_animate:-false}"

# Tokens
HF_TOKEN="${HF_TOKEN:-${HUGGINGFACE_TOKEN:-}}"
civitai_token="${civitai_token:-${CIVITAI_TOKEN:-}}"
LORAS_IDS_TO_DOWNLOAD="${LORAS_IDS_TO_DOWNLOAD:-}"
CHECKPOINT_IDS_TO_DOWNLOAD="${CHECKPOINT_IDS_TO_DOWNLOAD:-}"

# Downloader helper
dl(){
  local url="$1"; local out="$2"
  if [[ -s "$out" ]]; then
    log "Skip (exists): $out"
    return 0
  fi
  mkdir -p "$(dirname "$out")"
  if command -v aria2c >/dev/null 2>&1; then
    aria2c -c -x16 -s16 -k1M -o "$(basename "$out")" -d "$(dirname "$out")" "$url"
  else
    curl -L --fail --retry 5 --retry-delay 2 -o "$out" "$url"
  fi
}

# OPTIONAL: install extra system deps
log "Ensuring base tools..."
apt-get update -y
apt-get install -y curl git aria2 ca-certificates

# OPTIONAL: custom nodes / workflows (examples)
# log "Cloning workflows..."
# mkdir -p "$WORKSPACE/workflows"
# git clone --depth 1 https://github.com/<you>/<your-workflows>.git "$WORKSPACE/workflows" || true

# --- MODEL DOWNLOADS ---
# IMPORTANT: Replace placeholder URLs with your actual model sources (HF/CivitAI/S3/etc.)

download_wan_native_480p(){
  log "Downloading Wan native 480p models..."
  # Examples (placeholders):
  # dl "https://huggingface.co/<repo>/resolve/main/wan_1.3B_t2v_480p.safetensors" \
  #    "$DIFFUSION/wan_1.3B_t2v_480p.safetensors"
  # dl "https://huggingface.co/<repo>/resolve/main/wan_14B_t2v_480p.safetensors" \
  #    "$DIFFUSION/wan_14B_t2v_480p.safetensors"
  # dl "https://huggingface.co/<repo>/resolve/main/wan_14B_i2v_480p.safetensors" \
  #    "$DIFFUSION/wan_14B_i2v_480p.safetensors"
  :
}

download_wan_native_720p(){
  log "Downloading Wan native 720p models..."
  :
}

download_wan_fun_helper(){
  log "Downloading Wan Fun + SDXL helper models..."
  :
}

download_wan_vace(){
  log "Downloading Wan VACE models..."
  :
}

download_wan_animate_bundle(){
  log "Downloading Wan animate bundle (LoRAs / extras)..."
  :
}

# CivitAI by version IDs (saves as <id>.bin; you can rename later if you want)
civitai_download(){
  local id="$1"; local outdir="$2"
  mkdir -p "$outdir"
  local url="https://civitai.com/api/download/models/${id}"
  local outfile="${outdir}/${id}.bin"

  if [[ -s "$outfile" ]]; then
    log "Skip (exists): $outfile"
    return 0
  fi

  log "CivitAI download id=${id} -> ${outfile}"
  if [[ -n "$civitai_token" ]]; then
    curl -L --fail -H "Authorization: Bearer ${civitai_token}" -o "$outfile" "$url"
  else
    curl -L --fail -o "$outfile" "$url"
  fi
}

download_civitai_assets(){
  if [[ -z "$LORAS_IDS_TO_DOWNLOAD" && -z "$CHECKPOINT_IDS_TO_DOWNLOAD" ]]; then
    return 0
  fi
  if [[ -z "$civitai_token" ]]; then
    log "WARN: civitai_token not set; some downloads may fail."
  fi

  if [[ -n "$LORAS_IDS_TO_DOWNLOAD" ]]; then
    IFS=',' read -ra IDS <<< "$LORAS_IDS_TO_DOWNLOAD"
    for id in "${IDS[@]}"; do
      id="$(echo "$id" | xargs)"; [[ -z "$id" ]] && continue
      civitai_download "$id" "$LORAS"
    done
  fi

  if [[ -n "$CHECKPOINT_IDS_TO_DOWNLOAD" ]]; then
    IFS=',' read -ra IDS <<< "$CHECKPOINT_IDS_TO_DOWNLOAD"
    for id in "${IDS[@]}"; do
      id="$(echo "$id" | xargs)"; [[ -z "$id" ]] && continue
      civitai_download "$id" "$CHECKPOINTS"
    done
  fi
}

# Map old envs
if is_true "$download_wan22"; then
  download_480p_native_models="true"
fi

# Execute downloads by toggles
if is_true "$download_480p_native_models"; then download_wan_native_480p; fi
if is_true "$download_720p_native_models"; then download_wan_native_720p; fi
if is_true "$download_wan_fun_and_sdxl_helper"; then download_wan_fun_helper; fi
if is_true "$download_vace"; then download_wan_vace; fi
if is_true "$download_wan_animate"; then download_wan_animate_bundle; fi

download_civitai_assets

log "Provisioning complete."