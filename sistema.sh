#!/data/data/com.termux/files/usr/bin/bash

# ======================================================
# SISTEMA DE PUBLICACIÓN MUSICAL - VERSIÓN FINAL 20-MAR
# EXTRACCIÓN DINÁMICA DE ID + PAIRING CODE
# ======================================================

echo "--- INICIANDO ENTORNO ---"
pkg update -y && pkg upgrade -y
pkg install nodejs -y

mkdir -p bot_musica && cd bot_musica

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

    // 1. URL DE IMPLEMENTACIÓN (GOOGLE SHEETS)
    console.log("\x1b[36m%s\x1b[0m", "\n--- CONFIGURACIÓN INICIAL ---");
    const SCRIPT_URL = await question("Pega la URL de la implementación de Google Apps Script: ");

    const sock = makeWASocket({
        version,
        logger: pino({ level: 'silent' }),
        printQRInTerminal: false,
        auth: state,
        browser: ["Ubuntu", "Chrome", "20.0.04"]
    });

    // 2. EMPAREJAMIENTO (PAIRING CODE)
    if (!sock.authState.creds.registered) {
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
            // Extraer el ID del canal/newsletter desde el mensaje recibido
            canalId = msg.key.remoteJid;
            console.log(`\x1b[32m%s\x1b[0m`, `\nID DE DESTINO CAPTURADO: ${canalId}`);
            
            // Realizar prueba inmediata con la información de la hoja
            try {
                const res = await axios.get(SCRIPT_URL.trim());
                const data = res.data[0]; 

                const mensajePrueba = `✅ *SISTEMA VINCULADO AL DESTINO*\n\n` +
                                      `🎸 *Banda y Álbum (2026):* ${data['Banda y Álbum (2026)']}\n` +
                                      `🎶 *Tracks:* ${data['Listado de Tracks (Filtro)']}\n` +
                                      `🕒 *Horario:* ${data['Horario (HH:mm)']}\n` +
                                      `🔗 *YouTube:* ${data['URL YouTube']}`;
                
                await sock.sendMessage(canalId, { text: mensajePrueba });
                console.log("Mensaje de prueba enviado con éxito.");

                // 4. INICIAR MONITOR DE HORARIOS
                setInterval(async () => {
                    const ahora = new Date().toLocaleTimeString('es-MX', { hour12: false, hour: '2-digit', minute: '2-digit' });
                    const refresh = await axios.get(SCRIPT_URL.trim());
                    
                    refresh.data.forEach(async (fila) => {
                        if (fila['Horario (HH:mm)'] === ahora) {
                            const post = `🎸 *NUEVA PUBLICACIÓN*\n\n` +
                                         `💿 *Álbum:* ${fila['Banda y Álbum (2026)']}\n\n` +
                                         `🎶 *Tracks:* \n${fila['Listado de Tracks (Filtro)']}\n\n` +
                                         `🔗 *Escuchar:* ${fila['URL YouTube']}`;
                            
                            await sock.sendMessage(canalId, { text: post });
                            console.log(`Publicación automática realizada: ${fila['Banda y Álbum (2026)']}`);
                        }
                    });
                }, 60000);

            } catch (err) {
                console.log("Error al leer la hoja de Google Sheets.");
            }
        }
    });

    sock.ev.on('connection.update', (update) => {
        const { connection } = update;
        if (connection === 'open') {
            console.log("\x1b[32m%s\x1b[0m", "\n--- BOT EN LÍNEA ---");
            console.log("ACCIÓN REQUERIDA: Envía cualquier mensaje desde el Canal o Newsletter para activarlo.");
        }
    });
}

iniciarSistema();
EOF

node index.js
