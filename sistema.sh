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

const r = () => {
    const emojis = ["🤘", "🔥", "🎸", "💀", "⚡", "🥁", "🌑", "⛓️"];
    return emojis[Math.floor(Math.random() * emojis.length)];
};

const evideo = () => {
    const emjV = ["🎥", "🎬", "📺", "📼", "📀"];
    return emjV[Math.floor(Math.random() * emjV.length)];
};

// --- SINCRONIZACIÓN INTELIGENTE (GOOGLE SHEETS) ---
async function sincronizarAgenda(url) {
    if (!url) return;
    try {
        console.log("📥 [8:00 AM] Sincronizando agenda desde Google Sheets...");
        const { data } = await axios.get(url);
        fs.writeFileSync(AGENDA_PATH, JSON.stringify(data, null, 2));
        console.log("✅ Datos guardados localmente. No habrá más peticiones a Google hoy.");
        return data;
    } catch (e) {
        console.log("❌ Error de red: Usando base de datos local.");
        return fs.existsSync(AGENDA_PATH) ? JSON.parse(fs.readFileSync(AGENDA_PATH)) : [];
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

            // Sincronización inicial solo si no hay agenda
            if (!fs.existsSync(AGENDA_PATH) && config.urlGoogle) {
                await sincronizarAgenda(config.urlGoogle);
            }

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
                            await sincronizarAgenda(url.trim());
                        }
                        sock.ev.off("messages.upsert", mensajeHandler);
                    }
                };
                sock.ev.on("messages.upsert", mensajeHandler);
            }

            // CRON 1: Sincronización ÚNICA a las 8:00 AM
            cron.schedule('0 8 * * *', async () => {
                const conf = obtenerConfig();
                await sincronizarAgenda(conf.urlGoogle);
            });

            // CRON 2: Verificación de publicaciones (Cada minuto en local)
            cron.schedule('* * * * *', async () => {
                const conf = obtenerConfig();
                if (!fs.existsSync(AGENDA_PATH) || !conf.idCanal) return;

                const agendaLocal = JSON.parse(fs.readFileSync(AGENDA_PATH));
                const ahora = new Date().toLocaleTimeString('es-MX', { 
                    hour12: false, hour: '2-digit', minute: '2-digit', timeZone: 'America/Mexico_City' 
                });

                for (const item of agendaLocal) {
                    if (item.horario === ahora) {
                        console.log(`🚀 Iniciando secuencia para: ${item.banda}`);
                        
                        // Typing y Delay de 14 segundos
                        await sock.sendPresenceUpdate('composing', conf.idCanal);
                        await delay(14000);

                        // Spintax y Variedad
                        const txt = spintax("{🔥 ¡NUEVO ESTRENO!|🤘 ¡NOTICIA METALERA!|🎸 RECIÉN SALIDO|💀 METAL ALERT|⚡ NOVEDAD RECOMENDADA}");
                        const bnd = spintax("{📢 Banda|🎸 Grupo|🔥 Artista|🌑 Proyecto}");
                        const trk = spintax("{💿 Tracks|🎶 Lista de canciones|🎼 Repertorio|⛓️ Canciones}");
                        const vtxt = spintax("{Ver video oficial aquí:|Haz clic para el estreno:|Liga del video oficial:|Disfruta el nuevo material:}");

                        // Construcción con Jerarquía (Link arriba + 3 espacios)
                        const cuerpo = `${r()} *${txt}*\n\n\n` + 
                                       `${evideo()} _${vtxt}_\n` +
                                       `${item.youtube}\n\n` + 
                                       `${r()} *${bnd}:* ${item.banda}\n` +
                                       `${r()} *${trk}:* ${item.tracks}`;

                        await sock.sendMessage(conf.idCanal, { 
                            text: cuerpo,
                            contextInfo: {
                                externalAdReply: {
                                    title: item.banda,
                                    body: "Reproducir ahora",
                                    mediaType: 1,
                                    sourceUrl: item.youtube,
                                    thumbnailUrl: "https://img.youtube.com/vi/" + (item.youtube.split('v=')[1] || "").split('&')[0] + "/0.jpg"
                                }
                            }
                        });

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
        const numero = await question("👉 Introduce tu número (521...): ");
        const codigo = await sock.requestPairingCode(numero.trim());
        console.log(`\n🔑 CÓDIGO DE VINCULACIÓN: ${codigo}\n`);
    }
}

iniciar();
EOF

node bot_metal.js
