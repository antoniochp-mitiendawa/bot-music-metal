#!/data/data/com.termux/files/usr/bin/bash
termux-wake-lock

# --- INSTALACIÓN DE DEPENDENCIAS ---
pkg update -y && pkg upgrade -y
pkg install -y git nodejs-lts python ffmpeg libsqlite openssl wget
mkdir -p datos_ia sesion_bot
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

// --- MOTOR DE BÚSQUEDA MEJORADO (FILTRO DE PAÍS Y GÉNERO REAL) ---
async function enriquecerInformacion(bandaAlbum) {
    console.log(`🔍 Investigando a fondo: ${bandaAlbum}...`);
    try {
        // Forzamos búsqueda en español y términos específicos de Rock/Metal
        const query = encodeURIComponent(`${bandaAlbum} banda origen género historia español`);
        const { data } = await axios.get(`https://html.duckduckgo.com/html/?q=${query}`, { 
            headers: { 'User-Agent': 'Mozilla/5.0' } 
        });
        const $ = cheerio.load(data);
        const snippet = $(".result__snippet").first().text().toLowerCase() || "";

        // Lógica de detección de País (Prioridad EE.UU. para Britny Fox/Hard Rock)
        let pais = "Origen Internacional 🤘";
        if (snippet.includes("ee.uu") || snippet.includes("usa") || snippet.includes("pennsylvania") || snippet.includes("filadelfia")) pais = "Estados Unidos 🇺🇸";
        else if (snippet.includes("suecia") || snippet.includes("sweden")) pais = "Suecia 🇸🇪";
        else if (snippet.includes("reino unido") || snippet.includes("uk")) pais = "Reino Unido 🇬🇧";

        // Lógica de Género (Prioridad Hard Rock/Glam si detecta términos clave)
        let genero = "Metal Extremo";
        if (snippet.includes("hard rock") || snippet.includes("glam") || snippet.includes("heavy rock")) genero = "Hard Rock / Glam Metal";
        else if (snippet.includes("death")) genero = "Death Metal";
        else if (snippet.includes("black")) genero = "Black Metal";

        return {
            pais,
            genero,
            bio: snippet.substring(0, 250) + "...",
            tematica: "{Hard Rock Life y Energía|Glamour y Poder|Leyendas del Rock|Resiliencia Musical}"
        };
    } catch (e) {
        return { pais: "EE.UU. 🇺🇸", genero: "Hard Rock", bio: "Banda legendaria de la escena Rock.", tematica: "Rock n' Roll" };
    }
}

async function sincronizarDatos(urlGoogle) {
    try {
        const { data } = await axios.get(urlGoogle);
        const enriquecidos = [];
        for (const item of data) {
            const infoExtra = await enriquecerInformacion(item.banda);
            enriquecidos.push({ ...item, ...infoExtra });
            await delay(2000); 
        }
        fs.writeFileSync(INFO_HOY_PATH, JSON.stringify(enriquecidos));
        return enriquecidos;
    } catch (e) { console.log("Error sincro: " + e.message); }
}

async function iniciar() {
    const { state, saveCreds } = await useMultiFileAuthState('sesion_bot');
    const { version } = await fetchLatestBaileysVersion();
    const sock = makeWASocket({ version, logger: pino({ level: "silent" }), auth: state, printQRInTerminal: false, browser: ["Ubuntu", "Chrome", "20.0.04"] });

    sock.ev.on("creds.update", saveCreds);
    sock.ev.on("connection.update", async (up) => {
        const { connection, lastDisconnect } = up;

        if (connection === "open") {
            console.log("\n✅ SISTEMA METAL CONECTADO Y VINCULADO");
            let config = obtenerConfig();

            // --- SOLUCIÓN AL BUCLE: BLOQUEO SI YA EXISTE CONFIG ---
            if (!config.idCanal || !config.urlGoogle) {
                console.log("\n👉 CONFIGURACIÓN INICIAL REQUERIDA...");
                sock.ev.on("messages.upsert", async (m) => {
                    const msg = m.messages[0];
                    if (!config.idCanal && msg.key.remoteJid.endsWith("@newsletter")) {
                        const realID = msg.key.remoteJid;
                        console.log(`✅ ID CAPTURADO: ${realID}`);
                        guardarConfig({ idCanal: realID });
                        config = obtenerConfig(); // Actualizar variable local
                        
                        if (!config.urlGoogle) {
                            const url = await question("\n👉 PASTE APP SCRIPT URL: ");
                            guardarConfig({ urlGoogle: url.trim() });
                            const datos = await sincronizarDatos(url.trim());
                            
                            // --- MENSAJE DE PRUEBA INMEDIATO ---
                            console.log("🚀 Enviando mensaje de prueba...");
                            const prueba = datos[0];
                            const cuerpoPrueba = `🧪 *PRUEBA DE INSTALACIÓN*\n\n*Banda:* ${prueba.banda}\n*País:* ${prueba.pais}\n*Género:* ${prueba.genero}\n\n*Bio:* ${prueba.bio}\n\n*Tracks:* _${prueba.tracks}_`;
                            await sock.sendMessage(realID, { text: cuerpoPrueba });
                        }
                    }
                });
            } else {
                console.log("🛡️ Blindaje activo: Configuración cargada. Ignorando nuevos IDs.");
            }

            // COMANDO ACTUALIZAR
            sock.ev.on("messages.upsert", async (m) => {
                const msg = m.messages[0];
                const texto = msg.message?.conversation || "";
                if (texto.toLowerCase() === "actualizar" && config.urlGoogle) {
                    await sincronizarDatos(config.urlGoogle);
                    await sock.sendMessage(msg.key.remoteJid, { text: "✅ Sincronización manual exitosa." });
                }
            });

            // CRONÓMETRO DE PUBLICACIÓN
            cron.schedule('* * * * *', async () => {
                if (!fs.existsSync(INFO_HOY_PATH)) return;
                const noticias = JSON.parse(fs.readFileSync(INFO_HOY_PATH));
                const conf = obtenerConfig();
                const ahora = new Date().toLocaleTimeString('es-MX', { hour12: false, hour: '2-digit', minute: '2-digit', timeZone: 'America/Mexico_City' });

                for (const item of noticias) {
                    if (item.horario === ahora) {
                        const cuerpo = `${spintax("{🔥 ¡ESTRENO!|🎸 NOVEDAD}")}\n\n` +
                                     `🎤 *${item.banda}*\n🌍 *Origen:* ${item.pais}\n🎸 *Género:* ${item.genero}\n\n` +
                                     `📖 *Bio:* ${item.bio}\n📜 *Temática:* ${spintax(item.tematica)}\n\n` +
                                     `💿 *Tracks:* _${item.tracks}_\n\n${spintax("{🎥|🎬}")} *Video:* ${item.youtube}`;

                        await sock.sendPresenceUpdate('composing', conf.idCanal);
                        await delay(7000);
                        await sock.sendMessage(conf.idCanal, { text: cuerpo });
                    }
                }
            });
        }
        if (connection === "close" && lastDisconnect?.error?.output?.statusCode !== DisconnectReason.loggedOut) iniciar();
    });

    if (!sock.authState.creds.registered) {
        await delay(5000);
        const numero = await question("👉 Introduce tu número (521...): ");
        const codigo = await sock.requestPairingCode(numero.trim());
        console.log(`\n🔑 CÓDIGO: ${codigo}\n`);
    }
}
iniciar();
EOF

node bot_metal.js
