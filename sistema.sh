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
# PASO 2: MOTOR DE EJECUCIÓN (NOTICIERO READY)
# ==========================================
if [ -f "$PASO2_MOTOR" ]; then
    echo "✅ [MEMORIA] Paso 2 (Motores e IA) ya está listo."
else
    echo "⚙️  [PASO 2] Instalando Node.js, Python, FFmpeg y Bases de Datos..."
    pkg install -y nodejs-lts python ffmpeg libsqlite
    
    mkdir -p datos_ia
    mkdir -p sesion_bot

    echo "📦 Instalando módulos de Node.js para WhatsApp y Noticias..."
    # Instalamos todo de una vez: Baileys + Scrapers + Programador
    npm install @whiskeysockets/baileys pino axios cheerio node-cron

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
    DisconnectReason 
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
        browser: ["Ubuntu", "Chrome", "20.0.0"],
        // Optimizaciones para evitar el "Connection Failure" en Termux
        connectTimeoutMs: 60000,
        defaultQueryTimeoutMs: 0,
        keepAliveIntervalMs: 10000
    });

    sock.ev.on("connection.update", async (update) => {
        const { connection, lastDisconnect } = update;

        if (connection === "close") {
            const statusCode = lastDisconnect?.error?.output?.statusCode;
            // Solo reiniciamos si no es un cierre por deslogueo manual
            if (statusCode !== DisconnectReason.loggedOut) {
                console.log("⚠️ Reajustando señal de red... reintentando en 5 segundos.");
                setTimeout(() => iniciarConexion(), 5000);
            }
        } else if (connection === "open") {
            console.log("\n✅ ¡CONEXIÓN EXITOSA! Noticiero Musical vinculado.");
            console.log("📌 El bot permanecerá en espera de noticias de getmetal.club...");
            // Ya no hay process.exit(0), el bot se queda vivo.
        }
    });

    // Proceso de solicitud de código de emparejamiento
    if (!sock.authState.creds.registered) {
        console.log("\n⏳ Sincronizando con los servidores de WhatsApp...");
        // Damos 10 segundos para que la conexión sea sólida antes de pedir el número
        await delay(10000); 

        console.log("\n------------------------------------------------");
        console.log("📱 CONFIGURACIÓN DE EMPAREJAMIENTO");
        console.log("------------------------------------------------");
        const numero = await question("👉 Introduce tu número de WhatsApp (ej: 521XXXXXXXXXX): ");
        
        if (numero.trim()) {
            try {
                // Pequeño delay extra para asegurar que el socket no se cierre durante la petición
                await delay(2000);
                const codigo = await sock.requestPairingCode(numero.trim());
                console.log(\`\\n🔑 TU CÓDIGO DE VINCULACIÓN ES: \${codigo}\`);
                console.log("Introduce este código en la notificación de tu teléfono.");
                console.log("------------------------------------------------\\n");
            } catch (error) {
                console.log("\\n❌ Error al generar el código. Reiniciando módulo...");
                setTimeout(() => iniciarConexion(), 3000);
            }
        }
    }

    sock.ev.on("creds.update", saveCreds);
}

iniciarConexion();
EOF

# Ejecución del bot
node index.js
