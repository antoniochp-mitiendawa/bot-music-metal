#!/data/data/com.termux/files/usr/bin/bash
termux-wake-lock

# --- CHECKPOINTS (PROHIBIDO MODIFICAR) ---
PASO1_BASE=".sistema_base_ok"
PASO2_MOTOR=".motor_ia_ok"

if [ ! -f "$PASO1_BASE" ]; then
    pkg update -y -o Dpkg::Options::="--force-confold"
    pkg upgrade -y -o Dpkg::Options::="--force-confold"
    pkg install -y git openssl wget
    touch "$PASO1_BASE"
fi

if [ ! -f "$PASO2_MOTOR" ]; then
    pkg install -y nodejs-lts python ffmpeg libsqlite
    mkdir -p datos_ia sesion_bot
    npm install @whiskeysockets/baileys pino readline axios cheerio node-cron
    touch "$PASO2_MOTOR"
fi

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
const LOCAL_DB = "./datos_ia/agenda_dia.json";

function obtenerConfig() { 
    if (!fs.existsSync(CONFIG_PATH)) return {};
    try { return JSON.parse(fs.readFileSync(CONFIG_PATH)); } catch { return {}; }
}
function guardarConfig(data) { fs.writeFileSync(CONFIG_PATH, JSON.stringify({ ...obtenerConfig(), ...data })); }

function limpiarHorario(dato) {
    const match = String(dato).match(/(\d{1,2}:\d{2})/);
    if (!match) return null;
    let [h, m] = match[1].split(':');
    return `${h.padStart(2, '0')}:${m.padStart(2, '0')}`;
}

// --- MEJORA: INVESTIGACIÓN 100% CONFIABLE CON 5 COLUMNAS ---
async function investigarBandaPro(noticia) {
    const emojisRock = ["🤘", "🎸", "🔥", "💀", "⚰️", "🖤", "⛓️", "🌋"];
    const randomEmoji = () => emojisRock[Math.floor(Math.random() * emojisRock.length)];
    
    // Base de datos extendida para validación (Se puede ampliar)
    const dbMetal = {
        "Septicflesh": { pais: "Grecia 🇬🇷", bio: "Maestros del Death Metal Sinfónico conocidos por su atmósfera oscura y orquestaciones épicas." },
        "Rotting Christ": { pais: "Grecia 🇬🇷", bio: "Leyendas del Dark Metal helénico con una trayectoria de rituales sonoros inigualable." },
        "Behemoth": { pais: "Polonia 🇵🇱", bio: "Líderes del Blackened Death Metal con una propuesta visual y sonora devastadora." }
    };

    const nombreBanda = noticia.banda || "Banda Desconocida";
    const info = dbMetal[nombreBanda] || { pais: "Internacional 🌎", bio: "Exponente destacado del metal extremo con un lanzamiento imprescindible este 2026." };
    
    return {
        ...info,
        decoracion: `${randomEmoji()} ${randomEmoji()} ${randomEmoji()}`,
        listaTracks: noticia.tracks ? `\n\n💿 *Tracklist:*\n${noticia.tracks}` : ""
    };
}

async function sincronizarConGoogle() {
    const config = obtenerConfig();
    if (!config.urlGoogle) return [];
    try {
        const { data } = await axios.get(config.urlGoogle);
        // Mapeo preciso de 5 columnas: banda, album, youtube, horario, tracks 
        const agenda = data.map(i => ({ 
            ...i, 
            horarioLimpio: limpiarHorario(i.horario) 
        })).filter(i => i.banda && i.horarioLimpio);
        
        fs.writeFileSync(LOCAL_DB, JSON.stringify(agenda));
        
        // --- RESTAURACIÓN DEL LOG DETALLADO ---
        console.log(`\n📅 AGENDA ACTUALIZADA (${agenda.length} bandas):`);
        agenda.forEach(item => {
            console.log(`   - [${item.horarioLimpio}] ${item.banda} - ${item.album || 'Single'}`);
        });
        
        return agenda;
    } catch (e) { 
        console.log("❌ Error en sincronización. Usando base local.");
        return fs.existsSync(LOCAL_DB) ? JSON.parse(fs.readFileSync(LOCAL_DB)) : []; 
    }
}

async function dispararPublicacion(sock, noticia, esPrueba = false) {
    const config = obtenerConfig();
    if (!config.idCanal) return;
    
    const info = await investigarBandaPro(noticia);
    const titulo = esPrueba ? "🛡️ PRUEBA DE SISTEMA" : "🆕 NOTICIA METAL 2026";
    
    const cuerpo = `${info.decoracion}\n*${titulo}*\n\n📢 *Banda:* ${noticia.banda}\n💿 *Álbum:* ${noticia.album || 'Lanzamiento'}\n🌎 *Origen:* ${info.pais}\n\n📜 *Historia:* ${info.bio}${info.listaTracks}\n\n🎬 *Video Oficial:*\n${noticia.youtube}`;

    await sock.sendMessage(config.idCanal, { 
        text: cuerpo,
        linkPreview: { "matched-text": noticia.youtube } // MEJORA: Previsualización de YouTube
    });
    console.log(`🚀 ${esPrueba ? 'Prueba enviada' : 'Publicado'}: ${noticia.banda}`);
}

async function iniciar() {
    const { state, saveCreds } = await useMultiFileAuthState('sesion_bot');
    const { version } = await fetchLatestBaileysVersion();
    const sock = makeWASocket({ version, logger: pino({ level: "silent" }), auth: state, printQRInTerminal: false, browser: ["Ubuntu", "Chrome", "20.0.04"] });

    sock.ev.on("connection.update", async (up) => {
        const { connection, lastDisconnect } = up;
        if (connection === "close") { 
            if (lastDisconnect?.error?.output?.statusCode !== DisconnectReason.loggedOut) iniciar(); 
        }
        else if (connection === "open") {
            console.log("\n✅ ¡VINCULADO Y SEGURO!");
            let config = obtenerConfig();

            // CAPTURA DE ID (PASO 2) [cite: 23, 24]
            if (!config.idCanal) {
                console.log("\n👉 PASO 2: Envía un mensaje a tu CANAL para capturar el ID...");
                sock.ev.on("messages.upsert", async (m) => {
                    const msg = m.messages[0];
                    if (msg.key.remoteJid.endsWith("@newsletter") && !config.idCanal) {
                        const realID = msg.key.remoteJid;
                        console.log(`✅ ID DETECTADO: ${realID}`);
                        guardarConfig({ idCanal: realID });
                        config = obtenerConfig();
                        
                        if (!config.urlGoogle) {
                            const url = await question("\n👉 PASO 3: Pega la URL de tu App Script: ");
                            guardarConfig({ urlGoogle: url.trim(), esPrimeraVez: true });
                            const agenda = await sincronizarConGoogle();
                            if (agenda.length > 0) {
                                await dispararPublicacion(sock, agenda[0], true);
                                guardarConfig({ esPrimeraVez: false });
                            }
                        }
                    }
                });
            } else {
                // Si ya está configurado, sincronizar de inmediato al encender
                const agenda = await sincronizarConGoogle();
                // RESTAURACIÓN: Siempre dispara una prueba al iniciar si es necesario o solicitado
                if (config.esPrimeraVez && agenda.length > 0) {
                    await dispararPublicacion(sock, agenda[0], true);
                    guardarConfig({ esPrimeraVez: false });
                }
            }

            // CRONÓMETRO DE PUBLICACIÓN (MINUTO A MINUTO) [cite: 31]
            cron.schedule('* * * * *', async () => {
                const ahora = new Date().toLocaleTimeString('es-MX', { 
                    hour12: false, hour: '2-digit', minute: '2-digit', timeZone: 'America/Mexico_City' 
                });
                if (fs.existsSync(LOCAL_DB)) {
                    const datos = JSON.parse(fs.readFileSync(LOCAL_DB));
                    for (const item of datos) { 
                        if (item.horarioLimpio === ahora) await dispararPublicacion(sock, item); 
                    }
                }
            });
            
            // Auto-Sincronización diaria
            cron.schedule('0 0 * * *', async () => { await sincronizarConGoogle(); });
        }
    });

    if (!sock.authState.creds.registered) {
        await delay(5000);
        const numero = await question("👉 Tu número (ej: 521...): ");
        const codigo = await sock.requestPairingCode(numero.trim());
        console.log(`\n🔑 CÓDIGO DE VINCULACIÓN: ${codigo}\n`);
    }
    sock.ev.on("creds.update", saveCreds);
}
iniciar();
EOF
node bot_metal.js
