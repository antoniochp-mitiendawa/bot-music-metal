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
# PASO 3: INDEX.JS (MOTOR MULTIFUENTE + LOGS)
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

// --- ESCENARIOS DE IDENTIDAD (ROTACIÓN) ---
const ESCENARIOS = [
    { name: "Android 14 (Pixel 8)", ua: 'Mozilla/5.0 (Linux; Android 14; Pixel 8) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/122.0.0.0 Mobile Safari/537.36' },
    { name: "Windows 11 (Edge)", ua: 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/121.0.0.0 Safari/537.36 Edg/121.0.0.0' },
    { name: "macOS (Safari)", ua: 'Mozilla/5.0 (Macintosh; Intel Mac OS X 14_2_1) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.2 Safari/605.1.15' },
    { name: "Linux (Firefox)", ua: 'Mozilla/5.0 (X11; Linux x86_64; rv:122.0) Gecko/20100101 Firefox/122.0' }
];

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

// --- EXTRACTOR CON LOGS Y ROTACIÓN ---
async function extraerConIdentidad(url) {
    for (const esc of ESCENARIOS) {
        console.log(`📡 Probando escenario: ${esc.name}...`);
        try {
            const { data } = await axios.get(url, { 
                headers: { 'User-Agent': esc.ua, 'Referer': 'https://www.google.com/' }, 
                timeout: 10000 
            });
            const $ = cheerio.load(data);
            const post = $("article, .post, .torrent-box, .entry").first();
            let tituloRaw = post.find("h2, .title, .entry-title").first().text().trim();
            let tituloLimpio = tituloRaw.replace(/\[.*?\]|\(.*?\)|320kbps/gi, "").trim();

            if (tituloLimpio && !cargarEnviados().includes(tituloLimpio)) {
                let tracks = post.find("ul li, .tracklist").map((i, el) => $(el).text().trim()).get().slice(0, 10);
                let lista = tracks.length > 0 ? "\n\n📋 *TRACKLIST:*\n" + tracks.map(t => `🔹 ${t}`).join("\n") : "";
                const yt = `https://www.youtube.com/results?search_query=${tituloLimpio.replace(/\s+/g, "+")}+2026`;
                
                return { 
                    texto: `🎸 *NUEVO LANZAMIENTO 2026* 🤘\n\n📢 *Disco:* ${tituloLimpio}${lista}\n\n🔗 *Escuchar:* ${yt}`, 
                    titulo: tituloLimpio 
                };
            }
        } catch (e) {
            console.log(`⚠️ Escenario ${esc.name} bloqueado o fallido.`);
        }
        await delay(2000);
    }
    return null;
}

async function ejecutarSistema(idCanal, urlPrincipal) {
    console.log("🔍 [LOG] Iniciando búsqueda de noticias...");
    
    const fuentes = [
        { nombre: "Fuente Inicial (Tag 2026)", url: urlPrincipal },
        { nombre: "Metal-Tracker", url: "https://metal-tracker.com/torrents/search.html?year=2026" },
        { nombre: "Metal Kingdom", url: "https://metalkingdom.net/albums/2026" },
        { nombre: "New Album Releases", url: "https://newalbumreleases.net/category/metal/" }
    ];

    for (const f of fuentes) {
        console.log(`🌐 Conectando a: ${f.nombre}...`);
        let noticia = await extraerConIdentidad(f.url);
        if (noticia) {
            console.log(`✅ Noticia encontrada en ${f.nombre}.`);
            await sock.sendMessage(idCanal, { text: noticia.texto });
            guardarEnviado(noticia.titulo);
            return;
        }
        console.log(`❌ Sin novedades en ${f.nombre}.`);
    }

    console.log("ℹ️ Ciclo completado. No se encontraron nuevas noticias.");
}

async function iniciarConexion() {
    const { state, saveCreds } = await useMultiFileAuthState('sesion_bot');
    const { version } = await fetchLatestBaileysVersion();

    sock = makeWASocket({
        version,
        logger: pino({ level: "silent" }),
        printQRInTerminal: false,
        auth: state,
        browser: ["Ubuntu", "Chrome", "20.0.04"]
    });

    sock.ev.on("connection.update", async (update) => {
        const { connection, lastDisconnect } = update;
        if (connection === "close") {
            if (sock.authState.creds.registered && lastDisconnect?.error?.output?.statusCode !== DisconnectReason.loggedOut) {
                iniciarConexion();
            }
        } else if (connection === "open") {
            console.log("\n✅ ¡CONEXIÓN EXITOSA! WhatsApp vinculado.");
            let config = obtenerConfig();

            if (!config?.idCanal) {
                const id = await question("👉 Pega el ID del Canal (@newsletter): ");
                if (id.trim().includes("@newsletter")) {
                    guardarConfig({ idCanal: id.trim() });
                    config = obtenerConfig();
                }
            }
            if (!config?.urlInicial) {
                const url = await question("👉 Pega la URL inicial (Tag 2026): ");
                if (url.trim()) {
                    guardarConfig({ urlInicial: url.trim() });
                    config = obtenerConfig();
                }
            }

            // --- MENSAJE DE VERIFICACIÓN BAILEYS ---
            console.log("🚀 Enviando verificación de conexión...");
            await sock.sendMessage(config.idCanal, { text: "🤖 *Sistema de Noticias en línea*\n\nVerificación de conexión con Baileys: OK.\nBuscando lanzamientos 2026..." });
            
            await ejecutarSistema(config.idCanal, config.urlInicial);

            cron.schedule('0 10,15,21 * * *', async () => {
                await ejecutarSistema(config.idCanal, config.urlInicial);
            }, { timezone: "America/Mexico_City" });
        }
    });

    if (!sock.authState.creds.registered) {
        await delay(5000);
        const numero = await question("👉 Introduce tu número de WhatsApp: ");
        if (numero.trim()) {
            const codigo = await sock.requestPairingCode(numero.trim());
            console.log(`\n🔑 CÓDIGO DE VINCULACIÓN: ${codigo}`);
        }
    }
    sock.ev.on("creds.update", saveCreds);
}
iniciarConexion();
EOF

# Ejecución
node index.js
