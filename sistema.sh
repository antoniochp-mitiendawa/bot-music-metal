#!/data/data/com.termux/files/usr/bin/bash
termux-wake-lock

# --- INSTALACIÓN COMPLETA ORIGINAL (PROTEGIDA) ---
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
const AGENDA_PATH = "./datos_ia/agenda.json";

// --- FUNCIONES DE PERSISTENCIA (BLINDADAS) ---
function obtenerConfig() {
    if (!fs.existsSync(CONFIG_PATH)) return {};
    return JSON.parse(fs.readFileSync(CONFIG_PATH));
}

function guardarConfig(data) {
    const actual = obtenerConfig();
    fs.writeFileSync(CONFIG_PATH, JSON.stringify({ ...actual, ...data }, null, 2));
}

// --- FUNCIONES DE VARIEDAD (SPINTAX) ---
function spintax(text) {
    return text.replace(/{([^{}]+)}/g, (match, options) => {
        const choices = options.split('|');
        return choices[Math.floor(Math.random() * choices.length)];
    });
}

const obtenerEmoji = () => {
    const emojis = ["🤘", "🔥", "🎸", "💀", "⚰️", "⚡", "🥁", "🌑", "⛓️", "🔊"];
    return emojis[Math.floor(Math.random() * emojis.length)];
};

async function sincronizarAgenda(url) {
    try {
        console.log("📥 Sincronizando agenda desde Google Sheets...");
        const { data } = await axios.get(url);
        fs.writeFileSync(AGENDA_PATH, JSON.stringify(data, null, 2));
        console.log("✅ Agenda guardada localmente en el teléfono.");
        return data;
    } catch (e) {
        console.log("❌ Error al sincronizar: " + e.message);
        if (fs.existsSync(AGENDA_PATH)) {
            console.log("⚠️ Usando última agenda guardada localmente.");
            return JSON.parse(fs.readFileSync(AGENDA_PATH));
        }
        return [];
    }
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
                const mensajeHandler = async (m) => {
                    const msg = m.messages[0];
                    if (msg.key.remoteJid.endsWith("@newsletter")) {
                        const realID = msg.key.remoteJid;
                        console.log(`✅ ID REAL CAPTURADO: ${realID}`);
                        guardarConfig({ idCanal: realID });
                        let configActualizada = obtenerConfig();
                        if (!configActualizada.urlGoogle) {
                            const url = await question("\n👉 PASO 3: Pega la URL de tu App Script: ");
                            guardarConfig({ urlGoogle: url.trim() });
                            console.log("✅ Configuración guardada.");
                            await sincronizarAgenda(url.trim());
                        }
                        sock.ev.off("messages.upsert", mensajeHandler);
                    }
                };
                sock.ev.on("messages.upsert", mensajeHandler);
            } else if (!config.urlGoogle) {
                const url = await question("\n👉 PASO EXTRA: Pega la URL de tu App Script: ");
                guardarConfig({ urlGoogle: url.trim() });
                await sincronizarAgenda(url.trim());
            }

            console.log("📅 Cargando agenda local del teléfono...");
            if (config.urlGoogle) {
                await sincronizarAgenda(config.urlGoogle);
            }

            cron.schedule('* * * * *', async () => {
                const conf = obtenerConfig();
                if (!fs.existsSync(AGENDA_PATH) || !conf.idCanal) return;

                const agendaLocal = JSON.parse(fs.readFileSync(AGENDA_PATH));
                const ahora = new Date().toLocaleTimeString('es-MX', { 
                    hour12: false, hour: '2-digit', minute: '2-digit', timeZone: 'America/Mexico_City' 
                });

                for (const item of agendaLocal) {
                    if (item.horario === ahora) {
                        console.log(`🚀 Iniciando secuencia de publicación para: ${item.banda}`);

                        // 1. Activar estado "Escribiendo..."
                        await sock.sendPresenceUpdate('composing', conf.idCanal);

                        // 2. Espera de 14 segundos para realismo y previsualización nativa
                        await delay(14000);

                        // 3. Construcción del mensaje con Spintax y Emojis
                        const intro = spintax("{🔥 ¡NUEVO ESTRENO!|🤘 ¡NOTICIA METALERA!|🎸 RECIÉN SALIDO DEL HORNO|💀 METAL ALERT|⚡ NOVEDAD RECOMENDADA}");
                        const labelBanda = spintax("{📢 Banda|🎸 Grupo|🔥 Artista|🌑 Proyecto}");
                        const labelTracks = spintax("{💿 Tracks|🎶 Lista de canciones|🎼 Temas|⛓️ Repertorio}");

                        const cuerpo = `${obtenerEmoji()} *${intro}* ${obtenerEmoji()}\n\n` +
                                       `${obtenerEmoji()} *${labelBanda}:* ${item.banda}\n` +
                                       `${obtenerEmoji()} *${labelTracks}:* ${item.tracks}\n\n` +
                                       `🎥 *Video:* ${item.youtube}`;

                        // 4. Envío de texto plano (WhatsApp generará el preview automáticamente)
                        await sock.sendMessage(conf.idCanal, { text: cuerpo });

                        // 5. Finalizar estado de presencia
                        await sock.sendPresenceUpdate('paused', conf.idCanal);
                        
                        await delay(2000);
                    }
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

node bot_metal.js
