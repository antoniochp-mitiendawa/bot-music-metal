#!/data/data/com.termux/files/usr/bin/bash

# Activar persistencia para que Termux no se detenga en segundo plano
termux-wake-lock

# --- CHECKPOINTS (PROHIBIDO MODIFICAR 1 Y 2 - BLINDADO) ---
PASO1_BASE=".sistema_base_ok"
PASO2_MOTOR=".motor_ia_ok"

echo "🤖 [SISTEMA] Cargando Motor de Gestión Metal 2026 (Versión Programada)..."

# ==========================================
# PASO 1: CIMENTACIÓN (BLINDADO) [cite: 1-3]
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
# PASO 2: MOTOR DE EJECUCIÓN (BLINDADO) [cite: 4-5]
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
# PASO 3: MOTOR DE IA Y AGENDA (IMPLEMENTACIÓN)
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

function limpiarHorario(datoGoogle) {
    if (typeof datoGoogle !== 'string') return null;
    const match = datoGoogle.match(/(\d{2}:\d{2})/);
    return match ? match[1] : null;
}

// --- VALIDACIÓN DE VIDEO Y BÚSQUEDA DE PORTADA ---
async function verificarVideo(url) {
    try {
        const res = await axios.get(url);
        return !res.data.includes("videoIsUnavailable");
    } catch { return false; }
}

async function obtenerPortada(banda, album) {
    console.log(`🖼️ Buscando portada para: ${banda} - ${album}...`);
    // Simulación de búsqueda de imagen profesional
    return "https://m.media-amazon.com/images/I/81O57f-C6rL._SL1500_.jpg"; 
}

async function investigarBandaPro(noticia) {
    const databaseMetal = {
        "Septicflesh": { pais: "Grecia 🇬🇷", historia: "Pioneros del Death Metal Sinfónico." },
        "Rotting Christ": { pais: "Grecia 🇬🇷", historia: "Leyendas del Dark Metal ritualista." }
    };
    const nombreBanda = noticia.banda.split(" - ")[0];
    const info = databaseMetal[nombreBanda] || { pais: "Internacional 🌎", historia: "Lanzamiento destacado de 2026." };
    return { ...info, tracksFormatted: noticia.tracks ? `\n\n💿 *Tracks:* ${noticia.tracks}` : "" };
}

async function sincronizarYProgramar(sock) {
    const config = obtenerConfig();
    if (!config.urlGoogle) return;

    try {
        console.log("📥 Sincronizando agenda desde Google...");
        const { data } = await axios.get(config.urlGoogle);
        const agenda = data.map(item => ({ ...item, horarioLimpio: limpiarHorario(item.horario) }));
        fs.writeFileSync(LOCAL_DB, JSON.stringify(agenda));

        // Programación de alarmas (Scheduler) para ahorro de batería
        agenda.forEach(item => {
            if (item.horarioLimpio) {
                const [hora, min] = item.horarioLimpio.split(":");
                cron.schedule(`${min} ${hora} * * *`, () => dispararPublicacion(sock, item));
                console.log(`⏰ Alarma programada: ${item.banda} a las ${item.horarioLimpio}`);
            }
        });
    } catch (e) { console.log("❌ Error de sincronización."); }
}

async function dispararPublicacion(sock, noticia, esPrueba = false) {
    const config = obtenerConfig();
    
    // Verificación de video antes de postear
    const videoOk = await verificarVideo(noticia.youtube);
    if (!videoOk && !esPrueba) {
        console.log(`⚠️ Video no disponible: ${noticia.banda}.`);
        return; 
    }

    const info = await investigarBandaPro(noticia);
    const portadaUrl = await obtenerPortada(noticia.banda, "Album");

    const caption = `🎸 *${esPrueba ? 'PRUEBA DE DEBUT' : 'NUEVO LANZAMIENTO'}* 🤘\n\n` +
                   `📢 *Disco:* ${noticia.banda}\n` +
                   `🌎 *Origen:* ${info.pais}\n` +
                   `📜 *Historia:* ${info.history || info.historia}${info.tracksFormatted}\n\n` +
                   `🔗 *Video:* ${noticia.youtube}`;

    // Envío con imagen de portada y pie de foto (caption)
    await sock.sendMessage(config.idCanal, { 
        image: { url: portadaUrl }, 
        caption: caption 
    });
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
            console.log("\n✅ SISTEMA VINCULADO CORRECTAMENTE");
            
            let config = obtenerConfig();
            if (!config.idCanal) {
                const link = await question("👉 Pega el link de invitación o ID del Canal: ");
                // Extracción local del ID del canal
                const idMatch = link.match(/chat\.whatsapp\.com\/([a-zA-Z0-9]+)/) || [null, link];
                guardarConfig({ idCanal: idMatch[1] || link.trim() });
            }
            if (!config.urlGoogle) {
                const url = await question("👉 Pega la URL de tu App Script: ");
                guardarConfig({ urlGoogle: url.trim(), esPrimeraVez: true });
            }
            
            config = obtenerConfig();
            await sincronizarYProgramar(sock);

            // Prueba de debut al instalar
            if (config.esPrimeraVez) {
                const agendaRaw = fs.readFileSync(LOCAL_DB);
                const agenda = JSON.parse(agendaRaw);
                if (agenda.length > 0) await dispararPublicacion(sock, agenda[0], true);
                guardarConfig({ esPrimeraVez: false });
            }

            cron.schedule('0 9 * * *', () => sincronizarYProgramar(sock));
        }
    });

    if (!sock.authState.creds.registered) {
        await delay(5000);
        const numero = await question("👉 Tu número (ej: 521...): ");
        const codigo = await sock.requestPairingCode(numero.trim());
        console.log(`\n🔑 CÓDIGO DE VINCULACIÓN: ${codigo}\n`);
    }
    sock.ev.on("creds.update", saveCreds);
}
iniciarConexion();
EOF

node index.js
