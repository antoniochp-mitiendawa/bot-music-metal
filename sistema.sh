#!/data/data/com.termux/files/usr/bin/bash

# ======================================================
# PROYECTO: BOT MUSICAL - REPOSITORIO SISTEMA.SH
# VERSIÓN FINAL CONFIRMADA (MARZO 2026)
# ======================================================

echo "Iniciando configuración del entorno en Termux..."

# Instalación de dependencias base
pkg update -y && pkg upgrade -y
pkg install nodejs -y

# Crear carpeta de trabajo
mkdir -p canal_musica
cd canal_musica

# Instalación de librerías necesarias
if [ ! -f package.json ]; then
    npm init -y
    npm install @whiskeysockets/baileys axios pino @adiwajshing/keyed-db readline
fi

# Generación del archivo index.js (El núcleo del Bot)
cat << 'EOF' > index.js
const { 
    default: makeWASocket, 
    useMultiFileAuthState, 
    fetchLatestBaileysVersion,
    makeCacheableSignalKeyStore 
} = require("@whiskeysockets/baileys");
const pino = require("pino");
const axios = require("axios");
const readline = require("readline");

const rl = readline.createInterface({ input: process.stdin, output: process.stdout });
const question = (text) => new Promise((resolve) => rl.question(text, resolve));

// CONFIGURACIÓN - AQUÍ VA TU URL DE APPS SCRIPT
const SCRIPT_URL = "TU_URL_DE_APPS_SCRIPT_AQUI";

async function startBot() {
    const { state, saveCreds } = await useMultiFileAuthState('auth_session');
    const { version } = await fetchLatestBaileysVersion();

    const sock = makeWASocket({
        version,
        logger: pino({ level: 'silent' }),
        printQRInTerminal: false, // OBLIGATORIO PARA PAIRING CODE
        auth: state,
        browser: ["Ubuntu", "Chrome", "20.0.04"]
    });

    // SISTEMA DE EMPAREJAMIENTO (PAIRING CODE)
    if (!sock.authState.creds.registered) {
        console.log("\x1b[32m%s\x1b[0m", "--- MÓDULO DE EMPAREJAMIENTO ACTIVO ---");
        const phoneNumber = await question("Introduce tu número de WhatsApp con código de país (ej. 521XXXXXXXXXX): ");
        const code = await sock.requestPairingCode(phoneNumber.replace(/[^0-9]/g, ''));
        console.log(`\nTU CÓDIGO DE VINCULACIÓN ES: \x1b[33m${code}\x1b[0m\n`);
    }

    sock.ev.on('creds.update', saveCreds);

    sock.ev.on('connection.update', (update) => {
        const { connection, lastDisconnect } = update;
        if (connection === 'open') {
            console.log("CONEXIÓN EXITOSA: El bot está vinculado y listo.");
            // Monitoreo constante cada minuto
            setInterval(() => checkSchedule(sock), 60000);
        } else if (connection === 'close') {
            console.log("Conexión perdida. Reiniciando...");
            startBot();
        }
    });
}

async function checkSchedule(sock) {
    try {
        const res = await axios.get(SCRIPT_URL);
        const data = res.data; // Recibe el JSON del Apps Script

        const now = new Date();
        const currentTime = now.getHours().toString().padStart(2, '0') + ":" + 
                            now.getMinutes().toString().padStart(2, '0');

        data.forEach(async (row) => {
            // MAPEO EXACTO DE TUS COLUMNAS:
            // row['Banda y Álbum (2026)']
            // row['URL YouTube']
            // row['Horario (HH:mm)']
            // row['Listado de Tracks (Filtro)']

            if (row['Horario (HH:mm)'] === currentTime) {
                const caption = `🎸 *NUEVA PUBLICACIÓN*\n\n` +
                                `💿 *Álbum:* ${row['Banda y Álbum (2026)']}\n\n` +
                                `🎶 *Tracks:* \n${row['Listado de Tracks (Filtro)']}\n\n` +
                                `🔗 *Link:* ${row['URL YouTube']}`;

                // Enviamos al número del dueño que definimos como prueba
                await sock.sendMessage("TU_NUMERO_DE_DUENO@s.whatsapp.net", { text: caption });
                console.log(`Publicado correctamente: ${row['Banda y Álbum (2026)']}`);
            }
        });
    } catch (err) {
        console.log("Error consultando la hoja: ", err.message);
    }
}

startBot();
EOF

# Ejecución del sistema
echo "Lanzando el Bot..."
node index.js
