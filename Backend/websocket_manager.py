import json
from fastapi import WebSocket


class ConnectionManager:
    def __init__(self):
        self.rooms: dict[str, list[WebSocket]] = {}

    async def connect(self, websocket: WebSocket, room: str):
        await websocket.accept()
        if room not in self.rooms:
            self.rooms[room] = []
        self.rooms[room].append(websocket)

    def disconnect(self, websocket: WebSocket, room: str):
        if room in self.rooms:
            self.rooms[room] = [ws for ws in self.rooms[room] if ws != websocket]

    async def broadcast(self, room: str, message: dict):
        if room not in self.rooms:
            return
        dead = []
        for ws in self.rooms[room]:
            try:
                await ws.send_json(message)
            except Exception:
                dead.append(ws)
        for ws in dead:
            self.rooms[room].remove(ws)

    async def broadcast_all(self, message: dict):
        for room in list(self.rooms.keys()):
            await self.broadcast(room, message)


manager = ConnectionManager()
