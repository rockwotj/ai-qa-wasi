#!/usr/bin/env bash

# e: errors, x: debug, u: only deefine vars, -o pipefail: don't mask errors
set -euxo pipefail
 
if false; then
    brew install rust rustup redpanda-data/tap/redpanda
fi

# flag for rust install
if false; then
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
fi

# Install python deps and export our model.
pip3 install --user transformers torch torchinfo onnx
python3 export.py

#add the wasi target
rustup target add wasm32-wasi

# Build it!
RUSTFLAGS="-Ctarget-feature=+simd128" cargo build --release --target=wasm32-wasi

rpk container purge
# Deploy to our locally running container
rpk container start --image docker.redpanda.com/redpandadata/redpanda:v23.3.5 --set rpk.additional_start_flags="--smp=4"
# Modify the required cluster configurations
rpk cluster config set data_transforms_enabled true
# NOTE: These limits allow for a single transform with half a GiB of memory.
rpk cluster config set data_transforms_per_core_memory_reservation 536870912
rpk cluster config set data_transforms_per_function_memory_limit 536870912
# Since we're hackily embedding the model in the Wasm binary, we need to support large binaries.
rpk cluster config set data_transforms_binary_max_size 125829120
# Allow some extra time on startup over the default. 
rpk cluster config set data_transforms_runtime_limit_ms 300000
# Retart our node.
rpk container stop
rpk container start
# Create needed topics
rpk topic create questions answers
cp ./target/wasm32-wasi/release/ai-qa-wasi.wasm .
rpk wasm deploy -v

#sleep 20
#echo "how many employees does JumpTrading employ?" | rpk topic produce questions
#echo "list the offices of jumptrading?" | rpk topic produce questions
#echo "who founded jumptrading?" | rpk topic produce questions
#echo "does jumptrading own a crypto firm?" | rpk topic produce questions