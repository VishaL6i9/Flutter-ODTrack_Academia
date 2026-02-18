"""
Generate a secure SECRET_KEY for the .env file
Run this script and copy the output to your .env file
"""
import secrets

if __name__ == "__main__":
    secret_key = secrets.token_urlsafe(32)
    print("=" * 60)
    print("Generated SECRET_KEY for your .env file:")
    print("=" * 60)
    print(f"\nSECRET_KEY={secret_key}\n")
    print("=" * 60)
    print("Copy the line above to your backend/.env file")
    print("=" * 60)
