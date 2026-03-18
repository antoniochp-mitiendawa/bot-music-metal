#!/data/data/com.termux/files/usr/bin/bash

# --- CHECKPOINTS (PROHIBIDO MODIFICAR 1 Y 2 - BLINDADO) ---
PASO1_BASE=".sistema_base_ok"
PASO2_MOTOR=".motor_ia_ok"

echo "🤖 [SISTEMA] Cargando Rastreador de ID de Canal (Blindado)..."

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
# PASO 3: INDEX.JS (CONECTOR + RASTREADOR DE ID)
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

const rl = readline.createInterface({ input: process.stdin, output: process.stdout });
const question = (text) => new Promise((resolve) => rl.question(text, resolve));

async function iniciarConexion() {
    const { state, saveCreds } = await useMultiFileAuthState('sesion_bot');
    const { version } = await fetchLatestBaileysVersion();

    const sock = makeWASocket({
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
            console.log("\n✅ ¡CONEXIÓN EXITOSA!");
            console.log("------------------------------------------------");
            console.log("🔎 BUSCADOR DE ID ACTIVO");
            console.log("INSTRUCCIONES:");
            console.log("1. Ve a tu canal de WhatsApp.");
            console.log("2. Envía cualquier mensaje (ej: 'Hola').");
            console.log("3. El ID aparecerá aquí abajo.");
            console.log("------------------------------------------------\n");
        }
    });

    // --- ESCUCHA DE EVENTOS PARA CAPTURAR EL ID DEL CANAL ---
    sock.ev.on("messages.upsert", async (m) => {
        const msg = m.messages[0];
        if (!msg.message) return;

        // Detectar si el mensaje viene de un canal (newsletter)
        if (msg.key.remoteJid.endsWith("@newsletter")) {
            console.log("🆔 ¡ID DETECTADO!");
            console.log(`📌 ID del Canal: ${msg.key.remoteJid}`);
            console.log(`📝 Contenido: ${msg.message.conversation || "Mensaje multimedia"}`);
            console.log("------------------------------------------------");
        }
    });

    if (!sock.authState.creds.registered) {
        console.log("\n⏳ Sincronizando...");
        await delay(8000); 
        const numero = await question("👉 Introduce tu número de WhatsApp: ");
        if (numero.trim()) {
            try {
                await delay(2000);
                const codigo = await sock.requestPairingCode(numero.trim());
                console.log(`\n🔑 TU CÓDIGO ES: ${codigo}\n`);
            } catch (error) {
                console.log("\n❌ Error al generar el código.");
            }
        }
    }

    sock.ev.on("creds.update", saveCreds);
}

iniciarConexion();
EOF

node index.js
