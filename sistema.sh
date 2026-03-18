#!/data/data/com.termux/files/usr/bin/bash

# Activar persistencia para que Termux no se detenga en segundo plano
termux-wake-lock

# --- CHECKPOINTS (PROHIBIDO MODIFICAR 1 Y 2 - BLINDADO) ---
PASO1_BASE=".sistema_base_ok"
PASO2_MOTOR=".motor_ia_ok"

echo "🤖 [SISTEMA] Cargando Motor de Noticias Blindado..."

# ==========================================
# PASO 1: CIMENTACIÓN (BLINDADO)
# ==========================================
if [ -f "$PASO1_BASE" ];
then
    echo "✅ [MEMORIA] Paso 1 listo."
else
    pkg update -y -o Dpkg::Options::="--force-confold"
    pkg upgrade -y -o Dpkg::Options::="--force-confold"
    pkg install -y git openssl wget
    touch "$PASO1_BASE"
fi

# ==========================================
# PASO 2: MOTOR DE EJECUCIÓN (BLINDADO)
# ==========================================
if [ -f "$PASO2_MOTOR" ];
then
    echo "✅ [MEMORIA] Paso 2 listo."
else
    pkg install -y nodejs-lts python ffmpeg libsqlite
    mkdir -p datos_ia
    mkdir -p sesion_bot
    npm install @whiskeysockets/baileys pino readline axios cheerio node-cron
    touch "$PASO2_MOTOR"
fi

# ==========================================
# PASO 3: INDEX.JS (CONECTOR + NOTICIERO INTEGRADO)
# ==========================================
cat << 'EOF' > index.js
const { 
    default: makeWASocket, 
    useMultiFileAuthState, 
    delay, 
    fetchLatestBaileysVersion, 
    DisconnectReason 
} = require("@whiskeysockets/baileys");
const pino = require("pino");
const readline = require("readline");
const axios = require("axios");
const cheerio = require("cheerio");
const cron = require("node-cron");
const fs = require("fs");

const rl = readline.createInterface({ input: process.stdin, output: process.stdout });
const question = (text) => new Promise((resolve) => rl.question(text, resolve));

let sock;
const DB_PATH = "./datos_ia/enviados.json";
const CONFIG_PATH = "./datos_ia/config.json";

// --- CONFIGURACIÓN DE DISFRAZ (ANTI-BOT) ---
const HEADERS_ANDROID = {
    'User-Agent': 'Mozilla/5.0 (Linux; Android 14; Pixel 8) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/122.0.0.0 Mobile Safari/537.36',
    'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,*/*;q=0.8',
    'Accept-Language': 'es-ES,es;q=0.9,en;q=0.8',
    'Referer': 'https://www.google.com/'
};

// --- FUNCIONES DE PERSISTENCIA DE DATOS ---
function cargarEnviados() {
    if (!fs.existsSync(DB_PATH)) return [];
    try { return JSON.parse(fs.readFileSync(DB_PATH)); } catch { return []; }
}

function guardarEnviado(titulo) {
    const enviados = cargarEnviados();
    enviados.push(titulo);
    if (enviados.length > 100) enviados.shift();
    fs.writeFileSync(DB_PATH, JSON.stringify(enviados));
}

function obtenerConfig() {
    if (!fs.existsSync(CONFIG_PATH)) return null;
    try { return JSON.parse(fs.readFileSync(CONFIG_PATH)); } catch { return null; }
}

function guardarConfig(data) {
    const actual = obtenerConfig() || {};
    fs.writeFileSync(CONFIG_PATH, JSON.stringify({ ...actual, ...data }));
}

// --- EXTRACTOR INTELIGENTE MULTIFUENTE ---
async function extraerNoticia(url) {
    try {
        const { data } = await axios.get(url, { headers: HEADERS_ANDROID, timeout: 15000 });
        const $ = cheerio.load(data);
        const post = $("article, .post, .torrent-box").first();
        
        let tituloRaw = post.find("h2, .entry-title, .title").first().text().trim();
        let tituloLimpio = tituloRaw.replace(/\[.*?\]|\(.*?\)|320\s?kbps|\.rar/gi, "").trim();

        if (!tituloLimpio || cargarEnviados().includes(tituloLimpio)) return null;

        // Intento de extraer tracklist
        let tracks = post.find("ul li, .tracklist, .songs").map((i, el) => $(el).text().trim()).get().slice(0, 10);
        let listaTracks = tracks.length > 0 ? "\n\n📋 *TRACKLIST:*\n" + tracks.map(t => `🔹 ${t}`).join("\n") : "";

        const queryYT = tituloLimpio.replace(/\s+/g, "+");
        const youtube = `https://www.youtube.com/results?search_query=${queryYT}+2026`;

        const emojis = ["🎸", "🤘", "🔊", "💿", "⛓️", "💀", "🔥"];
        const emo = () => emojis[Math.floor(Math.random() * emojis.length)];

        return {
            texto: `${emo()} *NUEVO LANZAMIENTO 2026* ${emo()}\n\n📢 *Artista/Disco:* ${tituloLimpio}${listaTracks}\n\n🔗 *Escuchar:* ${youtube}`,
            titulo: tituloLimpio
        };
    } catch (e) {
        return null;
    }
}

// --- FUNCIÓN DE ENVÍO CENTRALIZADA ---
async function ejecutarEnvio(idCanal, urlPrincipal) {
    console.log("🔍 Buscando novedades 2026...");
    
    // Intento 1: URL Principal (con disfraz)
    let noticia = await extraerNoticia(urlPrincipal);
    
    // Intento 2: Respaldo Automático (Metal-Tracker 2026)
    if (!noticia) {
        console.log("⚠️ Opción 1 bloqueada o sin cambios. Intentando Respaldo...");
        noticia = await extraerNoticia("https://metal-tracker.com/torrents/search.html?year=2026");
    }

    if (noticia) {
        console.log("📤 Enviando noticia nueva...");
        await sock.sendMessage(idCanal, { text: noticia.texto });
        guardarEnviado(noticia.titulo);
    } else {
        console.log("ℹ️ No hay noticias nuevas para enviar en este momento.");
    }
}

async function iniciarConexion() {
    const { state, saveCreds } = await useMultiFileAuthState('sesion_bot');
    const { version } = await fetchLatestBaileysVersion();

    sock = makeWASocket({
        version,
        logger: pino({ level: "silent" }),
        printQRInTerminal: false,
        auth: state,
        browser: ["Ubuntu", "Chrome", "20.0.04"],
        connectTimeoutMs: 60000,
        keepAliveIntervalMs: 10000
    });

    sock.ev.on("connection.update", async (update) => {
        const { connection, lastDisconnect } = update;

        if (connection === "close") {
            const statusCode = lastDisconnect?.error?.output?.statusCode;
            if (sock.authState.creds.registered && statusCode !== DisconnectReason.loggedOut) {
                iniciarConexion();
            }
        } 
        else if (connection === "open") {
            console.log("\n✅ ¡CONEXIÓN EXITOSA! WhatsApp vinculado.");
            
            let config = obtenerConfig();
            
            // Configuración de ID de Canal
            if (!config?.idCanal) {
                console.log("\n📍 CONFIGURACIÓN PENDIENTE");
                const id = await question("👉 Pega el ID del Canal detectado (@newsletter): ");
                if (id.trim().includes("@newsletter")) {
                    guardarConfig({ idCanal: id.trim() });
                    config = obtenerConfig();
                    console.log("✅ ID Guardado.");
                }
            }

            // Configuración de URL con Tag 2026
            if (!config?.urlInicial) {
                const url = await question("👉 Pega la URL inicial con el Tag 2026: ");
                if (url.trim()) {
                    guardarConfig({ urlInicial: url.trim() });
                    config = obtenerConfig();
                    console.log("✅ URL Guardada.");
                }
            }

            console.log("📌 Sistema activo monitoreando: " + config?.idCanal);

            // --- SINCRONIZACIÓN: PRIMER ENVÍO INMEDIATO ---
            if (config?.idCanal && config?.urlInicial) {
                console.log("🚀 Ejecutando envío inicial de prueba...");
                await ejecutarEnvio(config.idCanal, config.urlInicial);
            }

            // --- PROGRAMACIÓN: HORARIOS ESPECÍFICOS (10 AM, 3 PM, 9 PM) ---
            cron.schedule('0 10,15,21 * * *', async () => {
                if (config?.idCanal && config?.urlInicial) {
                    console.log("⏰ Horario programado alcanzado. Revisando noticias...");
                    await ejecutarEnvio(config.idCanal, config.urlInicial);
                }
            }, { timezone: "America/Mexico_City" });
        }
    });

    sock.ev.on("messages.upsert", async (m) => {
        const msg = m.messages[0];
        if (!msg.message) return;
        if (msg.key.remoteJid.includes("@newsletter")) {
            console.log("\n📢 ID DEL CANAL DETECTADO: " + msg.key.remoteJid);
        }
    });

    if (!sock.authState.creds.registered) {
        console.log("\n⏳ Sincronizando con los servidores de WhatsApp...");
        await delay(8000); 

        console.log("\n------------------------------------------------");
        console.log("📱 CONFIGURACIÓN DE EMPAREJAMIENTO");
        console.log("------------------------------------------------");
        
        const numero = await question("👉 Introduce tu número de WhatsApp (ej: 521XXXXXXXXXX): ");
        if (numero.trim()) {
            try {
                await delay(2000);
                const codigo = await sock.requestPairingCode(numero.trim());
                console.log(`\n🔑 TU CÓDIGO DE VINCULACIÓN ES: ${codigo}`);
                console.log("Introduce este código en la notificación de tu teléfono.");
                console.log("------------------------------------------------\n");
            } catch (error) {
                console.log("\n❌ Error al generar el código.");
            }
        }
    }

    sock.ev.on("creds.update", saveCreds);
}

iniciarConexion();
EOF

# Ejecución
node index.js
