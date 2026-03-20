#!/data/data/com.termux/files/usr/bin/bash
termux-wake-lock

# --- CAPA DE INSTALACIÓN BLINDADA ---
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
    npm install @whiskeysockets/baileys pino readline axios node-cron
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

// --- BASE DE DATOS DE BANDERAS ---
const banderas = {
    "Grecia": "🇬🇷", "Sweden": "🇸🇪", "Suecia": "🇸🇪", "Norway": "🇳🇴", "Noruega": "🇳🇴",
    "Germany": "🇩🇪", "Alemania": "🇩🇪", "USA": "🇺🇸", "EEUU": "🇺🇸", "Mexico": "🇲🇽",
    "México": "🇲🇽", "Finland": "🇫🇮", "Finlandia": "🇫🇮", "Brazil": "🇧🇷", "Brasil": "🇧🇷",
    "England": "🏴󠁧󠁢󠁥󠁮󠁧󠁿", "Inglaterra": "🏴󠁧󠁢󠁥󠁮󠁧󠁿", "Canada": "🇨🇦", "Canadá": "🇨🇦"
};

// --- MOTOR DE SPINTAX NOTICIOSO ---
const spintax = {
    intro: ["🔥 *¡ALERTA DE ESTRENO!*", "🤘 *NOVEDAD BRUTAL*", "⚡ *IMPACTO METALERO*", "🎸 *CRÓNICA DEL DÍA*"],
    bio_label: ["📜 *Trasfondo:*", "📖 *La Historia:*", "🔍 *Análisis:*", "📄 *Ficha Técnica:*"],
    tracks_label: ["💿 *Setlist del Álbum:*", "🎶 *Tracks Destacados:*", "🎼 *Lista de Temas:*"],
    link_label: ["🎥 *Video Oficial:*", "🔗 *Mira el video aquí:*", "🤘 *Ver en YouTube:*"]
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
        // El bot ahora espera 8 columnas según la nueva hoja
        const agenda = data.map(i => ({ ...i, horarioLimpio: limpiarHorario(i.horario) })).filter(i => i.banda && i.horarioLimpio);
        fs.writeFileSync(LOCAL_DB, JSON.stringify(agenda));
        console.log(`📅 Sincronización exitosa: ${agenda.length} publicaciones en agenda.`);
        return agenda;
    } catch (e) { return fs.existsSync(LOCAL_DB) ? JSON.parse(fs.readFileSync(LOCAL_DB)) : []; }
}

async function dispararPublicacion(sock, noticia, esPrueba = false) {
    const config = obtenerConfig();
    if (!config.idCanal) return;

    // 1. Simulación Humana (Typing) de 8 segundos
    await sock.sendPresenceUpdate('composing', config.idCanal);
    await delay(8000);

    // 2. Procesamiento de Bandera
    const emojiPais = banderas[noticia.pais] || "🌎";

    // 3. Construcción del Mensaje con Formato Noticioso (Negritas y Cursivas)
    const msg = `${getSpin('intro')}\n\n` +
                `📢 *Banda:* _${noticia.banda}_\n` +
                `🎸 *Género:* ${noticia.genero}\n` +
                `🌎 *Origen:* ${noticia.pais} ${emojiPais}\n\n` +
                `${getSpin('bio_label')}\n${noticia.bio}\n\n` +
                `${getSpin('tracks_label')}\n_${noticia.tracks}_\n\n` +
                `${getSpin('link_label')} ${noticia.youtube}`;

    // 4. Envío de Imagen como Contenedor (Si existe URL)
    if (noticia.imagen && noticia.imagen.startsWith('http')) {
        try {
            const res = await axios.get(noticia.imagen, { responseType: 'arraybuffer' });
            await sock.sendMessage(config.idCanal, { 
                image: Buffer.from(res.data), 
                caption: msg 
            });
        } catch (e) { 
            await sock.sendMessage(config.idCanal, { text: msg }); 
        }
    } else {
        await sock.sendMessage(config.idCanal, { text: msg });
    }
    console.log(`🚀 Publicado: ${noticia.banda}`);
}

async function iniciar() {
    const { state, saveCreds } = await useMultiFileAuthState('sesion_bot');
    const { version } = await fetchLatestBaileysVersion();
    const sock = makeWASocket({ version, logger: pino({ level: "silent" }), auth: state, printQRInTerminal: false, browser: ["Ubuntu", "Chrome", "20.0.04"] });

    sock.ev.on("connection.update", async (up) => {
        const { connection, lastDisconnect } = up;
        if (connection === "close") { 
            if (lastDisconnect?.error?.output?.statusCode !== DisconnectReason.loggedOut) iniciar(); 
        } else if (connection === "open") {
            console.log("\n✅ SISTEMA METAL 2026 VINCULADO");
            let config = obtenerConfig();

            // PASO 2: CAPTURA DE ID (PROTEGIDO)
            if (!config.idCanal) {
                console.log("\n👉 PASO 2: Envía un mensaje a tu CANAL para capturar el ID.");
                sock.ev.on("messages.upsert", async (m) => {
                    const msg = m.messages[0];
                    if (msg.key.remoteJid.endsWith("@newsletter") && !config.idCanal) {
                        const realID = msg.key.remoteJid;
                        console.log(`✅ ID CAPTURADO: ${realID}`);
                        guardarConfig({ idCanal: realID });
                        config = obtenerConfig();
                        if (!config.urlGoogle) {
                            const url = await question("\n👉 PASO 3: Pega la URL de tu App Script: ");
                            guardarConfig({ urlGoogle: url.trim() });
                            const agenda = await sincronizarConGoogle();
                            if (agenda.length > 0) await dispararPublicacion(sock, agenda[0], true);
                        }
                    }
                });
            }

            // CRONOGRAMA DE PUBLICACIÓN
            cron.schedule('* * * * *', async () => {
                const ahora = new Date().toLocaleTimeString('es-MX', { hour12: false, hour: '2-digit', minute: '2-digit', timeZone: 'America/Mexico_City' });
                if (fs.existsSync(LOCAL_DB)) {
                    const datos = JSON.parse(fs.readFileSync(LOCAL_DB));
                    for (const item of datos) { 
                        if (item.horarioLimpio === ahora) {
                            // Delay aleatorio para evitar detección de bot
                            setTimeout(() => dispararPublicacion(sock, item), Math.random() * 10000);
                        }
                    }
                }
                // Sincronizar con la hoja cada 30 min automáticamente
                if (new Date().getMinutes() % 30 === 0) await sincronizarConGoogle();
            });
        }
    });

    if (!sock.authState.creds.registered) {
        await delay(5000);
        const numero = await question("👉 Introduce tu número (con código de país): ");
        const codigo = await sock.requestPairingCode(numero.trim());
        console.log(`\n🔑 TU CÓDIGO DE VINCULACIÓN: ${codigo}\n`);
    }
    sock.ev.on("creds.update", saveCreds);
}
iniciar();
EOF

node bot_metal.js
