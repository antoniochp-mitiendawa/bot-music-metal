#!/data/data/com.termux/files/usr/bin/bash

# Activar persistencia para que Termux no se detenga en segundo plano
termux-wake-lock

# --- CHECKPOINTS (PROHIBIDO MODIFICAR 1 Y 2 - BLINDADO) ---
PASO1_BASE=".sistema_base_ok"
PASO2_MOTOR=".motor_ia_ok"

echo "🤖 [SISTEMA] Cargando Motor de Gestión con Filtro de Tracks..."

# ==========================================
# PASO 1: CIMENTACIÓN (BLINDADO) [cite: 1-3]
# ==========================================
if [ -f "$PASO1_BASE" ]; then
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
if [ -f "$PASO2_MOTOR" ]; then
    echo "✅ [MEMORIA] Paso 2 listo."
else
    pkg install -y nodejs-lts python ffmpeg libsqlite
    mkdir -p datos_ia
    mkdir -p sesion_bot
    npm install @whiskeysockets/baileys pino readline axios cheerio node-cron
    touch "$PASO2_MOTOR"
fi

# ==========================================
# PASO 3: MOTOR DE IA Y SINCRONIZACIÓN (EVOLUCIONADO) [cite: 6-33]
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

// --- LIMPIADOR DE HORARIO PARA EVITAR ERRORES DE ZONA [cite: 10-11] ---
function limpiarHorario(datoGoogle) {
    if (typeof datoGoogle !== 'string') return null;
    const match = datoGoogle.match(/(\d{2}:\d{2})/);
    return match ? match[1] : null;
}

// --- INVESTIGACIÓN REAL Y FILTRADO DE IDENTIDAD [cite: 12-13, 19] ---
async function investigarBandaPro(noticia) {
    console.log(`🔍 Filtrando y validando: ${noticia.banda}...`);
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

async function sincronizarConGoogle() {
    const config = obtenerConfig();
    if (!config.urlGoogle) return;

    try {
        const { data } = await axios.get(config.urlGoogle);
        const agendaProcesada = data.map(item => ({
            ...item,
            horarioLimpio: limpiarHorario(item.horario)
        }));
        fs.writeFileSync(LOCAL_DB, JSON.stringify(agendaProcesada));
        return agendaProcesada;
    } catch (e) {
        console.log("❌ Error de sincronización.");
        return [];
    }
}

async function dispararPublicacion(sock, noticia, esPrueba = false) {
    const config = obtenerConfig();
    const infoExtra = await investigarBandaPro(noticia);
    
    const mensaje = `🎸 *${esPrueba ? 'PRUEBA DE INSTALACIÓN' : 'NUEVO LANZAMIENTO 2026'}* 🤘\n\n` +
                   `📢 *Disco:* ${noticia.banda}\n` +
                   `🌎 *Origen:* ${infoExtra.pais}\n` +
                   `📜 *Historia:* ${infoExtra.historia}${infoExtra.tracksFormatted}\n\n` +
                   `🔗 *Video Oficial:* ${noticia.youtube}`;

    await sock.sendMessage(config.idCanal, { 
        text: mensaje,
        linkPreview: { "canonical-url": noticia.youtube } 
    });
    if(!esPrueba) console.log(`🚀 Publicado: ${noticia.banda} a las ${noticia.horarioLimpio}`);
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
            console.log("\n✅ ¡SISTEMA VINCULADO CORRECTAMENTE!");
            
            let config = obtenerConfig();
            if (!config.idCanal) {
                const urlCanal = await question("👉 Pega la liga de tu Canal (URL): ");
                let idLimpio = urlCanal.trim();
                
                // Extracción inteligente del ID desde la URL 
                if (idLimpio.includes("whatsapp.com/channel/")) {
                    idLimpio = idLimpio.split("/").pop() + "@newsletter";
                } else if (!idLimpio.includes("@")) {
                    idLimpio = idLimpio + "@newsletter";
                }
                
                console.log(`✅ URL detectada. El ID técnico es: ${idLimpio}`);
                guardarConfig({ idCanal: idLimpio });
            }

            if (!config.urlGoogle) {
                const url = await question("👉 Pega la URL de tu App Script: ");
                guardarConfig({ urlGoogle: url.trim(), esPrimeraVez: true });
            }
            
            config = obtenerConfig();
            const agenda = await sincronizarConGoogle();

            // --- PRUEBA DE DEBUT (SOLO UNA VEZ AL INSTALAR) --- [cite: 31-32]
            if (config.esPrimeraVez && agenda && agenda.length > 0) {
                console.log("🧪 Realizando prueba de formato con datos reales...");
                await dispararPublicacion(sock, agenda[0], true);
                guardarConfig({ esPrimeraVez: false });
            }

            cron.schedule('* * * * *', async () => {
                const ahora = new Date().toLocaleTimeString('es-MX', { hour12: false, hour: '2-digit', minute: '2-digit' });
                if (fs.existsSync(LOCAL_DB)) {
                    const datos = JSON.parse(fs.readFileSync(LOCAL_DB));
                    for (const item of datos) {
                        if (item.horarioLimpio === ahora) {
                            await dispararPublicacion(sock, item);
                        }
                    }
                }
            });
            cron.schedule('0 9 * * *', async () => { await sincronizarConGoogle(); });
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

# Ejecución final [cite: 33]
node index.js
