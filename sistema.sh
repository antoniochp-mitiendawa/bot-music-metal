#!/data/data/com.termux/files/usr/bin/bash
termux-wake-lock

# --- INSTALACIÓN COMPLETA ORIGINAL ---
pkg update -y && pkg upgrade -y
pkg install -y git nodejs-lts python ffmpeg libsqlite openssl wget
mkdir -p datos_ia sesion_bot
npm install @whiskeysockets/baileys pino readline axios node-cron

cat << 'EOF' > bot_metal.js
const { default: makeWASocket, useMultiFileAuthState, delay, fetchLatestBaileysVersion, DisconnectReason } = require("@whiskeysockets/baileys");
const pino = require("pino");
const readline = require("readline");
const axios = require("axios");
const fs = require("fs");
const cron = require("node-cron");

const rl = readline.createInterface({ input: process.stdin, output: process.stdout });
const question = (text) => new Promise((resolve) => rl.question(text, resolve));

const CONFIG_PATH = "./datos_ia/config.json";

function obtenerConfig() {
    if (!fs.existsSync(CONFIG_PATH)) return {};
    return JSON.parse(fs.readFileSync(CONFIG_PATH));
}

function guardarConfig(data) {
    const actual = obtenerConfig();
    fs.writeFileSync(CONFIG_PATH, JSON.stringify({ ...actual, ...data }));
}

async function iniciar() {
    const { state, saveCreds } = await useMultiFileAuthState('sesion_bot');
    const { version } = await fetchLatestBaileysVersion();

    const sock = makeWASocket({
        version,
        logger: pino({ level: "silent" }),
        auth: state,
        printQRInTerminal: false,
        browser: ["Ubuntu", "Chrome", "20.0.04"]
    });

    sock.ev.on("creds.update", saveCreds);

    sock.ev.on("connection.update", async (up) => {
        const { connection, lastDisconnect } = up;

        if (connection === "open") {
            console.log("\n✅ SISTEMA METAL CONECTADO Y VINCULADO");
            let config = obtenerConfig();

            if (!config.idCanal) {
                console.log("\n👉 PASO 2: Envía un mensaje a tu CANAL para capturar el ID.");
                sock.ev.on("messages.upsert", async (m) => {
                    const msg = m.messages[0];
                    if (msg.key.remoteJid.endsWith("@newsletter") && !config.idCanal) {
                        const realID = msg.key.remoteJid;
                        console.log(`✅ ID REAL CAPTURADO: ${realID}`);
                        guardarConfig({ idCanal: realID });
                        
                        if (!config.urlGoogle) {
                            const url = await question("\n👉 PASO 3: Pega la URL de tu App Script: ");
                            guardarConfig({ urlGoogle: url.trim() });
                            console.log("✅ Configuración guardada. El bot ya está activo.");
                        }
                    }
                });
            }

            // Ciclo de publicación original
            cron.schedule('* * * * *', async () => {
                const conf = obtenerConfig();
                if (!conf.urlGoogle || !conf.idCanal) return;

                try {
                    const { data } = await axios.get(conf.urlGoogle);
                    const ahora = new Date().toLocaleTimeString('es-MX', { 
                        hour12: false, 
                        hour: '2-digit', 
                        minute: '2-digit', 
                        timeZone: 'America/Mexico_City' 
                    });

                    for (const item of data) {
                        if (item.horario === ahora) {
                            console.log(`🚀 Publicando en canal: ${item.banda}`);
                            const cuerpo = `🔥 *¡NUEVO ESTRENO!* 🤘\n\n` +
                                           `📢 *Banda:* ${item.banda}\n` +
                                           `💿 *Tracks:* ${item.tracks}\n\n` +
                                           `🎥 *Video:* ${item.youtube}`;
                            
                            await sock.sendMessage(conf.idCanal, { text: cuerpo });
                        }
                    }
                } catch (e) {
                    console.log("Error en sincronización: " + e.message);
                }
            });
        }

        if (connection === "close") {
            if (lastDisconnect?.error?.output?.statusCode !== DisconnectReason.loggedOut) {
                iniciar();
            }
        }
    });

    if (!sock.authState.creds.registered) {
        await delay(5000);
        const numero = await question("👉 Introduce tu número (con código de país, ej: 521...): ");
        const codigo = await sock.requestPairingCode(numero.trim());
        console.log(`\n🔑 CÓDIGO DE VINCULACIÓN: ${codigo}\n`);
    }
}

iniciar();
EOF

node bot_met
