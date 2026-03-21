#!/data/data/com.termux/files/usr/bin/bash
termux-wake-lock

# --- CAPA DE INSTALACIÓN ORIGINAL ---
pkg update -y -o Dpkg::Options::="--force-confold"
pkg upgrade -y -o Dpkg::Options::="--force-confold"
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

async function dispararPublicacion(sock, noticia, esPrueba = false) {
    const config = obtenerConfig();
    if (!config.idCanal) return;

    // Simulación humana de 5 segundos para el canal
    await sock.sendPresenceUpdate('composing', config.idCanal);
    await delay(5000);

    const msg = `🔥 *${esPrueba ? 'PRUEBA DE CONEXIÓN' : '¡NUEVO ESTRENO!'}* 🤘\n\n` +
                `📢 *Banda:* ${noticia.banda}\n` +
                `💿 *Tracks:* ${noticia.tracks}\n\n` +
                `🎥 *Video:* ${noticia.youtube}`;

    await sock.sendMessage(config.idCanal, { text: msg });
    console.log(`🚀 ${esPrueba ? 'Mensaje de prueba enviado' : 'Publicado'}: ${noticia.banda}`);
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
            console.log("\n✅ SISTEMA METAL 2026 VINCULADO");
            let config = obtenerConfig();

            if (!config.idCanal) {
                console.log("\n👉 PASO 2: Envía un mensaje a tu CANAL para capturar el ID.");
                sock.ev.on("messages.upsert", async (m) => {
                    const msg = m.messages[0];
                    if (msg.key.remoteJid.endsWith("@newsletter") && !config.idCanal) {
                        const realID = msg.key.remoteJid;
                        console.log(`✅ ID REAL CAPTURADO: ${realID}`);
                        guardarConfig({ idCanal: realID });
                        config = obtenerConfig();
                        
                        if (!config.urlGoogle) {
                            const url = await question("\n👉 PASO 3: Pega la URL de tu App Script: ");
                            guardarConfig({ urlGoogle: url.trim() });
                            
                            // SINCRONIZACIÓN Y PRUEBA INMEDIATA (Original)
                            try {
                                const { data } = await axios.get(url.trim());
                                if (data.length > 0) {
                                    await dispararPublicacion(sock, data[0], true);
                                    console.log("✅ Sistema activo y probado.");
                                }
                            } catch (e) { console.log("⚠️ Error en prueba inicial."); }
                        }
                    }
                });
            }

            cron.schedule('* * * * *', async () => {
                const conf = obtenerConfig();
                if (!conf.urlGoogle || !conf.idCanal) return;

                try {
                    const { data } = await axios.get(conf.urlGoogle);
                    const ahora = new Date().toLocaleTimeString('es-MX', { 
                        hour12: false, hour: '2-digit', minute: '2-digit', timeZone: 'America/Mexico_City' 
                    });

                    for (const item of data) {
                        if (item.horario === ahora) {
                            await dispararPublicacion(sock, item);
                        }
                    }
                } catch (e) { console.log("Error sincronización cron."); }
            });
        }

        if (connection === "close") {
            if (lastDisconnect?.error?.output?.statusCode !== DisconnectReason.loggedOut) iniciar();
        }
    });

    if (!sock.authState.creds.registered) {
        await delay(5000);
        const numero = await question("👉 Introduce tu número (521...): ");
        const codigo = await sock.requestPairingCode(numero.trim());
        console.log(`\n🔑 CÓDIGO DE VINCULACIÓN: ${codigo}\n`);
    }
}

iniciar();
EOF

node bot_metal.js
