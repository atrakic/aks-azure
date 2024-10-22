import os
from datetime import datetime
from fastapi import FastAPI
from ollama import AsyncClient

OLLAMA_HOST = os.getenv("OLLAMA_HOST", "http://localhost:11434")
ollama_client = AsyncClient(OLLAMA_HOST)

app = FastAPI()


@app.get("/")
async def root():
    resp = await ollama_client.generate(
        model="llama3.2:latest",
        prompt="Why is the sky not green?",
    )
    return resp["response"]


@app.get("/healthz")
async def healthcheck():
    return {"message": datetime.now()}
