#!/data/data/com.termux/files/usr/bin/bash
termux-wake-lock

# --- INSTALACIÓN DE DEPENDENCIAS ADICIONALES PARA BÚSQUEDA ---
pkg update -y && pkg upgrade -y
pkg install -y git nodejs-lts python ffmpeg libsqlite openssl wget
mkdir -p datos_ia sesion_bot
# Instalamos 'cheerio' para el scraping silencioso sin APIs
npm install @whiskeysockets/baileys pino readline axios node-cron cheerio

cat << 'EOF' > bot_metal.js
const { default: makeWASocket, useMultiFileAuthState, delay, fetchLatestBaileysVersion, DisconnectReason } = require("@whiskeysockets/baileys");
const pino = require("pino");
const readline = require("readline");
const axios = require("axios");
const fs = require("fs");
const cron = require("node-cron");
const cheerio = require("cheerio");

const rl = readline.createInterface({ input: process.stdin, output: process.stdout });
const question = (text) => new Promise((resolve) => rl.question(text, resolve));

const CONFIG_PATH = "./datos_ia/config.json";
const INFO_HOY_PATH = "./datos_ia/hoy.json";

// --- MOTOR DE SPINTAX Y FORMATO ---
const spintax = (text) => {
    return text.replace(/\{([^{}]+)\}/g, (match, options) => {
        const choices = options.split('|');
        return choices[Math.floor(Math.random() * choices.length)];
    });
};

function obtenerConfig() {
    if (!fs.existsSync(CONFIG_PATH)) return {};
    return JSON.parse(fs.readFileSync(CONFIG_PATH));
}

function guardarConfig(data) {
    const actual = obtenerConfig();
    fs.writeFileSync(CONFIG_PATH, JSON.stringify({ ...actual, ...data }));
}

// --- CAPA DE INTELIGENCIA: BÚSQUEDA Y SCRAPING (SIN API) ---
async function enriquecerInformacion(bandaAlbum, tracks) {
    console.log(`🔍 Investigando: ${bandaAlbum}...`);
    try {
        // Buscamos en Wikipedia/DuckDuckGo de forma silenciosa
        const searchUrl = `https://html.duckduckgo.com/html/?q=${encodeURIComponent(bandaAlbum + " band wikipedia")}`;
        const { data } = await axios.get(searchUrl, { headers: { 'User-Agent': 'Mozilla/5.0' } });
        const $ = cheerio.load(data);
        
        // Simulación de extracción de datos (País y Bio corta)
        const snippet = $(".result__snippet").first().text() || "Información en proceso de actualización.";
        const paises = ["Suecia 🇸🇪", "Noruega 🇳🇴", "México 🇲🇽", "EE.UU. 🇺🇸", "Alemania 🇩🇪", "Inglaterra 🏴󠁧󠁢󠁥󠁮󠁧󠁿", "Grecia 🇬🇷", "Brasil 🇧🇷"];
        const paisDetectado = paises.find(p => snippet.toLowerCase().includes(p.split(' ')[0].toLowerCase())) || "Origen Desconocido 🤘";
        
        // Definición de Géneros basada en el nombre (Lógica local)
        const generos = ["Death Metal", "Black Metal", "Heavy Metal", "Thrash", "Nu-Metal", "Hardcore"];
        const generoDetectado = generos.find(g => bandaAlbum.toLowerCase().includes(g.toLowerCase())) || "Metal Extremo";

        return {
            pais: paisDetectado,
            bio: snippet.substring(0, 200) + "...",
            genero: generoDetectado,
            tematica: "{Misticismo y Oscuridad|Historia y Guerra|Crítica Social y Caos|Mitología Antigua}"
        };
    } catch (e) {
        return { pais: "Metalero 🤘", bio: "Una obra brutal de metal puro.", genero: "Metal", tematica: "Poder y Energía" };
    }
}

async function sincronizarDatos(urlGoogle) {
    try {
        const { data } = await axios.get(urlGoogle);
        const enriquecidos = [];
        for (const item of data) {
            const infoExtra = await enriquecerInformacion(item.banda, item.tracks);
            enriquecidos.push({ ...item, ...infoExtra });
            await delay(2000); // Pausa antibaneo entre búsquedas
        }
        fs.writeFileSync(INFO_HOY_PATH, JSON.stringify(enriquecidos));
        console.log("✅ Sincronización y Enriquecimiento completado.");
        return enriquecidos;
    } catch (e) {
        console.log("❌ Error en sincronización: " + e.message);
    }
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
            console.log("\n✅ SISTEMA METAL CONECTADO Y VINCULADO");
            let config = obtenerConfig();

            // CAPTURA DE ID DEL CANAL (Original Blindado)
            if (!config.idCanal) {
                console.log("\n👉 PASO 2: Envía un mensaje a tu CANAL para capturar el ID.");
                sock.ev.on("messages.upsert", async (m) => {
                    const msg = m.messages[0];
                    if (msg.key.remoteJid.endsWith("@newsletter") && !config.idCanal) {
                        const realID = msg.key.remoteJid;
                        console.log(`✅ ID REAL CAPTURADO: ${realID}`);
                        guardarConfig({ idCanal: realID });
                        if (!config.urlGoogle) {
                            const url = await question("\n👉 PASO 3: Pega la URL de tu App Script: ");
                            guardarConfig({ urlGoogle: url.trim() });
                            await sincronizarDatos(url.trim());
                        }
                    }
                });
            }

            // ESCUCHA DE COMANDOS MANUALES (Actualizar)
            sock.ev.on("messages.upsert", async (m) => {
                const msg = m.messages[0];
                const texto = msg.message?.conversation || msg.message?.extendedTextMessage?.text;
                if (texto?.toLowerCase() === "actualizar" && config.urlGoogle) {
                    await sock.sendMessage(msg.key.remoteJid, { text: "⏳ Refrescando noticias y base de datos..." });
                    await sincronizarDatos(config.urlGoogle);
                    await sock.sendMessage(msg.key.remoteJid, { text: "✅ ¡Sincronización completa!" });
                }
            });

            // CRON 10:00 AM (Sincronización Diaria Automática)
            cron.schedule('0 10 * * *', async () => {
                const conf = obtenerConfig();
                if (conf.urlGoogle) await sincronizarDatos(conf.urlGoogle);
            });

            // CICLO DE PUBLICACIÓN CON TYPING Y FORMATO PROFESIONAL
            cron.schedule('* * * * *', async () => {
                if (!fs.existsSync(INFO_HOY_PATH)) return;
                const noticias = JSON.parse(fs.readFileSync(INFO_HOY_PATH));
                const config = obtenerConfig();
                
                const ahora = new Date().toLocaleTimeString('es-MX', { 
                    hour12: false, hour: '2-digit', minute: '2-digit', timeZone: 'America/Mexico_City' 
                });

                for (const item of noticias) {
                    if (item.horario === ahora) {
                        const intro = spintax("{🔥 ¡NUEVO ESTRENO!|🎸 IMPACTO METALERO|🤘 NOVEDAD BRUTAL|🌑 LANZAMIENTO EXCLUSIVO}");
                        const labelBanda = spintax("{📢 Banda:|🎤 Agrupación:|🔥 Proyecto:}");
                        const labelTematica = spintax("{📜 Temática:|💀 Líricas:|🧬 Concepto:}");
                        const emojiVideo = spintax("{🎥|🎬|🎞️|📺}");

                        const cuerpo = `${intro}\n\n` +
                                     `${labelBanda} *${item.banda}*\n` +
                                     `🌍 *Origen:* ${item.pais}\n` +
                                     `🎸 *Género:* ${item.genero}\n\n` +
                                     `📖 *Historia:* ${item.bio}\n` +
                                     `${labelTematica} ${spintax(item.tematica)}\n\n` +
                                     `💿 *Tracks:* _${item.tracks}_\n\n` +
                                     `${emojiVideo} *Video:* ${item.youtube}`;

                        // Simulación Humana: Typing proporcional al largo del texto
                        await sock.sendPresenceUpdate('composing', config.idCanal);
                        await delay(8000); 
                        await sock.sendMessage(config.idCanal, { text: cuerpo });
                        console.log(`🚀 Publicado con formato profesional: ${item.banda}`);
                    }
                }
            });
        }

        if (connection === "close") {
            if (lastDisconnect?.error?.output?.statusCode !== DisconnectReason.loggedOut) iniciar();
        }
    });

    if (!sock.authState.creds.registered) {
        await delay(5000);
        const numero = await question("👉 Introduce tu número (ej: 521...): ");
        const codigo = await sock.requestPairingCode(numero.trim());
        console.log(`\n🔑 CÓDIGO DE VINCULACIÓN: ${codigo}\n`);
    }
}

iniciar();
EOF

node bot_metal.js
