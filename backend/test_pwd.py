from app.core.security import verify_password
import sys

# Hash from data_loader.py
h = "$2b$12$wbSPzLHsuT5z40x6SzC4duAnxazYqgbRrmRXDQb6KMCD/zYuGXbLC"
p = "password123"

print("--- START TEST ---")
try:
    result = verify_password(p, h)
    print(f"VERIFICATION_RESULT: {result}")
except Exception as e:
    print(f"VERIFICATION_ERROR: {str(e)}")
print("--- END TEST ---")
