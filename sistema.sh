#!/data/data/com.termux/files/usr/bin/bash
termux-wake-lock

# --- CHECKPOINTS (INTOCABLES) --- [cite: 1]
PASO1_BASE=".sistema_base_ok"
PASO2_MOTOR=".motor_ia_ok"

if [ ! -f "$PASO1_BASE" ]; then
    pkg update -y -o Dpkg::Options::="--force-confold"
    pkg upgrade -y -o Dpkg::Options::="--force-confold"
    pkg install -y git openssl wget
    touch "$PASO1_BASE"
fi [cite: 2]

if [ ! -f "$PASO2_MOTOR" ]; then
    pkg install -y nodejs-lts python ffmpeg libsqlite
    mkdir -p datos_ia sesion_bot
    npm install @whiskeysockets/baileys pino readline axios cheerio node-cron
    touch "$PASO2_MOTOR"
fi [cite: 3]

cat << 'EOF' > bot_metal.js
const { default: makeWASocket, useMultiFileAuthState, delay, fetchLatestBaileysVersion, DisconnectReason } = require("@whiskeysockets/baileys"); [cite: 3]
const pino = require("pino");
const readline = require("readline");
const axios = require("axios");
const cheerio = require("cheerio");
const fs = require("fs");
const cron = require("node-cron"); [cite: 4]

const rl = readline.createInterface({ input: process.stdin, output: process.stdout }); [cite: 5]
const question = (text) => new Promise((resolve) => rl.question(text, resolve));

const CONFIG_PATH = "./datos_ia/config.json"; [cite: 6]
const LOCAL_DB = "./datos_ia/agenda_dia.json";

// --- NUEVO: SPINTAX Y BANDERAS (ADICIÓN SIN ALTERAR LÓGICA) ---
const spintax = {
    intro: ["🔥 ¡ESTRENO BRUTAL!", "🤘 NOVEDAD METALERA", "⚡ RECIÉN SALIDO", "🎸 IMPACTO TOTAL"],
    bio: ["📜 Historia:", "📖 Biografía:", "🔍 Sobre la banda:", "📄 Ficha técnica:"],
    link: ["🔗 Video oficial:", "🎥 Mira el video:", "🤘 Escúchalo aquí:"]
};
const getSpin = (t) => spintax[t][Math.floor(Math.random() * spintax[t].length)];
const banderas = { "Greece": "🇬🇷", "Sweden": "🇸🇪", "Norway": "🇳🇴", "Germany": "🇩🇪", "USA": "🇺🇸", "Canada": "🇨🇦", "Finland": "🇫🇮" };

function obtenerConfig() { 
    if (!fs.existsSync(CONFIG_PATH)) return {};
    try { return JSON.parse(fs.readFileSync(CONFIG_PATH)); } catch { return {}; }
} [cite: 7]
function guardarConfig(data) { fs.writeFileSync(CONFIG_PATH, JSON.stringify({ ...obtenerConfig(), ...data })); } [cite: 7]

function limpiarHorario(dato) {
    const match = String(dato).match(/(\d{1,2}:\d{2})/);
    if (!match) return null;
    let [h, m] = match[1].split(':');
    return `${h.padStart(2, '0')}:${m.padStart(2, '0')}`;
} [cite: 9]

// --- INVESTIGACIÓN MEJORADA (MANTIENE ESTRUCTURA ORIGINAL) --- [cite: 10]
async function investigarBandaPro(noticia) {
    const query = noticia.banda.split(" - ")[0];
    let origen = "Origen Confirmado 🌎";
    let historia = "Lanzamiento 2026.";
    
    try {
        const { data } = await axios.get(`https://www.metal-archives.com/search?searchString=${encodeURIComponent(query)}&type=band_name`, { timeout: 4000 });
        const $ = cheerio.load(data);
        const countryFound = $("table tr:first-child td:nth-child(2)").text().trim();
        if (countryFound) {
            const flag = banderas[countryFound] || "🌎";
            origen = `${countryFound} ${flag}`;
        }
    } catch (e) { /* Silencioso para no romper flujo */ }

    return { p: origen, h: historia, tracks: noticia.tracks ? `\n\n💿 *Tracks:*\n${noticia.tracks}` : "" }; [cite: 12]
}

async function sincronizarConGoogle() {
    const config = obtenerConfig();
    if (!config.urlGoogle) return [];
    try {
        const { data } = await axios.get(config.urlGoogle); [cite: 14]
        const agenda = data.map(i => ({ ...i, horarioLimpio: limpiarHorario(i.horario) })).filter(i => i.banda && i.horarioLimpio);
        fs.writeFileSync(LOCAL_DB, JSON.stringify(agenda));
        console.log(`📅 Agenda: ${agenda.length} bandas listas.`); [cite: 16]
        return agenda;
    } catch (e) { return fs.existsSync(LOCAL_DB) ? JSON.parse(fs.readFileSync(LOCAL_DB)) : []; }
}

async function dispararPublicacion(sock, noticia, esPrueba = false) {
    const config = obtenerConfig();
    if (!config.idCanal) return;

    // Simulación Humana (Typing)
    await sock.sendPresenceUpdate('composing', config.idCanal);
    await delay(3000 + Math.random() * 3000);

    const info = await investigarBandaPro(noticia); [cite: 18]
    const msg = `🎸 *${esPrueba?'PRUEBA':getSpin('intro')}* 🤘\n\n📢 *Disco:* ${noticia.banda}\n🌎 *Origen:* ${info.p}\n${getSpin('bio')} ${info.h}${info.tracks}\n\n${getSpin('link')} ${noticia.youtube}`;

    // Envío con Imagen si existe URL [cite: 19]
    if (noticia.imagen && noticia.imagen.startsWith('http')) {
        try {
            const res = await axios.get(noticia.imagen, { responseType: 'arraybuffer' });
            await sock.sendMessage(config.idCanal, { image: Buffer.from(res.data), caption: msg });
        } catch (e) { await sock.sendMessage(config.idCanal, { text: msg }); }
    } else {
        await sock.sendMessage(config.idCanal, { text: msg });
    }
    console.log(`🚀 ${esPrueba?'Prueba enviada':'Publicado'}: ${noticia.banda}`);
}

async function iniciar() {
    const { state, saveCreds } = await useMultiFileAuthState('sesion_bot');
    const { version } = await fetchLatestBaileysVersion(); [cite: 21]
    const sock = makeWASocket({ version, logger: pino({ level: "silent" }), auth: state, printQRInTerminal: false, browser: ["Ubuntu", "Chrome", "20.0.04"] });

    sock.ev.on("connection.update", async (up) => {
        const { connection, lastDisconnect } = up;
        if (connection === "close") { if (lastDisconnect?.error?.output?.statusCode !== DisconnectReason.loggedOut) iniciar(); }
        else if (connection === "open") {
            console.log("\n✅ ¡VINCULADO!");
            let config = obtenerConfig();

            // FLUJO DE CONFIGURACIÓN ORIGINAL (PROTEGIDO) [cite: 23]
            if (!config.idCanal) {
                console.log("\n👉 PASO 2: Por favor, envía un mensaje a tu CANAL ahora.");
                sock.ev.on("messages.upsert", async (m) => {
                    const msg = m.messages[0];
                    if (msg.key.remoteJid.endsWith("@newsletter") && !config.idCanal) {
                        const realID = msg.key.remoteJid;
                        console.log(`✅ ID REAL CAPTURADO: ${realID}`);
                        guardarConfig({ idCanal: realID });
                        config = obtenerConfig();
                        if (!config.urlGoogle) {
                            const url = await question("\n👉 PASO 3: Pega la URL de tu App Script: "); [cite: 26]
                            guardarConfig({ urlGoogle: url.trim(), esPrimeraVez: true });
                            const agenda = await sincronizarConGoogle();
                            if (agenda.length > 0) { 
                                await dispararPublicacion(sock, agenda[0], true); [cite: 27]
                                guardarConfig({ esPrimeraVez: false }); 
                            }
                        }
                    }
                });
            } else if (!config.urlGoogle) {
                const url = await question("👉 Pega la URL de tu App Script: "); [cite: 29]
                guardarConfig({ urlGoogle: url.trim(), esPrimeraVez: true });
                await sincronizarConGoogle();
            }

            // Cronograma original [cite: 31]
            cron.schedule('* * * * *', async () => {
                const ahora = new Date().toLocaleTimeString('es-MX', { hour12: false, hour: '2-digit', minute: '2-digit', timeZone: 'America/Mexico_City' });
                if (fs.existsSync(LOCAL_DB)) {
                    const datos = JSON.parse(fs.readFileSync(LOCAL_DB));
                    for (const item of datos) { 
                        if (item.horarioLimpio === ahora) {
                            const wait = Math.floor(Math.random() * 60000); // Variación de segundos
                            setTimeout(() => dispararPublicacion(sock, item), wait);
                        }
                    }
                }
            });
        }
    });

    if (!sock.authState.creds.registered) {
        await delay(5000);
        const numero = await question("👉 Tu número (ej: 521...): "); [cite: 33]
        const codigo = await sock.requestPairingCode(numero.trim());
        console.log(`\n🔑 CÓDIGO DE VINCULACIÓN: ${codigo}\n`);
    }
    sock.ev.on("creds.update", saveCreds);
}
iniciar();
EOF
node bot_metal.js
