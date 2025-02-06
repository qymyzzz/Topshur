from fastapi import FastAPI

from routes.health import router as health
from routes.transcribe import router as transcribe_router

app = FastAPI()

app.include_router(transcribe_router)
app.include_router(health)

if __name__ == "__main__":
    import uvicorn

    uvicorn.run(app, host="0.0.0.0", port=8000)

# uvicorn main:app --reload
