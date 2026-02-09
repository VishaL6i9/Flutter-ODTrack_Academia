from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

app = FastAPI(
    title="ODTrack Academia API",
    description="Backend API for ODTrack Academia Mobile App",
    version="1.0.0",
)

# Configure CORS
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # In production, replace with specific origins
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

@app.get("/")
async def root():
    return {"message": "Welcome to ODTrack Academia API", "status": "running"}

@app.get("/health")
async def health_check():
    return {"status": "ok", "service": "ODTrack Academia Backend"}
