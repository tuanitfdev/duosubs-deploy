FROM ghcr.io/tuanitfdev/duosubs-hub-deploy:latest as model-hub

# FROM pytorch/pytorch:2.8.0-cuda12.8-cudnn9-devel
FROM vastai/pytorch:2.8.0-cu128-cuda-12.9-mini-py312-2026-03-26