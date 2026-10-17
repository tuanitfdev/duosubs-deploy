FROM ghcr.io/tuanitfdev/duosubs-hub-deploy:latest as model-hub

# FROM pytorch/pytorch:2.8.0-cuda12.8-cudnn9-devel
FROM vastai/pytorch:2.8.0-cu128-cuda-12.9-mini-py312-2026-03-26

# Thiết lập biến môi trường để tránh các câu hỏi tương tác
ARG DEBIAN_FRONTEND=noninteractive
# Ép uv sử dụng system python và không tạo venv
ARG UV_SYSTEM_PYTHON=1
# Chỉ định thư mục cache cho uv
ARG UV_CACHE_DIR=/root/.cache/uv
# Sử dụng chế độ copy thay vì hardlink để tương thích tốt nhất với Docker mount cache
ARG UV_LINK_MODE=copy

WORKDIR /my/dl/duosubs

ARG VIRTUAL_ENV=/venv/main
ARG PATH="$VIRTUAL_ENV/bin:$PATH"

COPY --from=model-hub /data/huggingface/hub /workspace/.hf_home/hub

COPY data/fixture/* /my/dl/duosubs/

RUN uv pip install --no-cache-dir duosubs

ARG SUB_NAME="h2500-gn"

RUN duosubs merge -p ${SUB_NAME}.en.srt -s ${SUB_NAME}.vi.srt --mode mixed --device cuda --format-all srt --output-name "${SUB_NAME}-duosubs"


