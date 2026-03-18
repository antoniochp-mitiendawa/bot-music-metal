#!/data/data/com.termux/files/usr/bin/bash

# --- CHECKPOINTS (PROHIBIDO MODIFICAR 1 Y 2) ---
PASO1_BASE=".sistema_base_ok"
PASO2_MOTOR=".motor_ia_ok"

echo "🤖 [SISTEMA] Iniciando Secuencia Automatizada de Noticias..."

# ==========================================
# PASO 1: CIMENTACIÓN (BLINDADO)
# ==========================================
if [ -f "$PASO1_BASE" ];
then
    echo "✅ [MEMORIA] Paso 1 (Sistema Base) ya está listo."
else
    echo "🚀 [PASO 1] Ejecutando Instalación Base..."
    pkg update -y -o Dpkg::Options::="--force-confold"
    pkg upgrade -y -o Dpkg::Options::="--force-confold"
    pkg install -y git openssl wget
    touch "$PASO1_BASE"
    echo "✅ PASO 1 COMPLETADO."
fi

# ==========================================
# PASO 2: MOTOR DE EJECUCIÓN (NOTICIERO READY)
# ==========================================
if [ -f "$PASO2_MOTOR" ];
then
    echo "✅ [MEMORIA] Paso 2 (Motores e IA) ya está listo."
else
    echo "⚙️  [PASO 2] Instalando Node.js, Python, FFmpeg y Bases de Datos..."
    pkg install -y nodejs-lts python ffmpeg libsqlite
    mkdir -p datos_ia
    mkdir -p sesion_bot
    touch "$PASO2_MOTOR"
    echo "✅ PASO 2 COMPLETADO."
fi

# ==========================================
# PASO 3: CONEXIÓN Y PERMANENCIA (BAILEYS)
# ==========================================
echo "🔗 [PASO 3] Iniciando Motor de Vinculación..."

# Instalación de dependencias originales + herramientas de noticias solicitadas
npm install @whiskeysockets/baileys pino readline axios cheerio node-cron

cat << 'EOF' > index.js
const { default: makeWASocket, useMultiFileAuthState, delay, fetchLatestBaileysVersion, DisconnectReason } = require("@whiskeysockets/baileys");
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
            // Solo reinicia automáticamente si ya hay una sesión registrada
            // Esto evita que el bucle de reinicio cierre el readline durante el emparejamiento
            if (sock.authState.creds.registered && statusCode !== DisconnectReason.loggedOut) {
                iniciarConexion();
            }
        } else if (connection === "open") {
            console.log("\n✅ ¡CONEXIÓN EXITOSA! WhatsApp vinculado.");
            console.log("📌 El sistema permanece activo para el noticiero musical.");
            // Eliminado process.exit(0) para mantener la sesión abierta
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
                console.log("\n❌ Error al generar el código. Reinicia el script e intenta de nuevo.");
            }
        }
    }

    sock.ev.on("creds.update", saveCreds);
}

iniciarConexion();
EOF

# Ejecución del proceso
node index.js
