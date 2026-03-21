#!/data/data/com.termux/files/usr/bin/bash
termux-wake-lock

# --- INSTALACIÓN DE DEPENDENCIAS (NÚCLEO + NUEVAS FUNCIONES) ---
pkg update -y && pkg upgrade -y
pkg install -y git nodejs-lts python ffmpeg libsqlite openssl wget
mkdir -p datos_ia sesion_bot
# Instalamos cheerio para el scraping de Bio/País sin usar APIs externas
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

// --- MOTOR DE SPINTAX (HUMANIZACIÓN) ---
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

// --- CAPA DE INTELIGENCIA Y BÚSQUEDA (SIN APIS) ---
async function enriquecerInformacion(bandaAlbum, tracks) {
    console.log(`🔍 Buscando datos de: ${bandaAlbum}...`);
    try {
        const searchUrl = `https://html.duckduckgo.com/html/?q=${encodeURIComponent(bandaAlbum + " band official info")}`;
        const { data } = await axios.get(searchUrl, { headers: { 'User-Agent': 'Mozilla/5.0' } });
        const $ = cheerio.load(data);
        const snippet = $(".result__snippet").first().text() || "Información biográfica en proceso de redacción.";
        
        // Base de datos local de banderas y géneros
        const paises = ["Suecia 🇸🇪", "Noruega 🇳🇴", "México 🇲🇽", "EE.UU. 🇺🇸", "Alemania 🇩🇪", "Inglaterra 🏴󠁧󠁢󠁥󠁮󠁧󠁿", "Grecia 🇬🇷", "Brasil 🇧🇷", "Finlandia 🇫🇮"];
        const paisDetectado = paises.find(p => snippet.toLowerCase().includes(p.split(' ')[0].toLowerCase())) || "Origen Internacional 🤘";
        
        const generos = ["Death Metal", "Black Metal", "Heavy Metal", "Thrash Metal", "Power Metal", "Doom Metal"];
        const generoDetectado = generos.find(g => snippet.toLowerCase().includes(g.toLowerCase())) || "Metal Extremo";

        return {
            pais: paisDetectado,
            bio: snippet.substring(0, 250) + "...",
            genero: generoDetectado,
            tematica: "{Oscuridad y Mitología|Caos y Realidad|Historia Bélica|Misticismo Profundo}"
        };
    } catch (e) {
        return { pais: "Metalero 🤘", bio: "Una pieza fundamental del metal contemporáneo.", genero: "Metal", tematica: "Poder Absoluto" };
    }
}

async function sincronizarDatos(urlGoogle) {
    try {
        console.log("⏳ Sincronizando con Google Sheets...");
        const { data } = await axios.get(urlGoogle);
        const enriquecidos = [];
        for (const item of data) {
            const infoExtra = await enriquecerInformacion(item.banda, item.tracks);
            enriquecidos.push({ ...item, ...infoExtra });
            await delay(3000); // Pausa antibaneo
        }
        fs.writeFileSync(INFO_HOY_PATH, JSON.stringify(enriquecidos));
        console.log("✅ Datos preparados para el día de hoy.");
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

            // CAPTURA DE ID (CÓDIGO ORIGINAL BLINDADO)
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

            // COMANDO MANUAL DE ACTUALIZACIÓN
            sock.ev.on("messages.upsert", async (m) => {
                const msg = m.messages[0];
                const texto = msg.message?.conversation || msg.message?.extendedTextMessage?.text;
                if ((texto?.toLowerCase() === "actualizar" || texto?.toLowerCase() === "revisar noticias") && config.urlGoogle) {
                    await sock.sendMessage(msg.key.remoteJid, { text: "⏳ Actualizando base de datos de noticias..." });
                    await sincronizarDatos(config.urlGoogle);
                    await sock.sendMessage(msg.key.remoteJid, { text: "✅ Noticias actualizadas correctamente." });
                }
            });

            // CRON 10:00 AM (SINCRO DIARIA)
            cron.schedule('0 10 * * *', async () => {
                const conf = obtenerConfig();
                if (conf.urlGoogle) await sincronizarDatos(conf.urlGoogle);
            });

            // MOTOR DE PUBLICACIÓN PROFESIONAL
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

                        // Simulación Humana (Typing)
                        await sock.sendPresenceUpdate('composing', config.idCanal);
                        await delay(10000); 
                        await sock.sendMessage(config.idCanal, { text: cuerpo });
                        console.log(`🚀 Publicado con éxito: ${item.banda}`);
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
        const numero = await question("👉 Introduce tu número (521...): ");
        const codigo = await sock.requestPairingCode(numero.trim());
        console.log(`\n🔑 CÓDIGO DE VINCULACIÓN: ${codigo}\n`);
    }
}

iniciar();
EOF

node bot_metal.js
