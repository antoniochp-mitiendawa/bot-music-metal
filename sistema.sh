#!/data/data/com.termux/files/usr/bin/bash

# Activar persistencia para que Termux no se detenga en segundo plano
termux-wake-lock

# --- CHECKPOINTS (PROHIBIDO MODIFICAR 1 Y 2 - BLINDADO) [cite: 15-19] ---
PASO1_BASE=".sistema_base_ok"
PASO2_MOTOR=".motor_ia_ok"

echo "🤖 [SISTEMA] Cargando Motor de Gestión Metal 2026 (Sincronización Corregida)..."

if [ -f "$PASO1_BASE" ];
then
    echo "✅ [MEMORIA] Paso 1 listo."
else
    pkg update -y -o Dpkg::Options::="--force-confold"
    pkg upgrade -y -o Dpkg::Options::="--force-confold"
    pkg install -y git openssl wget
    touch "$PASO1_BASE"
fi

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
# PASO 3: MOTOR DE IA Y SINCRONIZACIÓN (CORREGIDO)
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

// --- LIMPIADOR DE HORARIO [cite: 25] ---
function limpiarHorario(datoGoogle) {
    if (typeof datoGoogle !== 'string') return null;
    const match = datoGoogle.match(/(\d{2}:\d{2})/);
    return match ? match[1] : null;
}

// --- INVESTIGACIÓN DE BANDA (BLINDADO) [cite: 27-32] ---
async function investigarBandaPro(noticia) {
    const databaseMetal = {
        "Septicflesh": { pais: "Grecia 🇬🇷", historia: "Pioneros del Death Metal Sinfónico con una atmósfera orquestal única." },
        "Rotting Christ": { pais: "Grecia 🇬🇷", historia: "Leyendas del Dark Metal con un sonido ritualista y oscuro." }
    };
    const nombreBanda = noticia.banda ? noticia.banda.split(" - ")[0] : "Banda Desconocida";
    const info = databaseMetal[nombreBanda] || { 
        pais: "Origen Confirmado 🌎", 
        historia: "Agrupación destacada dentro de los nuevos lanzamientos de metal 2026." 
    };
    return {
        ...info,
        tracksFormatted: noticia.tracks ? `\n\n💿 *Tracks Destacados:*\n${noticia.tracks}` : ""
    };
}

// --- MOTOR DE SINCRONIZACIÓN (CORRECCIÓN DE COLUMNAS A-B-C-D) [cite: 13-14] ---
async function sincronizarConGoogle() {
    const config = obtenerConfig();
    if (!config.urlGoogle) return;
    try {
        const { data } = await axios.get(config.urlGoogle);
        // Mapeo explícito para asegurar que cada columna llegue a su lugar
        const agendaProcesada = data.map(item => ({
            banda: item.banda,      // Columna A
            youtube: item.youtube,  // Columna B
            horario: item.horario,  // Columna C
            tracks: item.tracks,    // Columna D
            horarioLimpio: limpiarHorario(item.horario)
        }));
        fs.writeFileSync(LOCAL_DB, JSON.stringify(agendaProcesada));
        console.log(`📥 Sincronización exitosa: ${agendaProcesada.length} registros cargados.`);
        return agendaProcesada;
    } catch (e) {
        console.log("❌ Error al traer información de Google Sheets.");
        return [];
    }
}

// --- FUNCIÓN DE DISPARO (BLINDADA) [cite: 37-40] ---
async function dispararPublicacion(sock, noticia, esPrueba = false) {
    const config = obtenerConfig();
    try {
        const infoExtra = await investigarBandaPro(noticia);
        const mensaje = `🎸 *${esPrueba ? 'PRUEBA DE INSTALACIÓN' : 'NUEVO LANZAMIENTO 2026'}* 🤘\n\n` +
                       `📢 *Disco:* ${noticia.banda || "N/A"}\n` +
                       `🌎 *Origen:* ${infoExtra.pais}\n` +
                       `📜 *Historia:* ${infoExtra.historia}${infoExtra.tracksFormatted}\n\n` +
                       `🔗 *Video Oficial:* ${noticia.youtube || "N/A"}`;

        await sock.sendMessage(config.idCanal, { 
            text: mensaje,
            linkPreview: noticia.youtube ? { "canonical-url": noticia.youtube } : null 
        });
        if(!esPrueba) console.log(`🚀 Publicado: ${noticia.banda} a las ${noticia.horarioLimpio}`);
    } catch (e) {
        console.log(`❌ Error al enviar publicación de ${noticia.banda}: ${e.message}`);
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
            console.log("\n✅ ¡SISTEMA VINCULADO CORRECTAMENTE!");
            let config = obtenerConfig();
            if (!config.idCanal) {
                const id = await question("👉 Pega el ID del Canal: ");
                guardarConfig({ idCanal: id.trim() });
            }
            if (!config.urlGoogle) {
                const url = await question("👉 Pega la URL de tu App Script: ");
                guardarConfig({ urlGoogle: url.trim(), esPrimeraVez: true });
            }
            config = obtenerConfig();
            const agenda = await sincronizarConGoogle();

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

node index.js
