#!/data/data/com.termux/files/usr/bin/bash

# ======================================================
# SISTEMA DE GESTIÓN METAL 2026 - VERSIÓN FINAL CONFIRMADA
# VINCULACIÓN DINÁMICA + APPS SCRIPT JSON MAPPING
# ======================================================

echo "--- INICIANDO ENTORNO TERMUX ---"
pkg update -y && pkg upgrade -y
pkg install nodejs -y

mkdir -p bot_metal && cd bot_metal

# Instalación de dependencias si no existen
if [ ! -f package.json ]; then
    npm init -y
    npm install @whiskeysockets/baileys axios pino @adiwajshing/keyed-db readline
fi

# Creación del archivo index.js (El motor del bot)
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

    // 1. SOLICITUD DE URL DE IMPLEMENTACIÓN (WEB APP)
    console.log("\x1b[36m%s\x1b[0m", "\n--- CONFIGURACIÓN SISTEMA METAL ---");
    const SCRIPT_URL = await question("Pega la URL de la implementación (Apps Script): ");

    const sock = makeWASocket({
        version,
        logger: pino({ level: 'silent' }),
        printQRInTerminal: false,
        auth: state,
        browser: ["Ubuntu", "Chrome", "20.0.04"]
    });

    // 2. EMPAREJAMIENTO (PAIRING CODE)
    if (!sock.authState.creds.registered) {
        console.log("\n--- VINCULACIÓN WHATSAPP ---");
        const phoneNumber = await question("Introduce el número de este teléfono (ej. 521...): ");
        const code = await sock.requestPairingCode(phoneNumber.trim());
        console.log(`\nTU CÓDIGO DE VINCULACIÓN ES: \x1b[33m${code}\x1b[0m\n`);
    }

    sock.ev.on('creds.update', saveCreds);

    let canalId = "";

    // 3. CAPTURA DE ID Y FLUJO DE PRUEBA
    sock.ev.on('messages.upsert', async m => {
        const msg = m.messages[0];
        if (!msg.message || msg.key.fromMe) return;

        if (!canalId) {
            canalId = msg.key.remoteJid;
            console.log(`\x1b[32m%s\x1b[0m`, `\nID DE DESTINO CAPTURADO: ${canalId}`);
            
            // Realizar prueba inmediata con el formato de tu Apps Script
            try {
                const res = await axios.get(SCRIPT_URL.trim());
                const data = res.data[0]; // Mapeo según tu JSON: banda, youtube, horario, tracks

                const mensajePrueba = `✅ *SISTEMA METAL 2026 - VINCULADO*\n\n` +
                                      `🎸 *Álbum:* ${data.banda}\n` +
                                      `🎶 *Tracks:* ${data.tracks}\n` +
                                      `🕒 *Horario:* ${data.horario}\n` +
                                      `🔗 *YouTube:* ${data.youtube}`;
                
                await sock.sendMessage(canalId, { text: mensajePrueba });
                console.log("Mensaje de prueba enviado al destino capturado.");

                // 4. MONITOR DE HORARIOS (CADA MINUTO)
                setInterval(async () => {
                    const ahora = new Date().toLocaleTimeString('es-MX', { hour12: false, hour: '2-digit', minute: '2-digit' });
                    try {
                        const refresh = await axios.get(SCRIPT_URL.trim());
                        refresh.data.forEach(async (fila) => {
                            if (fila.horario === ahora) {
                                const post = `🎸 *NUEVA PUBLICACIÓN*\n\n` +
                                             `💿 *Álbum:* ${fila.banda}\n\n` +
                                             `🎶 *Tracks:* \n${fila.tracks}\n\n` +
                                             `🔗 *Escuchar:* ${fila.youtube}`;
                                
                                await sock.sendMessage(canalId, { text: post });
                                console.log(`Publicado: ${fila.banda} a las ${ahora}`);
                            }
                        });
                    } catch (e) { /* Error silencioso en monitoreo */ }
                }, 60000);

            } catch (err) {
                console.log("Error al obtener datos de Google Sheets. Revisa la URL.");
            }
        }
    });

    sock.ev.on('connection.update', (update) => {
        const { connection } = update;
        if (connection === 'open') {
            console.log("\x1b[32m%s\x1b[0m", "\n--- BOT EN LÍNEA ---");
            console.log("ENVÍA UN MENSAJE DESDE EL CANAL/NEWSLETTER PARA ACTIVAR EL SISTEMA.");
        }
    });
}

iniciarSistema();
EOF

echo "Lanzando el bot..."
node index.js
