import asyncio
from fastapi import APIRouter, WebSocket, WebSocketDisconnect
import logging

log_router = APIRouter()

active_connections = set()

@log_router.websocket("/ws/logs")
async def websocket_endpoint(websocket: WebSocket):
    await websocket.accept()
    active_connections.add(websocket)
    try:
        while True:
            await asyncio.sleep(60)  # Keep alive
    except WebSocketDisconnect:
        active_connections.remove(websocket)

# Helper for backend to broadcast log messages
async def broadcast_log(message: str):
    to_remove = set()
    for ws in active_connections:
        try:
            await ws.send_text(message)
        except Exception:
            to_remove.add(ws)
    for ws in to_remove:
        active_connections.remove(ws)
