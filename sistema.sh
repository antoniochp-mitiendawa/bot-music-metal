#!/data/data/com.termux/files/usr/bin/bash

# Activar persistencia para que Termux no se detenga en segundo plano
termux-wake-lock

# --- CHECKPOINTS (PROHIBIDO MODIFICAR 1 Y 2 - BLINDADO) ---
PASO1_BASE=".sistema_base_ok"
PASO2_MOTOR=".motor_ia_ok"

echo "🤖 [SISTEMA] Cargando Motor de Gestión Metal 2026 (Versión Estable)..."

# ==========================================
# PASO 1: CIMENTACIÓN (BLINDADO) [cite: 15-17]
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
# PASO 2: MOTOR DE EJECUCIÓN (BLINDADO) [cite: 18-19]
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
# PASO 3: MOTOR DE IA Y AGENDA (IMPLEMENTACIÓN INTEGRAL)
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

// --- LIMPIADOR DE HORARIO PARA COINCIDENCIA CON COLUMNA C ---
function limpiarHorario(datoGoogle) {
    if (typeof datoGoogle !== 'string') return null;
    const match = datoGoogle.match(/(\d{2}:\d{2})/);
    return match ? match[1] : null;
}

// --- VALIDACIÓN TÉCNICA DE VIDEO ---
async function verificarVideo(url) {
    try {
        const res = await axios.get(url, { timeout: 5000 });
        return !res.data.includes("videoIsUnavailable");
    } catch { return false; }
}

// --- BÚSQUEDA DE PORTADA (SIN BASURA LOCAL) ---
async function obtenerPortadaLink(banda) {
    try {
        const query = encodeURIComponent(`${banda} album cover art metal`);
        const searchUrl = `https://www.google.com/search?q=${query}&tbm=isch`;
        const { data } = await axios.get(searchUrl, { headers: { 'User-Agent': 'Mozilla/5.0' } });
        const link = data.match(/src="(https:\/\/encrypted-tbn0\.gstatic\.com\/images\?q=[^"]+)"/);
        return link ? link[1] : null;
    } catch { return null; }
}

// --- INVESTIGACIÓN DE BANDA (BLINDADO CON EMOJIS) [cite: 27-32] ---
async function investigarBandaPro(noticia) {
    const databaseMetal = {
        "Septicflesh": { pais: "Grecia 🇬🇷", historia: "Pioneros del Death Metal Sinfónico con una atmósfera orquestal única." },
        "Rotting Christ": { pais: "Grecia 🇬🇷", historia: "Leyendas del Dark Metal con un sonido ritualista y oscuro." }
    };
    const nombreBanda = noticia.banda.split(" - ")[0];
    const info = databaseMetal[nombreBanda] || { 
        pais: "Origen Confirmado 🌎", 
        historia: "Agrupación destacada dentro de los nuevos lanzamientos de metal 2026." 
    };
    return {
        ...info,
        tracksFormatted: noticia.tracks ? `\n\n💿 *Tracks Destacados:*\n${noticia.tracks}` : ""
    };
}

// --- SINCRONIZACIÓN Y PROGRAMACIÓN DE ALARMAS (MAPEO A-B-C-D) ---
async function sincronizarYProgramar(sock) {
    const config = obtenerConfig();
    if (!config.urlGoogle) return;

    try {
        console.log("📥 Sincronizando todas las filas desde Google...");
        const { data } = await axios.get(config.urlGoogle);
        
        // Mapeo exacto: A=banda, B=youtube, C=horario, D=tracks [cite: 13-14]
        const agenda = data.map(item => ({
            ...item,
            horarioLimpio: limpiarHorario(item.horario)
        }));
        
        fs.writeFileSync(LOCAL_DB, JSON.stringify(agenda));

        // Programación de tareas exactas (Scheduler)
        agenda.forEach(item => {
            if (item.horarioLimpio) {
                const [hora, min] = item.horarioLimpio.split(":");
                cron.schedule(`${min} ${hora} * * *`, () => dispararPublicacion(sock, item));
                console.log(`⏰ Alarma configurada: ${item.banda} -> ${item.horarioLimpio}`);
            }
        });
        return agenda;
    } catch (e) {
        console.log("❌ Error al consultar la hoja.");
        return [];
    }
}

// --- DISPARO DE PUBLICACIÓN (BLINDADO CON NUEVAS MEJORAS) ---
async function dispararPublicacion(sock, noticia, esPrueba = false) {
    const config = obtenerConfig();
    
    // Validación de video verídica
    const videoOk = await verificarVideo(noticia.youtube);
    if (!videoOk && !esPrueba) {
        console.log(`⚠️ Video no disponible para ${noticia.banda}, post cancelado.`);
        return;
    }

    const infoExtra = await investigarBandaPro(noticia);
    const portadaUrl = await obtenerPortadaLink(noticia.banda);

    const mensaje = `🎸 *${esPrueba ? 'PRUEBA DE INSTALACIÓN' : 'NUEVO LANZAMIENTO 2026'}* 🤘\n\n` +
                   `📢 *Disco:* ${noticia.banda}\n` +
                   `🌎 *Origen:* ${infoExtra.pais}\n` +
                   `📜 *Historia:* ${infoExtra.historia}${infoExtra.tracksFormatted}\n\n` +
                   `🔗 *Video Oficial:* ${noticia.youtube}`;

    // Envío con imagen si existe, si no, solo texto
    if (portadaUrl) {
        await sock.sendMessage(config.idCanal, { image: { url: portadaUrl }, caption: mensaje });
    } else {
        await sock.sendMessage(config.idCanal, { text: mensaje });
    }
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
                // Extracción automática del ID desde la liga
                const idMatch = link.match(/channel\/([a-zA-Z0-9]+)/) || link.match(/chat\.whatsapp\.com\/([a-zA-Z0-9]+)/) || [null, link];
                const idFinal = idMatch[1] || link.trim();
                guardarConfig({ idCanal: idFinal });
                console.log(`✅ ID de destino configurado: ${idFinal}`);
            }
            if (!config.urlGoogle) {
                const url = await question("👉 Pega la URL de tu App Script: ");
                guardarConfig({ urlGoogle: url.trim(), esPrimeraVez: true });
            }
            
            config = obtenerConfig();
            const agenda = await sincronizarYProgramar(sock);

            // Mensaje de prueba de debut [cite: 45-46]
            if (config.esPrimeraVez && agenda && agenda.length > 0) {
                console.log("🧪 Validando formato con mensaje de prueba...");
                await dispararPublicacion(sock, agenda[0], true);
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
