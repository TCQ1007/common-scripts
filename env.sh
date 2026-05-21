#!/usr/bin/env bash
# Usage: source env.sh [uv] [hf] [py312] [mineru-api-start] [...]
#   uv                 - set UV_INDEX to Aliyun PyPI mirror
#   hf                 - set HF_ENDPOINT to HuggingFace mirror
#   py312              - activate ~/py312 virtual environment
#   mineru-api-start   - set MINERU_MODEL_SOURCE and start mineru-api server
#
# Add new aliases below in the case branch.
# NOTE: This script MUST be sourced (not executed) for env vars and venv activation to take effect.

CMD_AFTER=""

set_env() {
    case "$1" in
    uv)
        export UV_INDEX="https://mirrors.aliyun.com/pypi/simple"
        echo "  UV_INDEX=$UV_INDEX"
        ;;
    hf)
        export HF_ENDPOINT="https://hf-mirror.com"
        echo "  HF_ENDPOINT=$HF_ENDPOINT"
        ;;
    py312)
        local venv="$HOME/py312"
        if [ -f "$venv/bin/activate" ]; then
            # shellcheck disable=SC1091
            source "$venv/bin/activate"
            echo "  Activated: $venv"
        else
            echo "  ERROR: $venv/bin/activate not found" >&2
        fi
        ;;
    mineru-api-start)
        export MINERU_MODEL_SOURCE="modelscope"
        echo "  MINERU_MODEL_SOURCE=$MINERU_MODEL_SOURCE"
        CMD_AFTER="mineru-api --host 0.0.0.0 --port 8000"
        ;;
    *)
        echo "  Unknown alias: $1 (ignored)" >&2
        ;;
    esac
}

echo "Setting mirror environment variables..."
for arg in "$@"; do
    set_env "$arg"
done

if [ -n "$CMD_AFTER" ]; then
    echo "Running: $CMD_AFTER"
    eval "$CMD_AFTER"
fi