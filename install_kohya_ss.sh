#!/bin/bash
cd /workspace

if [ ! -d "/workspace/sd-scripts" ]; then
    git clone https://github.com/kohya-ss/sd-scripts.git /workspace/sd-scripts
fi

cd /workspace/sd-scripts
pip install --upgrade -r requirements.txt
accelerate config default --mixed_precision fp16

mkdir /workspace/models

# model downloads
if [ ! -f "/workspace/models/diffusion_pytorch_model.safetensors" ]; then
    wget https://huggingface.co/circlestone-labs/Anima-Base-v1.0-Diffusers/resolve/main/text_conditioner/diffusion_pytorch_model.safetensors?download=true -O /workspace/models/diffusion_pytorch_model.safetensors
fi
if [ ! -f "/workspace/models/qwen_3_06b_base.safetensors" ]; then
    wget https://huggingface.co/circlestone-labs/Anima/resolve/main/split_files/text_encoders/qwen_3_06b_base.safetensors?download=true -O /workspace/models/qwen_3_06b_base.safetensors
fi
if [ ! -f "/workspace/models/waiANIMA_v10Base10.safetensors" ]; then
    wget https://civitai.com/api/download/models/2983680?fileId=2863158 -O /workspace/models/waiANIMA_v10Base10.safetensors
fi

if [ ! -f "/workspace/models/waiANIMA_v10Base10_sdscripts.safetensors" ]; then
# convert waiANIMA_v10Base10.safetensors to a format compatible with kohya-ss/sd-scripts
python - <<'PY'
from safetensors.torch import load_file, save_file

src = "/workspace/models/waiANIMA_v10Base10.safetensors"
dst = "/workspace/models/waiANIMA_v10Base10_sdscripts.safetensors"

sd = load_file(src, device="cpu")
out = {}

for k, v in sd.items():
    if k.startswith("model.diffusion_model."):
        nk = k[len("model.diffusion_model."):]
    elif k.startswith("diffusion_model."):
        nk = k[len("diffusion_model."):]
    else:
        nk = k
    out[nk] = v

save_file(out, dst)
print("saved:", dst)
print("num keys:", len(out))
print("sample keys:")
for k in list(out.keys())[:30]:
    print(k)

print("has x_embedder:", any(k.startswith("x_embedder.") for k in out))
print("has t_embedder:", any(k.startswith("t_embedder.") for k in out))
print("has blocks:", any(k.startswith("blocks.") for k in out))
print("has llm_adapter:", any(k.startswith("llm_adapter.") for k in out))
PY
fi

if [ ! -d "./kohya_ss_anima_lora_vastai" ]; then
    git clone https://github.com/mayu4591/kohya_ss_anima_lora_vastai.git /workspace/kohya_ss_anima_lora_vastai
fi

cp -r /workspace/kohya_ss_anima_lora_vastai/script/* /workspace/