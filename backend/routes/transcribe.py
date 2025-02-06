import numpy as np
from fastapi import APIRouter
from fastapi.responses import JSONResponse
from pydantic import BaseModel
from transformers import pipeline

router = APIRouter()

pipe = pipeline(
    model="qymyz/whisper-russian-dysarthria",
)


class TranscriptionRequest(BaseModel):
    audio_data: list
    samplerate: int


class TranscriptionResult(BaseModel):
    text: str


@router.post("/transcribe", response_model=TranscriptionResult)
async def transcribe_audio(request: TranscriptionRequest):
    audio_data = np.array(request.audio_data, dtype=np.float32)
    result = pipe(audio_data)

    return JSONResponse(content={"text": result["text"]})
