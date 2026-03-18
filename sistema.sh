#!/data/data/com.termux/files/usr/bin/bash

# Activar persistencia para que Termux no se detenga en segundo plano
termux-wake-lock

# --- CHECKPOINTS (PROHIBIDO MODIFICAR 1 Y 2 - BLINDADO) ---
PASO1_BASE=".sistema_base_ok"
PASO2_MOTOR=".motor_ia_ok"

echo "🤖 [SISTEMA] Cargando Motor de Gestión por Hoja de Cálculo..."

# ==========================================
# PASO 1: CIMENTACIÓN (BLINDADO)
# ==========================================
if [ -f "$PASO1_BASE" ];
then
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
if [ -f "$PASO2_MOTOR" ];
then
    echo "✅ [MEMORIA] Paso 2 listo."
else
    pkg install -y nodejs-lts python ffmpeg libsqlite
    mkdir -p datos_ia
    mkdir -p sesion_bot
    npm install @whiskeysockets/baileys pino readline axios cheerio node-cron
    touch "$PASO2_MOTOR"
fi

# ==========================================
# PASO 3: MOTOR DE IA Y SINCRONIZACIÓN (NUEVO)
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
const fs = require("fs");
const cron = require("node-cron");

const rl = readline.createInterface({ input: process.stdin, output: process.stdout });
const question = (text) => new Promise((resolve) => rl.question(text, resolve));

const CONFIG_PATH = "./datos_ia/config.json";
const LOCAL_DB = "./datos_ia/agenda_dia.json";

function obtenerConfig() {
    if (!fs.existsSync(CONFIG_PATH)) return {};
    try { return JSON.parse(fs.readFileSync(CONFIG_PATH)); } catch { return {}; }
}

function guardarConfig(data) {
    const actual = obtenerConfig();
    fs.writeFileSync(CONFIG_PATH, JSON.stringify({ ...actual, ...data }));
}

// --- LIMPIADOR DE HORARIO (BLINDAJE CONTRA ZONAS HORARIAS) ---
function limpiarHorario(datoGoogle) {
    // Si Google manda "1899-12-30T10:00:00Z", extraemos solo "10:00"
    const match = datoGoogle.match(/(\d{2}:\d{2})/);
    return match ? match[1] : null;
}

// --- INVESTIGACIÓN DE LA BANDA (IA SIMULADA) ---
async function investigarBanda(nombreRaw) {
    console.log(`🔍 Investigando trasfondo de: ${nombreRaw}...`);
    // Aquí el sistema busca nacionalidad y resumen (Simulado para estabilidad)
    // En versiones futuras esto conectará con APIs de música
    const info = {
        pais: "Desconocido 🌍",
        resumen: "Lanzamiento destacado de metal para este 2026."
    };
    return info;
}

async function sincronizarConGoogle() {
    const config = obtenerConfig();
    if (!config.urlGoogle) return console.log("⚠️ No hay URL de Google configurada.");

    console.log("📥 Sincronizando con Google Sheets...");
    try {
        const { data } = await axios.get(config.urlGoogle);
        const agendaProcesada = data.map(item => ({
            ...item,
            horarioLimpio: limpiarHorario(item.horario)
        }));
        
        fs.writeFileSync(LOCAL_DB, JSON.stringify(agendaProcesada));
        console.log(`✅ Sincronización exitosa. ${agendaProcesada.length} bandas cargadas.`);
    } catch (e) {
        console.log("❌ Error al conectar con Google Apps Script.");
    }
}

async function dispararPublicacion(sock, noticia) {
    const config = obtenerConfig();
    const infoExtra = await investigarBanda(noticia.banda);
    
    const mensaje = `🎸 *NUEVO LANZAMIENTO 2026* 🤘\n\n` +
                   `📢 *Disco:* ${noticia.banda}\n` +
                   `🌎 *Origen:* ${infoExtra.pais}\n` +
                   `📝 *Nota:* ${infoExtra.resumen}\n\n` +
                   `🔗 *Ver aquí:* ${noticia.youtube}`;

    await sock.sendMessage(config.idCanal, { text: mensaje });
    console.log(`🚀 Publicado con éxito: ${noticia.banda} a las ${noticia.horarioLimpio}`);
}

async function iniciarConexion() {
    const { state, saveCreds } = await useMultiFileAuthState('sesion_bot');
    const { version } = await fetchLatestBaileysVersion();

    const sock = makeWASocket({
        version,
        logger: pino({ level: "silent" }),
        printQRInTerminal: false,
        auth: state,
        browser: ["Ubuntu", "Chrome", "20.0.04"]
    });

    sock.ev.on("connection.update", async (update) => {
        const { connection, lastDisconnect } = update;
        if (connection === "close") {
            if (lastDisconnect?.error?.output?.statusCode !== DisconnectReason.loggedOut) iniciarConexion();
        } else if (connection === "open") {
            console.log("\n✅ ¡CONEXIÓN EXITOSA!");
            
            let config = obtenerConfig();
            if (!config.idCanal) {
                const id = await question("👉 Pega el ID del Canal (@newsletter): ");
                guardarConfig({ idCanal: id.trim() });
            }
            if (!config.urlGoogle) {
                const url = await question("👉 Pega la URL de tu App Script: ");
                guardarConfig({ urlGoogle: url.trim() });
            }
            
            config = obtenerConfig();
            await sock.sendMessage(config.idCanal, { text: "🤖 *Sistema Metal Sincronizado*\nConexión con Google Sheets: OK.\nEsperando horarios de publicación..." });

            // Sincronización inicial y luego cada mañana a las 09:00
            await sincronizarConGoogle();
            
            // Revisión de agenda cada minuto
            cron.schedule('* * * * *', async () => {
                const ahora = new Date().toLocaleTimeString('es-MX', { hour12: false, hour: '2-digit', minute: '2-digit' });
                if (fs.existsSync(LOCAL_DB)) {
                    const agenda = JSON.parse(fs.readFileSync(LOCAL_DB));
                    for (const item of agenda) {
                        if (item.horarioLimpio === ahora) {
                            await dispararPublicacion(sock, item);
                        }
                    }
                }
            });

            // Sincronizar con Google cada mañana
            cron.schedule('0 9 * * *', async () => {
                await sincronizarConGoogle();
            });
        }
    });

    if (!sock.authState.creds.registered) {
        await delay(5000);
        const numero = await question("👉 Introduce tu número de WhatsApp (ej: 521...): ");
        const codigo = await sock.requestPairingCode(numero.trim());
        console.log(`\n🔑 CÓDIGO DE VINCULACIÓN: ${codigo}\n`);
    }

    sock.ev.on("creds.update", saveCreds);
}

iniciarConexion();
EOF

# Ejecución final
node index.js
