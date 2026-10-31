import hashlib

def hash_string_to_int32(input_string: str) -> int:
    """Hash a string to a 32-bit integer.
    SELECT ('x' || substr(md5('Your string here'), 1, 8))::bit(32)::integer;
    """
    digest = hashlib.md5(input_string.encode()).digest()[:4]
    key = int.from_bytes(digest, byteorder='big', signed=True)
    return key
