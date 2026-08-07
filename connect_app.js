#!/usr/bin/env node
// Connect to an OnionChat room exactly like the app's "Connect" button.
// Usage: node connect_app.js <onion> [password] [username] [socksPort] [--msg "text"]
// Lines typed on stdin (or a FIFO) are sent as chat messages once joined.
const { SocksProxyAgent } = require("socks-proxy-agent");
const WebSocket = require("ws");
const readline = require("readline");

const args = process.argv.slice(2);
const onion = args[0];
const password = args[1] || "";
let username = args[2] || "arcxlo-bot";
const socksPort = args[3] || "19050";
let queued = [];
const msgIdx = args.indexOf("--msg");
if (msgIdx >= 0 && args[msgIdx + 1]) queued.push(args[msgIdx + 1]);

if (!onion) {
  console.error("usage: node connect_app.js <onion> [password] [username] [socksPort] [--msg text]");
  process.exit(1);
}

const url = `ws://${onion}/`;
const agent = new SocksProxyAgent(`socks5h://127.0.0.1:${socksPort}`);
const ws = new WebSocket(url, { agent, handshakeTimeout: 45000, rejectUnauthorized: false });
let joined = false;

function send(obj) {
  if (ws.readyState === WebSocket.OPEN) ws.send(JSON.stringify(obj));
}
function sendMessage(text) {
  const t = text.trim();
  if (!t) return;
  if (joined) {
    send({ type: "message", text: t, id: `${Date.now()}-${Math.random().toString(36).slice(2, 8)}` });
    console.log(`[me] ${t}`);
  } else {
    queued.push(t);
    console.log(`[q] queued (not joined yet): ${t}`);
  }
}

const rl = readline.createInterface({ input: process.stdin });
rl.on("line", (line) => {
  const t = line.trim();
  if (!t) return;
  if (t.startsWith("/username ")) {
    username = t.slice("/username ".length).trim();
    if (username) { send({ type: "username", username }); console.log(`[i] username -> ${username}`); }
  } else {
    sendMessage(t);
  }
});

ws.on("open", () => {
  console.log(`[+] socket open -> ${onion}`);
  console.log(`[>] sending auth (password: ${password ? "set" : "none"})...`);
  send({ type: "auth", password });
});

ws.on("message", (raw) => {
  let msg;
  try { msg = JSON.parse(raw.toString()); } catch (_) { return; }
  switch (msg.type) {
    case "prompt":
      console.log(`[>] host asks for username, sending "${username}"...`);
      send({ type: "username", username });
      break;
    case "pending":
      console.log("[!!] JOIN PENDING - waiting for host approval on their phone...");
      break;
    case "ready":
      joined = true;
      console.log(`[+] READY! joined as "${msg.username}" color=${msg.color}`);
      console.log(`[+] members: ${(msg.members || []).map((m) => m.username).join(", ") || "(none yet)"}`);
      if (msg.history) console.log(`[+] history: ${msg.history.length} prior messages`);
      for (const m of queued.splice(0)) sendMessage(m);
      break;
    case "member":
      console.log(`[+] new member joined: ${msg.member?.username}`);
      break;
    case "profile":
      console.log(`[+] ${msg.oldUsername} -> ${msg.username} changed profile`);
      break;
    case "auth_failed":
      console.error("[!!] AUTH FAILED (wrong password)");
      process.exit(1);
      break;
    case "denied":
      console.error("[!!] DENIED - host rejected the join request");
      process.exit(1);
      break;
    case "kicked":
      console.error(`[!!] KICKED by host: ${msg.text || "(no reason)"}`);
      break;
    case "message":
      console.log(`[msg] ${msg.username}: ${msg.text}`);
      break;
    case "system":
      console.log(`[sys] ${msg.text}`);
      break;
    case "media":
      console.log(`[media] ${msg.username} shared ${msg.mediaType} (${msg.mediaName || "untitled"})`);
      break;
    case "edit":
      console.log(`[edit] ${msg.username} edited a message: ${msg.text}`);
      break;
    case "delete":
      console.log(`[del] message ${msg.messageId} deleted`);
      break;
    case "delete_all_messages":
      console.log("[sys] host wiped all messages");
      break;
    default:
      console.log(`[?] ${JSON.stringify(msg)}`);
  }
});

ws.on("error", (e) => console.error(`[!] connection error: ${e.message}`));
ws.on("close", (code, reason) => {
  console.log(`[x] closed (${code}${reason ? " " + reason : ""})`);
  process.exit(0);
});

process.on("SIGINT", () => {
  try { ws.close(); } catch (_) {}
  setTimeout(() => process.exit(0), 500);
});

setInterval(() => {}, 1000);
