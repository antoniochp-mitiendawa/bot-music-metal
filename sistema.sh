#!/data/data/com.termux/files/usr/bin/bash

# --- CHECKPOINTS ---
PASO1_BASE=".sistema_base_ok"
PASO2_MOTOR=".motor_ia_ok"

echo "🤖 [SISTEMA] Iniciando Secuencia de Instalación..."

# ==========================================
# PASO 1: CIMENTACIÓN
# ==========================================
if [ -f "$PASO1_BASE" ]; then
    echo "✅ [MEMORIA] Paso 1 listo."
else
    echo "🚀 [PASO 1] Actualizando sistema..."
    pkg update -y -o Dpkg::Options::="--force-confold"
    pkg upgrade -y -o Dpkg::Options::="--force-confold"
    pkg install -y git openssl wget
    touch "$PASO1_BASE"
fi

# ==========================================
# PASO 2: MOTOR DE EJECUCIÓN
# ==========================================
if [ -f "$PASO2_MOTOR" ]; then
    echo "✅ [MEMORIA] Paso 2 listo."
else
    echo "⚙️ [PASO 2] Instalando Node.js y librerías..."
    pkg install -y nodejs-lts python ffmpeg libsqlite
    
    mkdir -p datos_ia
    mkdir -p sesion_bot

    npm install @whiskeysockets/baileys pino axios cheerio node-cron
    touch "$PASO2_MOTOR"
fi

# ==========================================
# PASO 3: LÓGICA DE CONEXIÓN (ORIGINAL)
# ==========================================
echo "📡 Iniciando vinculación..."

cat <<EOF > index.js
const { 
    default: makeWASocket, 
    useMultiFileAuthState, 
    delay 
} = require("@whiskeysockets/baileys");
const pino = require("pino");
const readline = require("readline");

const rl = readline.createInterface({ input: process.stdin, output: process.stdout });
const question = (text) => new Promise((resolve) => rl.question(text, resolve));

async function iniciarConexion() {
    const { state, saveCreds } = await useMultiFileAuthState("sesion_bot");

    const sock = makeWASocket({
        auth: state,
        printQRInTerminal: false,
        logger: pino({ level: "silent" }),
        browser: ["Ubuntu", "Chrome", "20.0.0"]
    });

    sock.ev.on("connection.update", async (update) => {
        const { connection, lastDisconnect } = update;

        if (connection === "close") {
            const debeReiniciar = lastDisconnect?.error?.output?.statusCode !== 401;
            if (debeReiniciar) {
                iniciarConexion();
            }
        } else if (connection === "open") {
            console.log("\n✅ ¡CONEXIÓN EXITOSA!");
            console.log("📌 El sistema permanece activo.");
            // process.exit(0) ELIMINADO para mantener la permanencia.
        }
    });

    if (!sock.authState.creds.registered) {
        await delay(6000); 

        console.log("\n------------------------------------------------");
        console.log("📱 CONFIGURACIÓN DE EMPAREJAMIENTO");
        console.log("------------------------------------------------");
        const numero = await question("👉 Introduce tu número de WhatsApp (ej: 521XXXXXXXXXX): ");
        
        try {
            const codigo = await sock.requestPairingCode(numero.trim());
            console.log(\`\\n🔑 TU CÓDIGO DE VINCULACIÓN ES: \${codigo}\`);
            console.log("------------------------------------------------\\n");
        } catch (error) {
            console.log("❌ Error al generar código.");
        }
    }

    sock.ev.on("creds.update", saveCreds);
}

iniciarConexion();
EOF

# Ejecución
node index.js
