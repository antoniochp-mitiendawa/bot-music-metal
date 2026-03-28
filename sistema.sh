#!/data/data/com.termux/files/usr/bin/bash
termux-wake-lock 

# --- INSTALACIÓN COMPLETA ORIGINAL (PROTEGIDA) ---
pkg update -y && pkg upgrade -y 
pkg install -y git nodejs-lts python ffmpeg libsqlite openssl wget 
mkdir -p datos_ia sesion_bot 
npm install @whiskeysockets/baileys pino readline axios node-cron 

cat << 'EOF' > bot_metal.js
const { default: makeWASocket, useMultiFileAuthState, delay, fetchLatestBaileysVersion, DisconnectReason } = require("@whiskeysockets/baileys"); 
const pino = require("pino"); [cite: 2]
const readline = require("readline"); [cite: 2]
const axios = require("axios"); [cite: 2]
const fs = require("fs"); [cite: 2]
const cron = require("node-cron"); [cite: 2]

const rl = readline.createInterface({ input: process.stdin, output: process.stdout }); [cite: 3]
const question = (text) => new Promise((resolve) => rl.question(text, resolve)); [cite: 3]
const CONFIG_PATH = "./datos_ia/config.json"; [cite: 4]
const AGENDA_PATH = "./datos_ia/agenda.json"; [cite: 4]

// --- FUNCIONES DE PERSISTENCIA (BLINDADAS) ---
function obtenerConfig() {
    if (!fs.existsSync(CONFIG_PATH)) return {}; [cite: 5]
    return JSON.parse(fs.readFileSync(CONFIG_PATH)); [cite: 5]
}

function guardarConfig(data) {
    const actual = obtenerConfig(); [cite: 6]
    fs.writeFileSync(CONFIG_PATH, JSON.stringify({ ...actual, ...data }, null, 2)); [cite: 6]
}

// --- NUEVAS FUNCIONES DE VARIEDAD (SPINTAX Y EMOJIS) ---
function spintax(text) {
    return text.replace(/{([^{}]+)}/g, function(match, options) {
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
        console.log("📥 Sincronizando agenda desde Google Sheets..."); [cite: 7]
        const { data } = await axios.get(url); [cite: 7]
        fs.writeFileSync(AGENDA_PATH, JSON.stringify(data, null, 2)); [cite: 7]
        console.log("✅ Agenda guardada localmente en el teléfono."); [cite: 7]
        return data; [cite: 8]
    } catch (e) {
        console.log("❌ Error al sincronizar: " + e.message); [cite: 9]
        if (fs.existsSync(AGENDA_PATH)) {
            console.log("⚠️ Usando última agenda guardada localmente."); [cite: 10]
            return JSON.parse(fs.readFileSync(AGENDA_PATH)); [cite: 10]
        }
        return []; [cite: 11]
    }
}

async function iniciar() {
    const { state, saveCreds } = await useMultiFileAuthState('sesion_bot'); [cite: 12]
    const { version } = await fetchLatestBaileysVersion(); [cite: 12]

    const sock = makeWASocket({
        version, [cite: 12]
        logger: pino({ level: "silent" }), [cite: 13]
        auth: state, [cite: 13]
        printQRInTerminal: false, [cite: 13]
        browser: ["Ubuntu", "Chrome", "20.0.04"] [cite: 13]
    });

    sock.ev.on("creds.update", saveCreds); [cite: 13]

    sock.ev.on("connection.update", async (up) => {
        const { connection, lastDisconnect } = up; [cite: 13]

        if (connection === "open") {
            console.log("\n✅ SISTEMA METAL CONECTADO Y VINCULADO"); [cite: 14]
            let config = obtenerConfig(); [cite: 14]

            if (!config.idCanal) {
                console.log("\n👉 PASO 2: Envía un mensaje a tu CANAL para capturar el ID."); [cite: 14]
                const mensajeHandler = async (m) => {
                    const msg = m.messages[0]; [cite: 15]
                    if (msg.key.remoteJid.endsWith("@newsletter")) {
                        const realID = msg.key.remoteJid; [cite: 15]
                        console.log(`✅ ID REAL CAPTURADO: ${realID}`); [cite: 15]
                        guardarConfig({ idCanal: realID }); [cite: 15]
                        let configActualizada = obtenerConfig(); [cite: 16]
                        if (!configActualizada.urlGoogle) {
                            const url = await question("\n👉 PASO 3: Pega la URL de tu App Script: "); [cite: 17]
                            guardarConfig({ urlGoogle: url.trim() }); [cite: 17]
                            console.log("✅ Configuración guardada."); [cite: 17]
                            await sincronizarAgenda(url.trim()); [cite: 18]
                        }
                        sock.ev.off("messages.upsert", mensajeHandler); [cite: 19]
                    }
                };
                sock.ev.on("messages.upsert", mensajeHandler); [cite: 20]
            } else if (!config.urlGoogle) {
                const url = await question("\n👉 PASO EXTRA: Pega la URL de tu App Script: "); [cite: 21]
                guardarConfig({ urlGoogle: url.trim() }); [cite: 21]
                await sincronizarAgenda(url.trim()); [cite: 21]
            }

            console.log("📅 Cargando agenda local del teléfono..."); [cite: 22]
            if (config.urlGoogle) {
                await sincronizarAgenda(config.urlGoogle); [cite: 23]
            }

            cron.schedule('* * * * *', async () => {
                const conf = obtenerConfig(); [cite: 24]
                if (!fs.existsSync(AGENDA_PATH) || !conf.idCanal) return; [cite: 24]

                const agendaLocal = JSON.parse(fs.readFileSync(AGENDA_PATH)); [cite: 25]
                const ahora = new Date().toLocaleTimeString('es-MX', { 
                    hour12: false, hour: '2-digit', minute: '2-digit', timeZone: 'America/Mexico_City' 
                });

                for (const item of agendaLocal) {
                    if (item.horario === ahora) {
                        console.log(`🚀 Publicando con variedad: ${item.banda}`);
                        
                        // Aplicación de Spintax y Emojis variados
                        const intro = spintax("{🔥 ¡NUEVO ESTRENO!|🤘 ¡NOTICIA METALERA!|🎸 RECIÉN SALIDO DEL HORNO|💀 METAL ALERT|⚡ NOVEDAD RECOMENDADA}");
                        const labelBanda = spintax("{📢 Banda|🎸 Grupo|🔥 Artista|🌑 Proyecto}");
                        const labelTracks = spintax("{💿 Tracks|🎶 Lista de canciones|🎼 Temas|⛓️ Repertorio}");

                        const cuerpo = `${obtenerEmoji()} *${intro}* ${obtenerEmoji()}\n\n` +
                                       `${obtenerEmoji()} *${labelBanda}:* ${item.banda}\n` +
                                       `${obtenerEmoji()} *${labelTracks}:* ${item.tracks}\n\n` +
                                       `🎥 *Video:* ${item.youtube}`;

                        // Envío con soporte de Preview de YouTube
                        await sock.sendMessage(conf.idCanal, { 
                            text: cuerpo,
                            contextInfo: {
                                externalAdReply: {
                                    title: item.banda,
                                    body: "Haz clic para ver el video",
                                    mediaType: 1,
                                    sourceUrl: item.youtube,
                                    thumbnailUrl: "https://img.youtube.com/vi/" + (item.youtube.includes('v=') ? item.youtube.split('v=')[1].split('&')[0] : item.youtube.split('/').pop()) + "/0.jpg"
                                }
                            }
                        }); 
                        await delay(2000); 
                    }
                }
            }); [cite: 29]
        }

        if (connection === "close") {
            if (lastDisconnect?.error?.output?.statusCode !== DisconnectReason.loggedOut) {
                iniciar(); [cite: 30]
            }
        }
    });

    if (!sock.authState.creds.registered) {
        await delay(5000); [cite: 32]
        const numero = await question("👉 Introduce tu número (con código de país, ej: 521...): "); [cite: 33]
        const codigo = await sock.requestPairingCode(numero.trim()); [cite: 33]
        console.log(`\n🔑 CÓDIGO DE VINCULACIÓN: ${codigo}\n`); [cite: 33]
    }
}

iniciar();
EOF

node bot_metal.js
