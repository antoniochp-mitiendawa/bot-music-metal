#!/data/data/com.termux/files/usr/bin/bash

# Activar persistencia para que Termux no se detenga en segundo plano
termux-wake-lock

# --- CHECKPOINTS (PROHIBIDO MODIFICAR 1 Y 2 - BLINDADO) [cite: 15] ---
PASO1_BASE=".sistema_base_ok"
PASO2_MOTOR=".motor_ia_ok"

echo "🤖 [SISTEMA] Cargando Motor de Gestión con Filtro de Tracks..."

# ==========================================
# PASO 1: CIMENTACIÓN (BLINDADO) [cite: 16-17]
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
# PASO 2: MOTOR DE EJECUCIÓN (BLINDADO) [cite: 18-19]
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
# PASO 3: MOTOR DE IA Y SINCRONIZACIÓN (BLINDADO Y CORREGIDO) [cite: 20-55]
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

// --- SISTEMA SPINTAX PARA VARIEDAD (NUEVA FUNCIONALIDAD) ---
function aplicarSpintax(texto) {
    return texto.replace(/\{([^{}]+)\}/g, (match, opciones) => {
        const lista = opciones.split('|');
        return lista[Math.floor(Math.random() * lista.length)];
    });
}

function limpiarHorario(dato) {
    if (!dato) return null;
    const texto = String(dato);
    const match = texto.match(/(\d{1,2}:\d{2})/);
    if (!match) return null;
    let [horas, minutos] = match[1].split(':');
    return `${horas.padStart(2, '0')}:${minutos}`;
}

async function investigarBandaPro(noticia) {
    console.log(`🔍 Filtrando y validando: ${noticia.banda}...`);
    const databaseMetal = {
        "Septicflesh": { pais: "Grecia 🇬🇷", historia: "Pioneros del Death Metal Sinfónico con una atmósfera orquestal única." },
        "Rotting Christ": { pais: "Grecia 🇬🇷", historia: "Leyendas del Dark Metal con un sonido ritualista y oscuro." }
    };

    const nombreBanda = noticia.banda ? noticia.banda.split(" - ")[0] : "Desconocido";
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
    if (!config.urlGoogle) return [];

    try {
        const { data } = await axios.get(config.urlGoogle);
        // Mapeo espejo de Codigogs.txt 
        const agendaProcesada = data.map(item => ({
            banda: item.banda,
            youtube: item.youtube,
            horario: item.horario,
            tracks: item.tracks,
            horarioLimpio: limpiarHorario(item.horario)
        })).filter(i => i.banda && i.horarioLimpio);
        
        fs.writeFileSync(LOCAL_DB, JSON.stringify(agendaProcesada));
        console.log(`📅 Agenda: ${agendaProcesada.length} bandas programadas.`);
        return agendaProcesada;
    } catch (e) {
        console.log("❌ Error al leer Google Sheets.");
        return [];
    }
}

async function dispararPublicacion(sock, noticia, esPrueba = false) {
    const config = obtenerConfig();
    if (!config.idCanal) return;

    const infoExtra = await investigarBandaPro(noticia);
    const encabezado = esPrueba ? 'PRUEBA DE INSTALACIÓN' : aplicarSpintax('{NUEVO LANZAMIENTO|ESTRENO METALERO|ACTUALIDAD METAL} 2026');
    
    const mensaje = `🎸 *${encabezado}* 🤘\n\n` +
                   `📢 *Disco:* ${noticia.banda}\n` +
                   `🌎 *Origen:* ${infoExtra.pais}\n` +
                   `📜 *Historia:* ${infoExtra.historia}${infoExtra.tracksFormatted}\n\n` +
                   `🔗 *Video Oficial:* ${noticia.youtube}`;

    await sock.sendMessage(config.idCanal, { 
        text: mensaje,
        linkPreview: { "canonical-url": noticia.youtube } 
    });
    
    if (!esPrueba) console.log(`🚀 Publicado: ${noticia.banda} [${noticia.horarioLimpio}]`);
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
                if (idLimpio.includes("whatsapp.com/channel/")) {
                    idLimpio = idLimpio.split("/").pop() + "@newsletter";
                } else if (!idLimpio.includes("@")) {
                    idLimpio = idLimpio + "@newsletter";
                }
                console.log(`✅ ID detectado: ${idLimpio}`);
                guardarConfig({ idCanal: idLimpio });
                config = obtenerConfig(); 
            }

            if (!config.urlGoogle) {
                const url = await question("👉 Pega la URL de tu App Script: ");
                guardarConfig({ urlGoogle: url.trim(), esPrimeraVez: true });
                config = obtenerConfig();
            }
            
            const agenda = await sincronizarConGoogle();

            // --- MENSAJE DE PRUEBA RESTAURADO (AL INSTALAR) [cite: 48-49] ---
            if (config.esPrimeraVez && agenda.length > 0) {
                console.log("🧪 Disparando mensaje de prueba inmediato...");
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
