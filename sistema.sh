#!/data/data/com.termux/files/usr/bin/bash

# --- CHECKPOINTS (PROHIBIDO MODIFICAR) ---
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

# 2. Creación del archivo index.js con tiempo de espera para evitar error 428
cat << 'EOF' > index.js
const { default: makeWASocket, useMultiFileAuthState, delay } = require("@whiskeysockets/baileys");
const pino = require("pino");
const readline = require("readline");

const rl = readline.createInterface({ input: process.stdin, output: process.stdout });
const question = (text) => new Promise((resolve) => rl.question(text, resolve));

async function iniciarConexion() {
    const { state, saveCreds } = await useMultiFileAuthState('sesion_bot');
    
    const sock = makeWASocket({
        logger: pino({ level: "silent" }),
        printQRInTerminal: false,
        auth: state,
        browser: ["Ubuntu", "Chrome", "20.0.04"]
    });

    if (!sock.authState.creds.registered) {
        // Pausa de 5 segundos para asegurar que el socket esté abierto antes de pedir el número
        console.log("\n⏳ Estabilizando conexión con WhatsApp...");
        await delay(5000); 

        console.log("\n------------------------------------------------");
        console.log("📱 CONFIGURACIÓN DE EMPAREJAMIENTO");
        console.log("------------------------------------------------");
        const numero = await question("👉 Introduce tu número de WhatsApp (ej: 521XXXXXXXXXX): ");
        
        try {
            const codigo = await sock.requestPairingCode(numero.trim());
            console.log(`\n🔑 TU CÓDIGO DE VINCULACIÓN ES: ${codigo}`);
            console.log("Introduce este código en la notificación de tu teléfono.");
            console.log("------------------------------------------------\n");
        } catch (error) {
            console.log("\n❌ Error de conexión. Reintentando en 3 segundos...");
            await delay(3000);
            process.exit(1);
        }
    }

    sock.ev.on("creds.update", saveCreds);
    sock.ev.on("connection.update", (update) => {
        const { connection } = update;
        if (connection === "open") {
            console.log("✅ ¡CONEXIÓN EXITOSA! WhatsApp vinculado.");
            process.exit(0);
        }
    });
}
iniciarConexion();
EOF

# 3. Ejecución del proceso
node index.js
