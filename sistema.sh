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
# PASO 3 Y 4: VINCULACIÓN Y PERSISTENCIA
# ==========================================
echo "🔗 [SISTEMA] Iniciando Motor de Conexión Permanente..."

# 1. Asegurar dependencias de red
npm install @whiskeysockets/baileys pino readline

# 2. Creación del archivo index.js (Lógica de Persistencia)
cat << 'EOF' > index.js
const { default: makeWASocket, useMultiFileAuthState, delay, fetchLatestBaileysVersion, DisconnectReason } = require("@whiskeysockets/baileys");
const pino = require("pino");
const readline = require("readline");

const rl = readline.createInterface({ input: process.stdin, output: process.stdout });
const question = (text) => new Promise((resolve) => rl.question(text, resolve));

async function iniciarBot() {
    const { state, saveCreds } = await useMultiFileAuthState('sesion_bot');
    const { version } = await fetchLatestBaileysVersion();

    const sock = makeWASocket({
        version,
        logger: pino({ level: "silent" }),
        printQRInTerminal: false,
        auth: state,
        browser: ["Ubuntu", "Chrome", "20.0.04"]
    });

    // ESCUCHA DE EVENTOS DE CONEXIÓN
    sock.ev.on("connection.update", async (update) => {
        const { connection, lastDisconnect } = update;

        if (connection === "close") {
            const debeReconectar = (lastDisconnect?.error?.output?.statusCode !== DisconnectReason.loggedOut);
            console.log("🔄 Conexión perdida. Reconectando:", debeReconectar);
            if (debeReconectar) iniciarBot();
        } else if (connection === "open") {
            console.log("\n✅ [ESTADO] BOT ACTIVO Y VIGENTE.");
            console.log("📱 La sesión está guardada. Ya puedes enviar mensajes.");
        }
    });

    // ESCUCHA DE MENSAJES (PRUEBA DE PERSISTENCIA)
    sock.ev.on("messages.upsert", async (m) => {
        const msg = m.messages[0];
        if (!msg.key.fromMe && m.type === "notify") {
            const texto = msg.message?.conversation || msg.message?.extendedTextMessage?.text;
            
            // Si recibe "test", el bot responde para demostrar que sigue activo
            if (texto?.toLowerCase() === "test") {
                await sock.sendMessage(msg.key.remoteJid, { text: "✅ Bot funcionando en tiempo real." });
            }
        }
    });

    // SOLICITUD DE CÓDIGO (SOLO SI NO ESTÁ VINCULADO)
    if (!sock.authState.creds.registered) {
        console.log("\n⏳ Sincronizando con WhatsApp...");
        await delay(6000); 

        console.log("\n------------------------------------------------");
        console.log("📱 CONFIGURACIÓN DE EMPAREJAMIENTO");
        console.log("------------------------------------------------");
        const numero = await question("👉 Introduce tu número de WhatsApp (ej: 521XXXXXXXXXX): ");
        
        try {
            const codigo = await sock.requestPairingCode(numero.trim());
            console.log(`\n🔑 TU CÓDIGO DE VINCULACIÓN ES: ${codigo}`);
            console.log("Introduce este código en tu teléfono.");
            console.log("------------------------------------------------\n");
        } catch (error) {
            console.log("\n❌ Error. Reiniciando...");
            process.exit(1);
        }
    }

    sock.ev.on("creds.update", saveCreds);
}

iniciarBot();
EOF

# 3. Ejecución del bot
node index.js
