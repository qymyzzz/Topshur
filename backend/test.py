import io
import json

import numpy as np
import requests
import soundfile as sf


def preprocess_audio(file_path):
    with open(file_path, "rb") as audio_file:
        audio_data, samplerate = sf.read(audio_file)
        if len(audio_data.shape) > 1:
            audio_data = audio_data.mean(axis=1)
        audio_data = np.array(audio_data, dtype=np.float32)
        return audio_data.tolist(), samplerate


def test_transcribe_audio(file_path):
    audio_data, samplerate = preprocess_audio(file_path)
    payload = {"audio_data": audio_data, "samplerate": samplerate}
    url = "https://peoples-models.onrender.com/transcribe"
    response = requests.post(url, json=payload)

    if response.status_code == 200:
        result = response.json()
        print("Transcription result:", result)
    else:
        print(f"Failed to transcribe audio. Status code: {response.status_code}")


if __name__ == "__main__":
    test_audio_path = "1.wav"
    test_transcribe_audio(test_audio_path)
