const http = require('http');
const { WebSocketServer, WebSocket } = require('ws');

const PORT = process.env.PORT || 8088;
const server = http.createServer((req, res) => {
  res.writeHead(200, { 'Content-Type': 'application/json' });
  res.end(JSON.stringify({
    status: 'online',
    game: 'Pickleball Smash Live Battle Server',
    activeRooms: rooms.size,
    timestamp: new Date().toISOString()
  }));
});

const wss = new WebSocketServer({ server });
const rooms = new Map(); // roomCode -> { hostSocket, clientSockets: Set, cachedState }
const socketToRoom = new Map(); // socket -> roomCode

wss.on('connection', (ws, req) => {
  const url = new URL(req.url, `http://${req.headers.host}`);
  const queryRoom = url.searchParams.get('room');
  const isHostQuery = url.searchParams.get('host') === 'true';

  ws.on('message', (message) => {
    try {
      const packet = JSON.parse(message.toString());
      const { type, senderId, data = {} } = packet;

      if (type === 'ping') {
        ws.send(JSON.stringify({
          type: 'pong',
          timestamp: Date.now(),
          senderId: 'server',
          data: { echo: packet.timestamp }
        }));
        return;
      }

      if (type === 'joinRoom') {
        const roomCode = data.roomCode || queryRoom || 'GLOBAL';
        joinRoom(ws, roomCode, senderId, data, isHostQuery);
        return;
      }

      const roomCode = socketToRoom.get(ws);
      if (roomCode && rooms.has(roomCode)) {
        const room = rooms.get(roomCode);
        if (type === 'roomSync') {
          room.cachedState = data;
        }

        // Broadcast to all other participants
        const raw = JSON.stringify(packet);
        if (room.hostSocket && room.hostSocket !== ws && room.hostSocket.readyState === WebSocket.OPEN) {
          room.hostSocket.send(raw);
        }
        for (const client of room.clientSockets) {
          if (client !== ws && client.readyState === WebSocket.OPEN) {
            client.send(raw);
          }
        }
      }
    } catch (err) {
      console.error('[PARSE ERROR]', err);
    }
  });

  ws.on('close', () => removeSocket(ws));
  ws.on('error', () => removeSocket(ws));
});

function joinRoom(ws, roomCode, senderId, data, isHost) {
  if (!rooms.has(roomCode)) {
    rooms.set(roomCode, { hostSocket: null, clientSockets: new Set(), cachedState: null });
  }
  const room = rooms.get(roomCode);
  socketToRoom.set(ws, roomCode);

  if (isHost || !room.hostSocket) {
    room.hostSocket = ws;
    console.log(`[ROOM ${roomCode}] Host connected (${senderId}). Active rooms: ${rooms.size}`);
  } else {
    room.clientSockets.add(ws);
    console.log(`[ROOM ${roomCode}] Guest connected (${senderId}). Total players: ${room.clientSockets.size + 1}`);
  }

  // Forward join request to host
  if (room.hostSocket && room.hostSocket !== ws && room.hostSocket.readyState === WebSocket.OPEN) {
    room.hostSocket.send(JSON.stringify({
      type: 'joinRoom',
      timestamp: Date.now(),
      senderId,
      data
    }));
  } else if (room.cachedState) {
    ws.send(JSON.stringify({
      type: 'roomSync',
      timestamp: Date.now(),
      senderId: 'server',
      data: room.cachedState
    }));
  }
}

function removeSocket(ws) {
  const roomCode = socketToRoom.get(ws);
  if (roomCode && rooms.has(roomCode)) {
    const room = rooms.get(roomCode);
    if (room.hostSocket === ws) {
      room.hostSocket = null;
      console.log(`[ROOM ${roomCode}] Host disconnected`);
    } else {
      room.clientSockets.delete(ws);
      console.log(`[ROOM ${roomCode}] Client disconnected`);
    }

    socketToRoom.delete(ws);
    if (!room.hostSocket && room.clientSockets.size === 0) {
      rooms.delete(roomCode);
      console.log(`[ROOM ${roomCode}] Closed (empty). Active rooms: ${rooms.size}`);
    }
  }
}

server.listen(PORT, () => {
  console.log(`🏓 PICKLEBALL SMASH Node.js WebSocket Server listening on port ${PORT}`);
});
