#!/data/data/com.termux/files/usr/bin/bash

# --- CHECKPOINTS (PROHIBIDO MODIFICAR 1 Y 2) ---
PASO1_BASE=".sistema_base_ok"
PASO2_MOTOR=".motor_ia_ok"

echo "🤖 [SISTEMA] Iniciando Secuencia Automatizada..."

# ==========================================
# PASO 1: CIMENTACIÓN (BLINDADO)
# ==========================================
if [ -f "$PASO1_BASE" ]; then
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
# PASO 2: MOTOR DE EJECUCIÓN (BLINDADO)
# ==========================================
if [ -f "$PASO2_MOTOR" ]; then
    echo "✅ [MEMORIA] Paso 2 (Motores e IA) ya está listo."
else
    echo "⚙️  [PASO 2] Instalando Node.js, Python y FFmpeg..."
    pkg install -y nodejs-lts python ffmpeg libsqlite
    mkdir -p datos_ia
    touch "$PASO2_MOTOR"
    echo "✅ PASO 2 COMPLETADO."
fi

# ==========================================
# PASO 3: CONEXIÓN Y EMPAREJAMIENTO (BAILEYS)
# ==========================================
echo "🔗 [PASO 3] Iniciando Motor de Vinculación..."

# 1. Asegurar dependencias de red
npm install @whiskeysockets/baileys pino readline

# 2. Creación del archivo index.js (Lógica de Emparejamiento Real)
cat << 'EOF' > index.js
const { default: makeWASocket, useMultiFileAuthState, delay, fetchLatestBaileysVersion } = require("@whiskeysockets/baileys");
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
        // Identidad del navegador para evitar rechazos del servidor
        browser: ["Ubuntu", "Chrome", "20.0.04"]
    });

    // Manejo de eventos de conexión
    sock.ev.on("connection.update", async (update) => {
        const { connection, lastDisconnect } = update;

        if (connection === "close") {
            // Si la conexión se cierra, reinicia automáticamente para no perder el proceso
            iniciarConexion();
        } else if (connection === "open") {
            console.log("\n✅ ¡CONEXIÓN EXITOSA! WhatsApp vinculado.");
            process.exit(0);
        }
    });

    // Proceso de solicitud de código de emparejamiento
    if (!sock.authState.creds.registered) {
        console.log("\n⏳ Sincronizando con los servidores de WhatsApp...");
        await delay(6000); // Tiempo extra para estabilizar el socket en Termux

        console.log("\n------------------------------------------------");
        console.log("📱 CONFIGURACIÓN DE EMPAREJAMIENTO");
        console.log("------------------------------------------------");
        const numero = await question("👉 Introduce tu número de WhatsApp (ej: 521XXXXXXXXXX): ");
        
        try {
            // Solicitar código con el número limpio
            const codigo = await sock.requestPairingCode(numero.trim());
            console.log(`\n🔑 TU CÓDIGO DE VINCULACIÓN ES: ${codigo}`);
            console.log("Introduce este código en la notificación de tu teléfono.");
            console.log("------------------------------------------------\n");
        } catch (error) {
            console.log("\n❌ Error al generar el código. Reiniciando proceso...");
            process.exit(1);
        }
    }

    sock.ev.on("creds.update", saveCreds);
}

iniciarConexion();
EOF

# 3. Ejecución del proceso
node index.js
