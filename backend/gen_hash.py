from app.core.security import get_password_hash
import sys

try:
    p = "password123"
    h = get_password_hash(p)
    print(f"HASH_START:{h}:HASH_END")
except Exception as e:
    print(f"HASH_ERROR:{str(e)}")
