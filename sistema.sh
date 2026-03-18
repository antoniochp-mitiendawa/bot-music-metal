#!/data/data/com.termux/files/usr/bin/bash

# --- CHECKPOINTS (PROHIBIDO MODIFICAR 1 Y 2) ---
PASO1_BASE=".sistema_base_ok"
PASO2_MOTOR=".motor_ia_ok"

echo "🤖 [SISTEMA] Iniciando Secuencia Automatizada de Noticias..."

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
# PASO 2: MOTOR DE EJECUCIÓN Y LIBRERÍAS DE NOTICIAS
# ==========================================
if [ -f "$PASO2_MOTOR" ]; then
    echo "✅ [MEMORIA] Paso 2 (Motores e IA) ya está listo."
else
    echo "⚙️  [PASO 2] Instalando Node.js, Python, FFmpeg y Librerías de Scraper..."
    # Añadimos libsqlite para la base de datos de historial
    pkg install -y nodejs-lts python ffmpeg libsqlite
    
    # Creamos directorios necesarios para el proyecto
    mkdir -p datos_ia
    mkdir -p sesion_bot

    # Instalación de librerías esenciales para Baileys y el futuro Noticiero
    echo "📦 Instalando módulos de Node.js..."
    npm install @whiskeysockets/baileys pino qrcode-terminal readline axios cheerio node-cron

    touch "$PASO2_MOTOR"
    echo "✅ PASO 2 COMPLETADO."
fi

# ==========================================
# PASO 3: LÓGICA DE CONEXIÓN PERMANENTE
# ==========================================
echo "📡 Iniciando Motor de Conexión de WhatsApp..."

cat <<EOF > index.js
const { 
    default: makeWASocket, 
    useMultiFileAuthState, 
    delay, 
    makeCacheableSignalKeyStore 
} = require("@whiskeysockets/baileys");
const pino = require("pino");
const readline = require("readline");

const rl = readline.createInterface({ input: process.stdin, output: process.stdout });
const question = (text) => new Promise((resolve) => rl.question(text, resolve));

async function iniciarConexion() {
    const { state, saveCreds } = await useMultiFileAuthState("sesion_bot");

    const sock = makeWASocket({
        auth: state,
        printQRInTerminal: false, // Forzamos código de emparejamiento
        logger: pino({ level: "silent" }),
        browser: ["Ubuntu", "Chrome", "20.0.0"]
    });

    sock.ev.on("connection.update", async (update) => {
        const { connection, lastDisconnect } = update;

        if (connection === "close") {
            const debeReiniciar = lastDisconnect?.error?.output?.statusCode !== 401;
            console.log("⚠️ Conexión cerrada. Motivo:", lastDisconnect?.error?.message);
            if (debeReiniciar) {
                console.log("🔄 Reiniciando conexión automáticamente...");
                iniciarConexion();
            }
        } else if (connection === "open") {
            console.log("\n✅ ¡CONEXIÓN EXITOSA! El Noticiero está activo.");
            console.log("📌 El bot permanecerá encendido esperando tareas programadas.");
            // ELIMINADO: process.exit(0) para mantener la conexión viva.
        }
    });

    // Proceso de solicitud de código de emparejamiento (Solo si no está registrado)
    if (!sock.authState.creds.registered) {
        console.log("\n⏳ Sincronizando con los servidores de WhatsApp...");
        await delay(6000); 

        console.log("\n------------------------------------------------");
        console.log("📱 CONFIGURACIÓN DE EMPAREJAMIENTO");
        console.log("------------------------------------------------");
        const numero = await question("👉 Introduce tu número de WhatsApp (ej: 521XXXXXXXXXX): ");
        
        try {
            const codigo = await sock.requestPairingCode(numero.trim());
            console.log(\`\\n🔑 TU CÓDIGO DE VINCULACIÓN ES: \${codigo}\`);
            console.log("Introduce este código en la notificación de tu teléfono.");
            console.log("------------------------------------------------\\n");
        } catch (error) {
            console.log("\n❌ Error al generar el código. Reiniciando...");
            process.exit(1);
        }
    }

    sock.ev.on("creds.update", saveCreds);
}

iniciarConexion();
EOF

# Ejecución del bot
node index.js
