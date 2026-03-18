#!/data/data/com.termux/files/usr/bin/bash

# Activar persistencia para que Termux no se cierre en segundo plano
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
    echo "✅ [MEMORIA] Paso 1 listo." [cite: 2]
else
    pkg update -y -o Dpkg::Options::="--force-confold" [cite: 3]
    pkg upgrade -y -o Dpkg::Options::="--force-confold" [cite: 3]
    pkg install -y git openssl wget [cite: 3]
    touch "$PASO1_BASE" [cite: 3]
fi

# ==========================================
# PASO 2: MOTOR DE EJECUCIÓN (BLINDADO)
# ==========================================
if [ -f "$PASO2_MOTOR" ];
then
    echo "✅ [MEMORIA] Paso 2 listo." [cite: 4]
else
    pkg install -y nodejs-lts python ffmpeg libsqlite [cite: 5]
    mkdir -p datos_ia [cite: 5]
    mkdir -p sesion_bot [cite: 5]
    npm install @whiskeysockets/baileys pino readline axios cheerio node-cron [cite: 5]
    touch "$PASO2_MOTOR" [cite: 5]
fi

# ==========================================
# PASO 3: INDEX.JS (SISTEMA MULTIFUENTE 2026)
# ==========================================
cat << 'EOF' > index.js
const { 
    default: makeWASocket, 
    useMultiFileAuthState, 
    delay, 
    fetchLatestBaileysVersion, 
    DisconnectReason 
} = require("@whiskeysockets/baileys"); [cite: 5]
const pino = require("pino"); [cite: 6]
const readline = require("readline"); [cite: 6]
const axios = require("axios"); [cite: 6]
const cheerio = require("cheerio"); [cite: 6]
const cron = require("node-cron"); [cite: 6]
const fs = require("fs");

const rl = readline.createInterface({ input: process.stdin, output: process.stdout }); [cite: 7]
const question = (text) => new Promise((resolve) => rl.question(text, resolve)); [cite: 7]

let sock;
const DB_PATH = "./datos_ia/enviados.json";
const CONFIG_PATH = "./datos_ia/config.json";

// --- CONFIGURACIÓN DE DISFRAZ (ANTI-CLOUDFLARE) ---
const DISFRAZ = {
    'User-Agent': 'Mozilla/5.0 (Linux; Android 14; Pixel 8 Build/UD1A.230805.019) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/122.0.6261.64 Mobile Safari/537.36',
    'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,*/*;q=0.8',
    'Accept-Language': 'es-ES,es;q=0.9,en;q=0.8',
    'Referer': 'https://www.google.com/'
};

// --- GESTIÓN DE MEMORIA ---
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
async function extraerDePagina(url) {
    try {
        const { data } = await axios.get(url, { headers: DISFRAZ, timeout: 15000 });
        const $ = cheerio.load(data);
        const post = $("article").first();
        
        let tituloRaw = post.find("h2.entry-title, .post-title, h2").first().text().trim();
        let tituloLimpio = tituloRaw.replace(/\[.*?\]|\(.*?\)|320\s?kbps|\.rar/gi, "").trim();

        if (!tituloLimpio) return null;

        const enviados = cargarEnviados();
        if (enviados.includes(tituloLimpio)) return null;

        // Extraer Tracks (Simulado si no hay tabla interna)
        let tracks = post.find(".tracklist, .songs, ul li").map((i, el) => $(el).text().trim()).get().slice(0, 10);
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

async function ejecutarSistemaNoticias(idCanal, urlPrincipal) {
    console.log("🔍 Buscando novedades 2026...");
    
    // Intento 1: URL Principal (con disfraz)
    let noticia = await extraerDePagina(urlPrincipal);
    
    // Intento 2: Metal-Tracker (Respaldo)
    if (!noticia) {
        console.log("⚠️ Opción 1 bloqueada o sin cambios. Intentando Respaldo...");
        noticia = await extraerDePagina("https://metal-tracker.com/torrents/search.html?year=2026");
    }

    if (noticia) {
        console.log("📤 Enviando noticia fresca al canal...");
        await sock.sendMessage(idCanal, { text: noticia.texto, linkPreview: true });
        guardarEnviado(noticia.titulo);
    } else {
        console.log("ℹ️ No hay lanzamientos nuevos detectados en este ciclo.");
    }
}

async function iniciarConexion() {
    const { state, saveCreds } = await useMultiFileAuthState('sesion_bot'); [cite: 14]
    const { version } = await fetchLatestBaileysVersion(); [cite: 15]

    sock = makeWASocket({
        version,
        logger: pino({ level: "silent" }), [cite: 15]
        printQRInTerminal: false, [cite: 15]
        auth: state, [cite: 15]
        browser: ["Ubuntu", "Chrome", "20.0.04"], [cite: 15]
        connectTimeoutMs: 60000,
        keepAliveIntervalMs: 10000
    }); [cite: 15]

    sock.ev.on("connection.update", async (update) => {
        const { connection, lastDisconnect } = update; [cite: 16]

        if (connection === "close") { [cite: 16]
            const statusCode = lastDisconnect?.error?.output?.statusCode;
            if (sock.authState.creds.registered && statusCode !== DisconnectReason.loggedOut) {
                iniciarConexion(); [cite: 16]
            }
        } 
        else if (connection === "open") { 
            console.log("\n✅ ¡CONEXIÓN EXITOSA! WhatsApp vinculado."); 
            
            let config = obtenerConfig();
            
            if (!config?.idCanal) {
                const id = await question("👉 Pega el ID del Canal (@newsletter): ");
                guardarConfig({ idCanal: id.trim() });
                config = obtenerConfig();
            }

            if (!config?.urlInicial) {
                const url = await question("👉 Pega la URL inicial con el Tag 2026: ");
                guardarConfig({ urlInicial: url.trim() });
                config = obtenerConfig();
            }

            console.log("📌 Monitoreo activo para: " + config.idCanal);
            
            // Envío inicial de prueba
            await ejecutarSistemaNoticias(config.idCanal, config.urlInicial);

            // Programación: 10:00, 15:00 y 21:00
            cron.schedule('0 10,15,21 * * *', async () => {
                await ejecutarSistemaNoticias(config.idCanal, config.urlInicial);
            }, { timezone: "America/Mexico_City" });
        }
    });

    sock.ev.on("messages.upsert", async (m) => { [cite: 20]
        const msg = m.messages[0];
        if (!msg.message) return;
        if (msg.key.remoteJid.includes("@newsletter")) { [cite: 20]
            console.log("\n📢 ID DETECTADO: " + msg.key.remoteJid); [cite: 20]
        }
    });

    if (!sock.authState.creds.registered) { [cite: 21]
        console.log("\n⏳ Sincronizando con los servidores de WhatsApp..."); [cite: 21]
        await delay(8000); 

        console.log("\n------------------------------------------------"); 
        console.log("📱 CONFIGURACIÓN DE EMPAREJAMIENTO"); 
        console.log("------------------------------------------------"); 
        
        const numero = await question("👉 Introduce tu número de WhatsApp: "); 
        if (numero.trim()) {
            try {
                await delay(2000);
                const codigo = await sock.requestPairingCode(numero.trim()); [cite: 24]
                console.log(`\n🔑 TU CÓDIGO DE VINCULACIÓN ES: ${codigo}`); [cite: 24]
                console.log("Introduce este código en la notificación de tu teléfono."); [cite: 25]
            } catch (error) {
                console.log("\n❌ Error al generar el código."); [cite: 26]
            }
        }
    }
    sock.ev.on("creds.update", saveCreds);
}

iniciarConexion();
EOF

# Ejecución
node index.js
