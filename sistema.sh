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

// --- FUNCIONES DE PERSISTENCIA DE DATOS ---
function cargarEnviados() {
    if (!fs.existsSync(DB_PATH)) return [];
    try { return JSON.parse(fs.readFileSync(DB_PATH)); } catch { return []; }
}

function guardarEnviado(titulo) {
    const enviados = cargarEnviados();
    enviados.push(titulo);
    if (enviados.length > 50) enviados.shift();
    fs.writeFileSync(DB_PATH, JSON.stringify(enviados));
}

function obtenerConfig() {
    if (!fs.existsSync(CONFIG_PATH)) return null;
    try { return JSON.parse(fs.readFileSync(CONFIG_PATH)); } catch { return null; }
}

function guardarConfig(idCanal) {
    fs.writeFileSync(CONFIG_PATH, JSON.stringify({ idCanal }));
}

// --- FUNCIÓN DE EXTRACCIÓN Y LIMPIEZA DE NOTICIAS ---
async function obtenerNoticiaMusica() {
    try {
        const { data } = await axios.get("https://getmetal.club/");
        const $ = cheerio.load(data);
        
        const post = $("article").first();
        let tituloRaw = post.find("h2.entry-title").text().trim();
        
        let tituloLimpio = tituloRaw
            .replace(/\[.*?\]/g, "")
            .replace(/\(.*?\)/g, "")
            .replace(/320\s?kbps/gi, "")
            .replace(/\.rar/gi, "")
            .trim();

        const enviados = cargarEnviados();
        if (enviados.includes(tituloLimpio)) return null;

        const queryYouTube = tituloLimpio.replace(/\s+/g, "+");
        const enlaceYouTube = `https://www.youtube.com/results?search_query=${queryYouTube}`;

        return {
            texto: `🎸 *NUEVO LANZAMIENTO* 🎸\n\n📢 *Disco:* ${tituloLimpio}\n\n🔗 *Escuchar/Video:* ${enlaceYouTube}`,
            titulo: tituloLimpio
        };
    } catch (e) {
        console.log("❌ Error al extraer noticias.");
        return null;
    }
}

// --- FUNCIÓN DE ENVÍO CENTRALIZADA ---
async function ejecutarEnvio(idCanal) {
    const noticia = await obtenerNoticiaMusica();
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
            if (!config) {
                console.log("\n📍 CONFIGURACIÓN PENDIENTE");
                const id = await question("👉 Pega el ID del Canal detectado (@newsletter): ");
                if (id.trim().includes("@newsletter")) {
                    guardarConfig(id.trim());
                    config = { idCanal: id.trim() };
                    console.log("✅ ID Guardado permanentemente.");
                }
            }

            console.log("📌 El sistema de noticias está activo y monitoreando.");
            console.log(`📌 Canal destino: ${config?.idCanal}`);

            // --- SINCRONIZACIÓN: PRIMER ENVÍO INMEDIATO ---
            if (config) {
                console.log("🚀 Ejecutando envío inicial de prueba...");
                await ejecutarEnvio(config.idCanal);
            }

            // --- PROGRAMACIÓN: HORARIOS ESPECÍFICOS (10 AM, 3 PM, 9 PM) ---
            cron.schedule('0 10,15,21 * * *', async () => {
                if (config) {
                    console.log("⏰ Horario programado alcanzado. Revisando noticias...");
                    await ejecutarEnvio(config.idCanal);
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
