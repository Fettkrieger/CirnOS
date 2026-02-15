# ComfyUI - Stable Diffusion node-based GUI
{ pkgs, ... }:

let
  # Pinned ComfyUI source (update rev+hash together intentionally)
  comfyuiRev = "df1e5e85142746a745a56572b705406b273a594c";
  comfyuiSrc = pkgs.fetchFromGitHub {
    owner = "comfyanonymous";
    repo = "ComfyUI";
    rev = comfyuiRev;
    hash = "sha256-unmKkChJkMvJZOmW7fiyqqRTq3bHwnIrd7s3WpgYeOA=";
  };

  # Lock file tracked in repo for deterministic dependency reinstalls
  comfyuiLockFile = ./comfyui-requirements.lock;
  comfyuiLockHash = builtins.hashFile "sha256" comfyuiLockFile;

  # Base Python with venv support
  pythonBase = pkgs.python312.withPackages (ps: with ps; [
    pip
    setuptools
    wheel
    virtualenv
  ]);

  comfyuiWrapper = pkgs.writeShellScriptBin "comfyui" ''
    set -eu

    COMFYUI_DIR="$HOME/.local/share/comfyui"
    COMFYUI_VENV="$COMFYUI_DIR/.venv"
    COMFYUI_PORT=''${COMFYUI_PORT:-8188}
    SOURCE_STAMP="$COMFYUI_DIR/.cirnos-comfyui-rev"
    DEPS_STAMP="$COMFYUI_DIR/.cirnos-comfyui-deps-${builtins.substring 0 12 comfyuiRev}-${builtins.substring 0 12 comfyuiLockHash}"

    # Set up library path for CUDA/torch - include NixOS NVIDIA driver path
    export LD_LIBRARY_PATH="/run/opengl-driver/lib:${pkgs.stdenv.cc.cc.lib}/lib:${pkgs.zlib}/lib:''${LD_LIBRARY_PATH:-}"

    ensure_writable_dir() {
      local dir="$1"
      mkdir -p "$dir"
      chmod u+rwx "$dir" 2>/dev/null || true
    }

    ensure_writable_dir "$COMFYUI_DIR"

    current_rev=""
    if [ -r "$SOURCE_STAMP" ]; then
      current_rev="$(cat "$SOURCE_STAMP")"
    fi

    # Sync pinned source into the runtime directory while keeping user data.
    if [ "$current_rev" != "${comfyuiRev}" ]; then
      echo "Syncing pinned ComfyUI source (${comfyuiRev})..."
      ${pkgs.rsync}/bin/rsync -a --no-perms --delete \
        --exclude '.venv' \
        --exclude 'models' \
        --exclude 'input' \
        --exclude 'output' \
        --exclude 'custom_nodes' \
        --exclude 'user' \
        --exclude 'temp' \
        "${comfyuiSrc}/" "$COMFYUI_DIR/"
      ensure_writable_dir "$COMFYUI_DIR"
      printf '%s\n' "${comfyuiRev}" > "$SOURCE_STAMP"
    fi

    cd "$COMFYUI_DIR"

    # Create model and runtime directories if they don't exist
    mkdir -p models/{checkpoints,vae,loras,controlnet,embeddings,upscale_models,clip,clip_vision}
    mkdir -p input output custom_nodes user/default temp

    # Ensure runtime data paths remain writable even after source syncs.
    for dir in \
      "$COMFYUI_DIR" \
      "$COMFYUI_DIR/input" \
      "$COMFYUI_DIR/output" \
      "$COMFYUI_DIR/custom_nodes" \
      "$COMFYUI_DIR/user" \
      "$COMFYUI_DIR/user/default" \
      "$COMFYUI_DIR/temp"
    do
      chmod u+rwx "$dir" 2>/dev/null || true
    done

    # Create venv if it doesn't exist
    if [ ! -d "$COMFYUI_VENV" ]; then
      echo "Creating Python virtual environment..."
      ${pythonBase}/bin/python -m venv "$COMFYUI_VENV" --system-site-packages
    fi

    # Activate venv
    # shellcheck disable=SC1090
    source "$COMFYUI_VENV/bin/activate"

    # Install dependencies from the pinned lock file when stamp changes.
    if [ ! -f "$DEPS_STAMP" ]; then
      echo "Installing pinned Python dependencies from lock file..."

      pip install --upgrade \
        "pip==25.0.1" \
        "setuptools==80.9.0.post0" \
        "wheel==0.46.1"

      pip install \
        --index-url https://download.pytorch.org/whl/cu128 \
        --extra-index-url https://pypi.org/simple \
        --requirement "${comfyuiLockFile}"

      rm -f "$COMFYUI_DIR"/.cirnos-comfyui-deps-*
      touch "$DEPS_STAMP"
      echo "Dependencies installed!"
    fi

    echo ""
    echo "ComfyUI starting"
    echo "  URL:    http://127.0.0.1:$COMFYUI_PORT"
    echo "  Models: $COMFYUI_DIR/models/"
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

  comfyuiResetDeps = pkgs.writeShellScriptBin "comfyui-reset-deps" ''
    set -eu

    COMFYUI_DIR="$HOME/.local/share/comfyui"
    rm -f "$COMFYUI_DIR"/.cirnos-comfyui-deps-*
    echo "Cleared ComfyUI dependency stamp(s)."
    echo "Next 'comfyui' run will reinstall from pinned lock file."
  '';

  comfyuiRelock = pkgs.writeShellScriptBin "comfyui-relock" ''
    set -eu

    COMFYUI_VENV="$HOME/.local/share/comfyui/.venv"
    LOCK_FILE="$HOME/CirnOS/home/comfyui-requirements.lock"

    if [ ! -x "$COMFYUI_VENV/bin/pip" ]; then
      echo "ComfyUI virtualenv not found. Run 'comfyui' once first."
      exit 1
    fi

    "$COMFYUI_VENV/bin/pip" freeze --all | ${pkgs.coreutils}/bin/sort > "$LOCK_FILE"
    echo "Updated lock file: $LOCK_FILE"
    echo "Review changes, then rebuild to apply the new lock."
  '';
in
{
  home.packages = [
    comfyuiWrapper
    comfyuiResetDeps
    comfyuiRelock
    pkgs.xdg-utils
  ];
}
