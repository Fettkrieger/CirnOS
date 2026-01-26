# ComfyUI - Stable Diffusion node-based GUI
{ config, pkgs, lib, ... }:

let
  # Base Python with venv support
  pythonBase = pkgs.python312.withPackages (ps: with ps; [
    pip
    setuptools
    wheel
    virtualenv
  ]);

  # ComfyUI installation directory
  comfyuiDir = "$HOME/.local/share/comfyui";
  
  # Wrapper script that installs/updates and runs ComfyUI
  comfyuiWrapper = pkgs.writeShellScriptBin "comfyui" ''
    set -e
    
    COMFYUI_DIR="${comfyuiDir}"
    COMFYUI_VENV="$COMFYUI_DIR/.venv"
    COMFYUI_PORT=''${COMFYUI_PORT:-8188}
    
    # Set up library path for CUDA/torch - include NixOS NVIDIA driver path
    export LD_LIBRARY_PATH="/run/opengl-driver/lib:${pkgs.stdenv.cc.cc.lib}/lib:${pkgs.zlib}/lib:''${LD_LIBRARY_PATH:-}"
    
    # Create directory if it doesn't exist
    mkdir -p "$COMFYUI_DIR"
    
    # Clone or update ComfyUI
    if [ ! -d "$COMFYUI_DIR/.git" ]; then
      echo "Installing ComfyUI..."
      ${pkgs.git}/bin/git clone https://github.com/comfyanonymous/ComfyUI.git "$COMFYUI_DIR"
    else
      echo "Checking for ComfyUI updates..."
      cd "$COMFYUI_DIR"
      ${pkgs.git}/bin/git pull --ff-only 2>/dev/null || echo "Could not auto-update, continuing with current version"
    fi
    
    cd "$COMFYUI_DIR"
    
    # Create model directories if they don't exist
    mkdir -p models/{checkpoints,vae,loras,controlnet,embeddings,upscale_models,clip,clip_vision}
    mkdir -p input output custom_nodes
    
    # Create venv if it doesn't exist
    if [ ! -d "$COMFYUI_VENV" ]; then
      echo "Creating Python virtual environment..."
      ${pythonBase}/bin/python -m venv "$COMFYUI_VENV" --system-site-packages
    fi
    
    # Activate venv
    source "$COMFYUI_VENV/bin/activate"
    
    # Install/update dependencies
    if [ ! -f "$COMFYUI_DIR/.deps-installed-v4" ]; then
      echo "Installing Python dependencies (this may take a few minutes)..."
      
      # Install PyTorch with CUDA support
      pip install --upgrade \
        torch \
        torchvision \
        torchaudio \
        --index-url https://download.pytorch.org/whl/cu128
      
      # Install ComfyUI requirements from requirements.txt
      pip install -r "$COMFYUI_DIR/requirements.txt"
      
      # Install additional dependencies that may be missing
      pip install --upgrade \
        torchsde \
        av \
        pydantic \
        pydantic-settings
      
      touch "$COMFYUI_DIR/.deps-installed-v4"
      echo "Dependencies installed!"
    fi
    
    echo ""
    echo "╔════════════════════════════════════════════════════════════╗"
    echo "║                     ComfyUI Starting                       ║"
    echo "╠════════════════════════════════════════════════════════════╣"
    echo "║  URL: http://127.0.0.1:$COMFYUI_PORT                            ║"
    echo "║  Models: $COMFYUI_DIR/models/"
    echo "╚════════════════════════════════════════════════════════════╝"
    echo ""
    
    # Open browser after a short delay
    (sleep 4 && ${pkgs.xdg-utils}/bin/xdg-open "http://127.0.0.1:$COMFYUI_PORT" 2>/dev/null) &
    
    # Run ComfyUI with NVIDIA GPU support
    exec python main.py \
      --listen 127.0.0.1 \
      --port "$COMFYUI_PORT" \
      --preview-method auto \
      "$@"
  '';

in
{
  home.packages = [
    comfyuiWrapper
    pkgs.git
    pkgs.xdg-utils
  ];
}
