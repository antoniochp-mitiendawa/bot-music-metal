#!/data/data/com.termux/files/usr/bin/bash

# ======================================================
# SISTEMA DE GESTIÓN METAL 2026 - VERSIÓN FINAL CONFIRMADA
# FLUJO: PAIRING -> ID CANAL -> URL APPS SCRIPT
# ======================================================

echo "--- INICIANDO ENTORNO TERMUX ---"
pkg update -y && pkg upgrade -y
pkg install nodejs -y

mkdir -p bot_metal && cd bot_metal

if [ ! -f package.json ]; then
    npm init -y
    npm install @whiskeysockets/baileys axios pino @adiwajshing/keyed-db readline
fi

cat << 'EOF' > index.js
const { 
    default: makeWASocket, 
    useMultiFileAuthState, 
    fetchLatestBaileysVersion 
} = require("@whiskeysockets/baileys");
const pino = require("pino");
const axios = require("axios");
const readline = require("readline");

const rl = readline.createInterface({ input: process.stdin, output: process.stdout });
const question = (text) => new Promise((resolve) => rl.question(text, resolve));

async function iniciarSistema() {
    const { state, saveCreds } = await useMultiFileAuthState('auth_info');
    const { version } = await fetchLatestBaileysVersion();

    const sock = makeWASocket({
        version,
        logger: pino({ level: 'silent' }),
        printQRInTerminal: false,
        auth: state,
        browser: ["Ubuntu", "Chrome", "20.0.04"]
    });

    // 👉 PASO 1: VINCULACIÓN
    if (!sock.authState.creds.registered) {
        console.log("\x1b[36m%s\x1b[0m", "\n--- VINCULACIÓN ---");
        const phoneNumber = await question("👉 Tu número (ej: 521...): ");
        const code = await sock.requestPairingCode(phoneNumber.trim());
        console.log(`\x1b[33m🔑 CÓDIGO DE VINCULACIÓN: ${code}\x1b[0m\n`);
    }

    sock.ev.on('creds.update', saveCreds);

    let canalId = "";
    let SCRIPT_URL = "";

    sock.ev.on('connection.update', (update) => {
        const { connection } = update;
        if (connection === 'open') {
            console.log("\x1b[32m%s\x1b[0m", "\n✅ WHATSAPP CONECTADO");
            console.log("👉 PASO 2: Por favor, envía un mensaje (ej: 'Hola') a tu CANAL de noticias ahora.");
            console.log("⏳ Esperando a detectar el ID real del canal...");
        }
    });

    sock.ev.on('messages.upsert', async m => {
        const msg = m.messages[0];
        if (!msg.message || msg.key.fromMe) return;

        // DETECCIÓN DEL ID DEL CANAL
        if (!canalId) {
            canalId = msg.key.remoteJid;
            console.log(`\x1b[32m%s\x1b[0m`, `\n✅ ID CAPTURADO: ${canalId}`);
            
            // 👉 PASO 3: URL DE APPS SCRIPT
            console.log("\n--- CONFIGURACIÓN DE DATOS ---");
            SCRIPT_URL = await question("👉 PASO 3: Pega la URL de tu App Script: ");
            
            console.log("\n🚀 Iniciando validación de prueba...");
            await realizarPruebaInmediata(sock, canalId, SCRIPT_URL);
            
            // INICIAR MONITOR AUTOMÁTICO
            setInterval(() => monitorear(sock, canalId, SCRIPT_URL), 60000);
        }
    });
}

async function realizarPruebaInmediata(sock, id, url) {
    try {
        const res = await axios.get(url.trim());
        const data = res.data[0]; 

        const mensaje = `🎸 *PRUEBA DE CONEXIÓN METAL 2026*\n\n` +
                        `💿 *Banda/Álbum:* ${data.banda}\n` +
                        `🎶 *Tracks:* ${data.tracks}\n` +
                        `🕒 *Horario:* ${data.horario}\n` +
                        `🔗 *YouTube:* ${data.youtube}`;
        
        await sock.sendMessage(id, { text: mensaje });
        console.log("✅ Mensaje de prueba enviado satisfactoriamente.");
    } catch (e) {
        console.log("❌ Error al leer la hoja de Google Sheets.");
    }
}

async function monitorear(sock, id, url) {
    try {
        const ahora = new Date().toLocaleTimeString('es-MX', { hour12: false, hour: '2-digit', minute: '2-digit' });
        const res = await axios.get(url.trim());
        
        res.data.forEach(async (fila) => {
            if (fila.horario === ahora) {
                const post = `🎸 *NUEVA PUBLICACIÓN*\n\n` +
                             `💿 *Álbum:* ${fila.banda}\n\n` +
                             `🎶 *Tracks:* \n${fila.tracks}\n\n` +
                             `🔗 *Escuchar:* ${fila.youtube}`;
                
                await sock.sendMessage(id, { text: post });
                console.log(`✨ Publicado: ${fila.banda} a las ${ahora}`);
            }
        });
    } catch (err) { /* Monitor silencioso */ }
}

iniciarSistema();
EOF

node index.js
