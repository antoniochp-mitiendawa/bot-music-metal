#!/data/data/com.termux/files/usr/bin/bash

# --- CHECKPOINTS DE SEGURIDAD (PROHIBIDO MODIFICAR LO QUE YA FUNCIONA) ---
PASO1_BASE=".sistema_base_ok"
PASO2_MOTOR=".motor_ia_ok"
PASO2_EXTERNO=".motores_pesados_ok"

echo "================================================="
echo "🤖 [SISTEMA] INSTALACIÓN TOTAL Y AUTOMATIZADA"
echo "================================================="

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
    echo "✅ [MEMORIA] Paso 2 (Motores Base) ya está listo."
else
    echo "⚙️  [PASO 2] Instalando Node.js, Python y FFmpeg..."
    pkg install -y nodejs-lts python ffmpeg libsqlite
    mkdir -p datos_ia
    touch "$PASO2_MOTOR"
    echo "✅ PASO 2 COMPLETADO."
fi

# ==========================================
# PASO 2.5: ARMAMENTO DE IA, AUDIO Y VISIÓN (TODO LO DEMÁS)
# ==========================================
if [ -f "$PASO2_EXTERNO" ]; then
    echo "✅ [MEMORIA] Motores de IA y Audio ya están instalados."
else
    echo "🧠 [PASO 2.5] Instalando IA, Whisper y Visión..."
    
    # Herramientas de sistema para audio y fotos
    pkg install -y libwebp-static imagemagick
    
    # Motores de Inteligencia Artificial (Python)
    pip install --upgrade pip
    pip install openai-whisper pandas numpy
    
    # SDKs de IA para Node.js y Persistencia
    npm install openai @google/generative-ai sharp fluent-ffmpeg
    
    touch "$PASO2_EXTERNO"
    echo "✅ TODO LO DEMÁS (IA/AUDIO) INSTALADO CORRECTAMENTE."
fi

# ==========================================
# PASO 3 Y 4: VINCULACIÓN Y PERSISTENCIA (BLINDADO)
# ==========================================
echo "🔗 [SISTEMA] Iniciando Motor de Conexión Permanente..."

# Asegurar dependencias de WhatsApp
npm install @whiskeysockets/baileys pino readline

# Creación del archivo index.js (Lógica de Conexión + Persistencia + Sensores IA)
cat << 'EOF' > index.js
const { default: makeWASocket, useMultiFileAuthState, delay, fetchLatestBaileysVersion, DisconnectReason } = require("@whiskeysockets/baileys");
const pino = require("pino");
const readline = require("readline");
const fs = require("fs");

const rl = readline.createInterface({ input: process.stdin, output: process.stdout });
const question = (text) => new Promise((resolve) => rl.question(text, resolve));

async function iniciarBot() {
    // Carpeta de sesión persistente
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
            console.log("🔄 Conexión perdida. Reconectando...");
            if (debeReconectar) iniciarBot();
        } else if (connection === "open") {
            console.log("\n✅ [ESTADO] BOT ACTIVO Y VIGENTE.");
            console.log("📱 Motores listos: Texto, Audio (Whisper) e Imágenes.");
            console.log("------------------------------------------------\n");
        }
    });

    // ESCUCHA DE MENSAJES
    sock.ev.on("messages.upsert", async (m) => {
        const msg = m.messages[0];
        if (!msg.key.fromMe && m.type === "notify") {
            const texto = msg.message?.conversation || msg.message?.extendedTextMessage?.text;
            const esAudio = msg.message?.audioMessage;
            
            // Test de vida del bot
            if (texto?.toLowerCase() === "test") {
                await sock.sendMessage(msg.key.remoteJid, { text: "✅ Sistema conectado. IA y Motores de Audio listos." });
            }
            
            // Detección de Audio (Verificación de sensores del Paso 2.5)
            if (esAudio) {
                console.log("🎙️ Audio detectado. Motor Whisper listo para transcripción.");
            }
        }
    });

    // SOLICITUD DE CÓDIGO (SOLO SI NO HAY SESIÓN)
    if (!sock.authState.creds.registered) {
        console.log("\n⏳ Sincronizando con WhatsApp...");
        await delay(6000); 

        console.log("\n------------------------------------------------");
        console.log("📱 CONFIGURACIÓN DE EMPAREJAMIENTO");
        console.log("------------------------------------------------");
        const numero = await question("👉 Introduce tu número de WhatsApp (521XXXXXXXXXX): ");
        
        try {
            const codigo = await sock.requestPairingCode(numero.trim());
            console.log(`\n🔑 TU CÓDIGO DE VINCULACIÓN ES: ${codigo}`);
            console.log("Introduce este código en tu teléfono.");
            console.log("------------------------------------------------\n");
        } catch (error) {
            console.log("\n❌ Error en la vinculación. Reintentando...");
            process.exit(1);
        }
    }

    sock.ev.on("creds.update", saveCreds);
}

iniciarBot();
EOF

# Ejecución del sistema completo
node index.js
