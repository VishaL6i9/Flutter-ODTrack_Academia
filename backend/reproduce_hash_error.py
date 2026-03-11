from passlib.context import CryptContext

pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")

try:
    print("Hashing 'password123'...")
    hashed = pwd_context.hash("password123")
    print(f"Success: {hashed}")
except Exception as e:
    print(f"Error: {e}")
