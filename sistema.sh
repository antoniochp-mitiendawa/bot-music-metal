#!/data/data/com.termux/files/usr/bin/bash
termux-wake-lock

# --- INSTALACIÓN COMPLETA ORIGINAL ---
pkg update -y && pkg upgrade -y
pkg install -y git nodejs-lts python ffmpeg libsqlite openssl wget
mkdir -p datos_ia sesion_bot
npm install @whiskeysockets/baileys pino readline axios node-cron

cat << 'EOF' > bot_metal.js
const { default: makeWASocket, useMultiFileAuthState, delay, fetchLatestBaileysVersion, DisconnectReason } = require("@whiskeysockets/baileys");
const pino = require("pino");
const readline = require("readline");
const axios = require("axios");
const fs = require("fs");
const cron = require("node-cron");

const rl = readline.createInterface({ input: process.stdin, output: process.stdout });
const question = (text) => new Promise((resolve) => rl.question(text, resolve));
const CONFIG_PATH = "./datos_ia/config.json";
const AGENDA_PATH = "./datos_ia/agenda.json";

// --- FUNCIONES DE PERSISTENCIA BLINDADAS ---
function obtenerConfig() {
    if (!fs.existsSync(CONFIG_PATH)) return {};
    return JSON.parse(fs.readFileSync(CONFIG_PATH));
}

function guardarConfig(data) {
    const actual = obtenerConfig();
    fs.writeFileSync(CONFIG_PATH, JSON.stringify({ ...actual, ...data }, null, 2));
}

function obtenerAgenda() {
    if (!fs.existsSync(AGENDA_PATH)) return [];
    return JSON.parse(fs.readFileSync(AGENDA_PATH));
}

function guardarAgenda(data) {
    fs.writeFileSync(AGENDA_PATH, JSON.stringify(data, null, 2));
}

// --- MOTOR DE SPINTAX Y HUMANIZACIÓN ---
function aplicarSpintax(texto) {
    const opciones = {
        saludos: ["¡Atención!", "🤘 Novedades,", "📢 Noticia de última hora:", "🔥 Estreno:", "✨ Mira esto:"],
        emojis: ["🤘", "🔥", "🎸", "💀", "💿", "🚀", "📢", "✨"],
        cierres: ["¡No te lo pierdas!", "¡Dale play ahora!", "¡Disponible ya!", "🤘 Keep on rocking!"]
    };

    const saludo = opciones.saludos[Math.floor(Math.random() * opciones.saludos.length)];
    const emoji = opciones.emojis[Math.floor(Math.random() * opciones.emojis.length)];
    const cierre = opciones.cierres[Math.floor(Math.random() * opciones.cierres.length)];

    return `${emoji} *${saludo}*\n\n${texto}\n\n${emoji} ${cierre}`;
}

async function simularEscritura(sock, idCanal) {
    await sock.sendPresenceUpdate('composing', idCanal);
    const delayHuman = Math.floor(Math.random() * (10000 - 5000 + 1)) + 5000;
    await delay(delayHuman);
    await sock.sendPresenceUpdate('paused', idCanal);
}

// --- SINCRONIZACIÓN MAESTRA (AGNOSTICA) ---
async function sincronizarDatos(urlGoogle, enviarPrueba = false, sock = null, idCanal = null) {
    try {
        const res = await axios.get(urlGoogle);
        const data = res.data;
        if (Array.isArray(data)) {
            guardarAgenda(data);
            console.log(`✅ Sincronización exitosa: ${data.length} registros guardados.`);
            
            if (enviarPrueba && data.length > 0 && sock && idCanal) {
                console.log("🚀 Ejecutando envío de prueba inicial...");
                await enviarPublicacion(sock, idCanal, data[0]);
            }
        }
    } catch (e) {
        console.log("❌ Error en sincronización: " + e.message);
    }
}

async function enviarPublicacion(sock, idCanal, item) {
    // Construcción dinámica basada en encabezados (Agnosticismo de producto)
    let cuerpoBase = "";
    Object.keys(item).forEach(key => {
        if (key !== 'horario' && key !== 'fila') {
            const etiqueta = key.charAt(0).toUpperCase() + key.slice(1);
            cuerpoBase += `✅ *${etiqueta}:* ${item[key]}\n`;
        }
    });

    const mensajeFinal = aplicarSpintax(cuerpoBase);
    
    // Humanización: Delay aleatorio antes de empezar a escribir (0-60 seg)
    const jitter = Math.floor(Math.random() * 60000);
    await delay(jitter);

    await simularEscritura(sock, idCanal);
    await sock.sendMessage(idCanal, { text: mensajeFinal });
    console.log(`✅ Publicación realizada: ${new Date().toLocaleTimeString()}`);
}

async function iniciar() {
    const { state, saveCreds } = await useMultiFileAuthState('sesion_bot');
    const { version } = await fetchLatestBaileysVersion();

    const sock = makeWASocket({
        version,
        logger: pino({ level: "silent" }),
        auth: state,
        printQRInTerminal: false,
        browser: ["Ubuntu", "Chrome", "20.0.04"]
    });

    sock.ev.on("creds.update", saveCreds);

    sock.ev.on("connection.update", async (up) => {
        const { connection, lastDisconnect } = up;

        if (connection === "open") {
            console.log("\n✅ SISTEMA CONECTADO Y VINCULADO");
            let config = obtenerConfig();

            // --- PASO 2 Y 3: CONFIGURACIÓN ÚNICA ---
            if (!config.idCanal || !config.urlGoogle) {
                console.log("\n👉 PASO DE CONFIGURACIÓN INICIAL ACTIVO...");
                
                const handler = async (m) => {
                    const msg = m.messages[0];
                    if (msg.key.remoteJid.endsWith("@newsletter") && !config.idCanal) {
                        const realID = msg.key.remoteJid;
                        console.log(`✅ ID REAL CAPTURADO: ${realID}`);
                        
                        const url = await question("\n👉 PASO 3: Pega la URL de tu App Script: ");
                        const cleanedUrl = url.trim();
                        
                        guardarConfig({ idCanal: realID, urlGoogle: cleanedUrl });
                        config = obtenerConfig(); // Refrescar en memoria
                        
                        console.log("✅ Configuración guardada permanentemente.");
                        
                        // Sincronización inicial y prueba inmediata
                        await sincronizarDatos(cleanedUrl, true, sock, realID);
                        
                        // ELIMINAR ESCUCHADOR: Blindaje contra repetición
                        sock.ev.off("messages.upsert", handler);
                        console.log("🔒 Modo configuración desactivado.");
                    }
                };
                sock.ev.on("messages.upsert", handler);
            } else {
                console.log("🚀 El bot está operando en modo SILENCIOSO (Sin escucha activa).");
                // Sincronización al arrancar si ya está configurado
                await sincronizarDatos(config.urlGoogle);
            }

            // --- CRON 1: SINCRONIZACIÓN MAESTRA DIARIA (10:00 AM) ---
            cron.schedule('0 10 * * *', async () => {
                const conf = obtenerConfig();
                if (conf.urlGoogle) {
                    await sincronizarDatos(conf.urlGoogle);
                }
            }, { timezone: "America/Mexico_City" });

            // --- CRON 2: VERIFICADOR DE PUBLICACIONES (CADA MINUTO SOBRE CACHE LOCAL) ---
            cron.schedule('* * * * *', async () => {
                const conf = obtenerConfig();
                const agenda = obtenerAgenda();
                if (!conf.idCanal || agenda.length === 0) return;

                const ahora = new Date().toLocaleTimeString('es-MX', { 
                    hour12: false, hour: '2-digit', minute: '2-digit', 
                    timeZone: 'America/Mexico_City' 
                });

                for (const item of agenda) {
                    if (item.horario === ahora) {
                        await enviarPublicacion(sock, conf.idCanal, item);
                    }
                }
            });
        }

        if (connection === "close") {
            if (lastDisconnect?.error?.output?.statusCode !== DisconnectReason.loggedOut) {
                iniciar();
            }
        }
    });

    if (!sock.authState.creds.registered) {
        await delay(5000);
        const numero = await question("👉 Introduce tu número (con código de país, ej: 521...): ");
        const codigo = await sock.requestPairingCode(numero.trim());
        console.log(`\n🔑 CÓDIGO DE VINCULACIÓN: ${codigo}\n`);
    }
}

iniciar();
EOF

node bot_metal.js
