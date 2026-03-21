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

const banderas = {
    "Grecia": "🇬🇷", "Sweden": "🇸🇪", "Norway": "🇳🇴", "Germany": "🇩🇪", "USA": "🇺🇸", "Mexico": "🇲🇽", "Finland": "🇫🇮", "Brazil": "🇧🇷", "Poland": "🇵🇱"
};

const spintax = {
    intro: ["🔥 *¡ALERTA DE ESTRENO!*", "🤘 *NOVEDAD BRUTAL*", "⚡ *IMPACTO METALERO*"],
    bio_label: ["📜 *Trasfondo:*", "📖 *La Historia:*", "🔍 *Análisis:*"],
    tracks_label: ["💿 *Setlist:*", "🎶 *Tracks:*"],
    link_label: ["🎥 *Video Oficial:*", "🔗 *Ver en YouTube:*"]
};
const getSpin = (t) => spintax[t][Math.floor(Math.random() * spintax[t].length)];

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

async function sincronizarConGoogle() {
    const config = obtenerConfig();
    if (!config.urlGoogle) return [];
    try {
        const { data } = await axios.get(config.urlGoogle);
        // Sincronización completa de 8 columnas
        const agenda = data.map(i => ({ 
            ...i, 
            horarioLimpio: limpiarHorario(i.horario) 
        })).filter(i => i.banda && i.horarioLimpio);
        fs.writeFileSync(LOCAL_DB, JSON.stringify(agenda));
        console.log(`📅 Agenda: ${agenda.length} bandas listas.`);
        return agenda;
    } catch (e) { return fs.existsSync(LOCAL_DB) ? JSON.parse(fs.readFileSync(LOCAL_DB)) : []; }
}

async function dispararPublicacion(sock, noticia, esPrueba = false) {
    const config = obtenerConfig();
    if (!config.idCanal) return;

    await sock.sendPresenceUpdate('composing', config.idCanal);
    await delay(7000); 

    const emojiPais = banderas[noticia.pais] || "🌎";
    const msg = `${getSpin('intro')}\n\n` +
                `📢 *Banda:* _${noticia.banda}_\n` +
                `🎸 *Género:* ${noticia.genero}\n` +
                `🌎 *Origen:* ${noticia.pais} ${emojiPais}\n\n` +
                `${getSpin('bio_label')}\n${noticia.bio}\n\n` +
                `${getSpin('tracks_label')}\n_${noticia.tracks}_\n\n` +
                `${getSpin('link_label')} ${noticia.youtube}`;

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
    const { version } = await fetchLatestBaileysVersion();
    const sock = makeWASocket({ version, logger: pino({ level: "silent" }), auth: state, printQRInTerminal: false, browser: ["Ubuntu", "Chrome", "20.0.04"] });

    sock.ev.on("connection.update", async (up) => {
        const { connection, lastDisconnect } = up;
        if (connection === "close") { 
            if (lastDisconnect?.error?.output?.statusCode !== DisconnectReason.loggedOut) iniciar(); 
        }
        else if (connection === "open") {
            console.log("\n✅ ¡SISTEMA METAL VINCULADO!");
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
                            const url = await question("\n👉 PASO 3: URL de App Script: ");
                            guardarConfig({ urlGoogle: url.trim() });
                            const agenda = await sincronizarConGoogle();
                            if (agenda.length > 0) await dispararPublicacion(sock, agenda[0], true);
                        }
                    }
                });
            } else if (!config.urlGoogle) {
                const url = await question("👉 Pega la URL de tu App Script: ");
                guardarConfig({ urlGoogle: url.trim() });
                await sincronizarConGoogle();
            }

            cron.schedule('* * * * *', async () => {
                const ahora = new Date().toLocaleTimeString('es-MX', { hour12: false, hour: '2-digit', minute: '2-digit', timeZone: 'America/Mexico_City' });
                if (fs.existsSync(LOCAL_DB)) {
                    const datos = JSON.parse(fs.readFileSync(LOCAL_DB));
                    for (const item of datos) { 
                        if (item.horarioLimpio === ahora) {
                            setTimeout(() => dispararPublicacion(sock, item), Math.random() * 5000);
                        }
                    }
                }
                if (new Date().getMinutes() % 15 === 0) await sincronizarConGoogle();
            });
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
