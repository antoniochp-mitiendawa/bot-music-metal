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

// --- DICCIONARIO DE BANDERAS (NORMALIZACIÓN) ---
const obtenerBandera = (pais) => {
    if (!pais) return "🌍";
    const p = pais.toLowerCase().trim();
    const banderas = {
        "mexico": "🇲🇽", "méxico": "🇲🇽", "usa": "🇺🇸", "eeuu": "🇺🇸", "united states": "🇺🇸",
        "germany": "🇩🇪", "alemania": "🇩🇪", "sweden": "🇸🇪", "suecia": "🇸🇪", "norway": "🇳🇴", "noruega": "🇳🇴",
        "finland": "🇫🇮", "finlandia": "🇫🇮", "brazil": "🇧🇷", "brasil": "🇧🇷", "uk": "🇬🇧", "reino unido": "🇬🇧",
        "england": "🏴󠁧󠁢󠁥󠁮󠁧󠁿", "greece": "🇬🇷", "grecia": "🇬🇷", "france": "🇫🇷", "francia": "🇫🇷",
        "italy": "🇮🇹", "italia": "🇮🇹", "spain": "🇪🇸", "españa": "🇪🇸", "canada": "🇨🇦", "canadá": "🇨🇦",
        "australia": "🇦🇺", "argentina": "🇦🇷", "chile": "🇨🇱", "colombia": "🇨🇴", "poland": "🇵🇱", "polonia": "🇵🇱"
    };
    return banderas[p] || "🌍";
};

// --- FUNCIONES DE PERSISTENCIA ---
function obtenerConfig() {
    if (!fs.existsSync(CONFIG_PATH)) return {};
    return JSON.parse(fs.readFileSync(CONFIG_PATH));
}

function guardarConfig(data) {
    const actual = obtenerConfig();
    fs.writeFileSync(CONFIG_PATH, JSON.stringify({ ...actual, ...data }, null, 2));
}

// --- SPINTAX LIMPIO (SIN EMOJIS INTERNOS) ---
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

// --- SINCRONIZACIÓN ÚNICA (8:00 AM) ---
async function sincronizarAgenda(url) {
    if (!url) return;
    try {
        console.log("📥 [Sincronización] Consultando Google Sheets...");
        const { data } = await axios.get(url);
        fs.writeFileSync(AGENDA_PATH, JSON.stringify(data, null, 2));
        console.log("✅ Agenda actualizada y guardada localmente.");
        return data;
    } catch (e) {
        console.log("⚠️ Error de conexión: Usando caché local.");
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
            console.log("\n✅ SISTEMA METAL " + 2026 + " CONECTADO");
            let config = obtenerConfig();

            // Sincronización inicial si no existe archivo local
            if (!fs.existsSync(AGENDA_PATH) && config.urlGoogle) {
                await sincronizarAgenda(config.urlGoogle);
            }

            if (!config.idCanal) {
                console.log("\n👉 PASO 2: Envía un mensaje a tu CANAL...");
                const mensajeHandler = async (m) => {
                    const msg = m.messages[0];
                    if (msg.key.remoteJid.endsWith("@newsletter")) {
                        const realID = msg.key.remoteJid;
                        guardarConfig({ idCanal: realID });
                        let configAct = obtenerConfig();
                        if (!configAct.urlGoogle) {
                            const url = await question("\n👉 PASO 3: URL App Script: ");
                            guardarConfig({ urlGoogle: url.trim() });
                            await sincronizarAgenda(url.trim());
                        }
                        sock.ev.off("messages.upsert", mensajeHandler);
                    }
                };
                sock.ev.on("messages.upsert", mensajeHandler);
            }

            // --- CRON: SINCRONIZAR SOLO A LAS 8:00 AM ---
            cron.schedule('0 8 * * *', async () => {
                const conf = obtenerConfig();
                await sincronizarAgenda(conf.urlGoogle);
            });

            // --- CRON: PUBLICACIÓN MINUTO A MINUTO ---
            cron.schedule('* * * * *', async () => {
                const conf = obtenerConfig();
                if (!fs.existsSync(AGENDA_PATH) || !conf.idCanal) return;

                const agenda = JSON.parse(fs.readFileSync(AGENDA_PATH));
                const ahora = new Date().toLocaleTimeString('es-MX', { 
                    hour12: false, hour: '2-digit', minute: '2-digit', timeZone: 'America/Mexico_City' 
                });

                for (const item of agenda) {
                    if (item.horario === ahora) {
                        console.log(`🚀 Publicando estreno: ${item.banda}`);
                        
                        // Estado "Escribiendo" por 14 segundos
                        await sock.sendPresenceUpdate('composing', conf.idCanal);
                        await delay(14000);

                        // Spintax Sin Emojis (Limpieza Total)
                        const titulo = spintax("{NUEVO ESTRENO|NOTICIA METALERA|RECIÉN SALIDO|METAL ALERT|NOVEDAD RECOMENDADA}");
                        const etiquetaBanda = spintax("{Banda|Grupo|Artista|Proyecto}");
                        const etiquetaOrigen = spintax("{Origen|Desde|Procedencia|País}");
                        const bandera = obtenerBandera(item.tracks); // Usamos la columna 'tracks' para el País

                        // Estética: 1 solo emoji por línea + Triple Espacio
                        const cuerpo = `${r()} *${titulo}*\n\n\n` +
                                       `🎥 *Video Oficial:*\n` +
                                       `${item.youtube}\n` +
                                       `_(Toca el link azul de arriba para reproducir 👆)_\n\n` +
                                       `${r()} *${etiquetaBanda}:* ${item.banda}\n` +
                                       `${bandera} *${etiquetaOrigen}:* ${item.tracks}`;

                        await sock.sendMessage(conf.idCanal, { 
                            text: cuerpo,
                            contextInfo: {
                                externalAdReply: {
                                    title: item.banda,
                                    body: "Ver Estreno en YouTube",
                                    mediaType: 1,
                                    sourceUrl: item.youtube,
                                    thumbnailUrl: "https://img.youtube.com/vi/" + (item.youtube.split('v=')[1] || "").split('&')[0] + "/maxresdefault.jpg"
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
