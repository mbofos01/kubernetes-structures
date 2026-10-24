import os
import platform
import socket
from datetime import datetime, timezone

from fastapi import FastAPI

app = FastAPI(
    title="Simple API",
    description="A simple API for Kubernetes experiments.",
    version="1.0.0",
    docs_url="/docs",
    redoc_url="/redoc",
    openapi_url="/openapi.json",
    swagger_ui_parameters={"displayRequestDuration": True},
)

@app.get("/info", tags=["info"], summary="Get host information")
async def info():
    return {
        "hostname": socket.gethostname(),
        "ip_address": socket.gethostbyname(socket.gethostname()),
        "platform": platform.platform(),
        "python_version": platform.python_version(),
        "pid": os.getpid(),
        "pod_name": os.getenv("POD_NAME"),
        "namespace": os.getenv("POD_NAMESPACE"),
        "timestamp": datetime.now(timezone.utc).isoformat(),
    }