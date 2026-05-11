"""CATT — Character-Aware Transformer for Tashkeel (Arabic diacritization).

Paper: https://arxiv.org/abs/2407.03236   Repo: https://github.com/abjadai/catt

The pip package `catt-tashkeel` pins onnxruntime-gpu (no macOS wheel), so we
bootstrap the official repo + checkpoint directly and run PyTorch inference
with MPS / CUDA / CPU device selection.

Install deps:
    pip install torch pytorch_lightning kaldialign

First import clones the repo into scripts/experiments/vendor/catt and downloads
the EO checkpoint (~76 MB). Subsequent runs reuse them.

Usage:
    from catt import diacritize
    diacritize(["ذهب الولد إلى المدرسة"])
"""
import os
import subprocess
import sys
import urllib.request
from pathlib import Path

# Allow MPS to fall back to CPU for any unsupported ops.
os.environ.setdefault("PYTORCH_ENABLE_MPS_FALLBACK", "1")

VENDOR = Path(__file__).parent / "vendor" / "catt"
CKPT = VENDOR / "models" / "best_eo_mlm_ns_epoch_193.pt"
CKPT_URL = (
    "https://github.com/abjadai/catt/releases/download/v2/"
    "best_eo_mlm_ns_epoch_193.pt"
)


def _bootstrap() -> None:
    if not VENDOR.exists():
        print(f"cloning CATT into {VENDOR}...")
        subprocess.run(
            ["git", "clone", "--depth", "1", "https://github.com/abjadai/catt.git", str(VENDOR)],
            check=True,
        )
    if not CKPT.exists():
        CKPT.parent.mkdir(parents=True, exist_ok=True)
        print(f"downloading {CKPT.name}...")
        urllib.request.urlretrieve(CKPT_URL, CKPT)
    if str(VENDOR) not in sys.path:
        sys.path.insert(0, str(VENDOR))


_bootstrap()

import torch  # noqa: E402
from eo_pl import TashkeelModel  # noqa: E402
from tashkeel_tokenizer import TashkeelTokenizer  # noqa: E402
from utils import remove_non_arabic  # noqa: E402


def _pick_device() -> str:
    if torch.cuda.is_available():
        return "cuda"
    if torch.backends.mps.is_available():
        return "mps"
    return "cpu"


_model: TashkeelModel | None = None
_device: str | None = None


def _load() -> TashkeelModel:
    global _model, _device
    if _model is None:
        _device = _pick_device()
        print(f"device: {_device}")
        tokenizer = TashkeelTokenizer()
        m = TashkeelModel(tokenizer, max_seq_len=1024, n_layers=6, learnable_pos_emb=False)
        m.load_state_dict(torch.load(str(CKPT), map_location=_device))
        m.eval().to(_device)
        _model = m
    return _model


def diacritize(texts: list[str], batch_size: int = 16, verbose: bool = False) -> list[str]:
    """Add Arabic diacritics to a list of plain Arabic strings."""
    model = _load()
    cleaned = [remove_non_arabic(t) for t in texts]
    return model.do_tashkeel_batch(cleaned, batch_size, verbose)


if __name__ == "__main__":
    import time

    sample = ["ذهب الولد إلى المدرسة"]
    diacritize(sample)  # warmup
    t0 = time.perf_counter()
    out = diacritize(sample)
    print(f"{time.perf_counter() - t0:.2f}s  →  {out[0]}")
