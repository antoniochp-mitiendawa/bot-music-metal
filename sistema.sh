#!/data/data/com.termux/files/usr/bin/bash

# --- CHECKPOINTS (PROHIBIDO MODIFICAR 1 Y 2 - BLINDADO) ---
PASO1_BASE=".sistema_base_ok"
PASO2_MOTOR=".motor_ia_ok"

echo "🤖 [SISTEMA] Cargando Motor de Noticias Blindado..."

# ==========================================
# PASO 1: CIMENTACIÓN (BLINDADO)
# ==========================================
if [ -f "$PASO1_BASE" ]; then
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
if [ -f "$PASO2_MOTOR" ]; then
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

const rl = readline.createInterface({ input: process.stdin, output: process.stdout });
const question = (text) => new Promise((resolve) => rl.question(text, resolve));

let sock;
let ultimaNoticia = ""; // Memoria temporal para evitar duplicados en la sesión

// --- FUNCIÓN DE EXTRACCIÓN Y LIMPIEZA DE NOTICIAS ---
async function obtenerNoticiaMusica() {
    try {
        const { data } = await axios.get("https://getmetal.club/");
        const $ = cheerio.load(data);
        
        // Tomar el primer post de la página
        const post = $("article").first();
        let tituloRaw = post.find("h2.entry-title").text().trim();
        
        // LIMPIEZA: Eliminar basura técnica (320 kbps, RAR, etc.)
        let tituloLimpio = tituloRaw
            .replace(/\[.*?\]/g, "")
            .replace(/\(.*?\)/g, "")
            .replace(/320\s?kbps/gi, "")
            .replace(/\.rar/gi, "")
            .trim();

        if (tituloLimpio === ultimaNoticia) return null;
        ultimaNoticia = tituloLimpio;

        // Búsqueda de Video (Simulación de enlace para generar preview)
        const queryYouTube = tituloLimpio.replace(/\s+/g, "+");
        const enlaceYouTube = `https://www.youtube.com/results?search_query=${queryYouTube}`;

        return `🎸 *NUEVO LANZAMIENTO* 🎸\n\n📢 *Disco:* ${tituloLimpio}\n\n🔗 *Escuchar/Video:* ${enlaceYouTube}`;
    } catch (e) {
        console.log("❌ Error al extraer noticias.");
        return null;
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
        } else if (connection === "open") {
            console.log("\n✅ ¡CONEXIÓN EXITOSA! WhatsApp vinculado.");
            console.log("📌 El sistema de noticias está activo y monitoreando.");
            
            // PROGRAMACIÓN: Revisar noticias cada 3 horas (Ejemplo automático)
            cron.schedule('0 */3 * * *', async () => {
                const mensaje = await obtenerNoticiaMusica();
                if (mensaje) {
                    console.log("📤 Enviando noticia nueva...");
                    // Aquí se enviaría al ID del canal cuando lo tengamos definido
                }
            });
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
