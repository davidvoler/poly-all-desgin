"""Deterministic word-bucket assignment.

Used to spread a vocabulary across N proficiency tiers without storing a
per-word level in the DB — given the same `word` and `n_buckets` you'll
always get the same bucket on every machine, every process, every Python
version.

Why SHA-256 and not the built-in `hash()`?
    Python randomizes the built-in `hash()` for strings between processes
    (PEP 456 / PYTHONHASHSEED). That's a security feature for dict-keyed
    user input but fatal for "stable across deploys" bucketing.

Usage:
    >>> bucket_for("hello")
    3
    >>> bucket_for("hello")        # same answer, always
    3
    >>> bucket_for("こんにちは", n_buckets=4)
    1
"""

import hashlib


def bucket_for(word: str, *, n_buckets: int = 3) -> int:
    """Return a 1-indexed bucket number in 1..n_buckets for `word`.

    The mapping is deterministic and approximately uniform — over a large
    vocabulary each bucket gets ~1/n_buckets of the words.
    """
    if n_buckets < 1:
        raise ValueError("n_buckets must be >= 1")
    digest = hashlib.sha256(word.encode("utf-8")).digest()
    # First 8 bytes is plenty of entropy for modulo of small N.
    n = int.from_bytes(digest[:8], "big")
    return n % n_buckets + 1


# ───────────── ad-hoc sanity check (run: `python buckets.py`) ─────────────
if __name__ == "__main__":  # pragma: no cover
    from collections import Counter

    sample = [
        "hello", "thanks", "book", "school", "water", "friend", "morning",
        "family", "teacher", "please", "good", "learn", "time", "house",
        "food", "love", "people", "year", "day", "child", "world",
        "country", "story", "music", "color", "number", "letter", "sound",
        "name", "place", "thing", "way", "work", "life", "hand", "eye",
        "heart", "money", "fire", "tree",'שלום', 'תודה', 'ספר', 'בית ספר', 'מים', 'חבר', 'בוקר', 'משפחה', 'お願いします', 'いい', '学ぶ', '時間', '家', '食べ物', '愛', '人々', '年', '日', '子供', '世界', '国', '物語', '音楽', '色', '数字', '文字', '音', '名前', '場所', '物', '方法', '仕事', '人生', '手', '目', '心臓', 'お金', '火事', '木',
    ]
    counts = Counter(bucket_for(w, n_buckets=5) for w in sample)
    print(f"Sample size: {len(sample)}")
    for b in sorted(counts):
        print(f"  bucket {b}: {counts[b]:>3}  ({counts[b]/len(sample):.0%})")


    print("hello -> bucket", bucket_for("hello"))
    print("hello -> bucket", bucket_for("hello"))
    print("こんにちは -> bucket", bucket_for("こんにちは"))
    print("こんにちは -> bucket", bucket_for("こんにちは"))
