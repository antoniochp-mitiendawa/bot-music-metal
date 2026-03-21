#!/data/data/com.termux/files/usr/bin/bash
termux-wake-lock

# --- INSTALACIÓN COMPLETA ---
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

function obtenerConfig() {
    if (!fs.existsSync(CONFIG_PATH)) return {};
    return JSON.parse(fs.readFileSync(CONFIG_PATH));
}

function guardarConfig(data) {
    const actual = obtenerConfig();
    fs.writeFileSync(CONFIG_PATH, JSON.stringify({ ...actual, ...data }));
}

// Spintax
function spintax(texto) {
    const regex = /\{([^{}]+)\}/g;
    return texto.replace(regex, (match, grupo) => {
        const opciones = grupo.split('|');
        return opciones[Math.floor(Math.random() * opciones.length)];
    });
}

// Generar mensaje
function generarMensaje(item, info) {
    const titulos = ["{🔥 ¡NUEVO ESTRENO! 🤘|⚡ ATENCIÓN METALEROS ⚡|🤘 LANZAMIENTO DESTACADO 🤘|🎸 NOVEDAD METAL 🎸}"];
    const bandaFormat = ["{📢 *Banda:*|🎸 *Artista:*|🤘 *Agrupación:*}"];
    const origenFormat = ["{📍 *Origen:*|🌍 *Procedencia:*|🏠 *De:*}"];
    const generoFormat = ["{🎭 *Género:*|🎸 *Estilo:*|🔊 *Género:*}"];
    const bioFormat = ["{📖 *Biografía:*|🔍 *Sobre la banda:*|📜 *Historia:*}"];
    const videoFormat = ["{🎥 *Video:*|▶️ *Escúchalo:*|🔗 *Mira el video:*}"];
    
    let msg = `${spintax(titulos)}\n\n`;
    msg += `${spintax(bandaFormat)} ${item.banda}\n`;
    if (info.pais) msg += `${spintax(origenFormat)} ${info.pais}\n`;
    if (info.genero) msg += `${spintax(generoFormat)} ${info.genero}\n`;
    if (info.biografia) msg += `\n${spintax(bioFormat)}\n${info.biografia}\n`;
    msg += `\n${spintax(videoFormat)} ${item.youtube}`;
    return msg;
}

// Buscar en Wikipedia
async function buscarWikipedia(bandaNombre) {
    try {
        const busqueda = encodeURIComponent(bandaNombre);
        const res = await axios.get(`https://es.wikipedia.org/api/rest_v1/page/summary/${busqueda}`, { timeout: 8000 });
        if (res.data && res.data.extract) {
            const texto = res.data.extract;
            let pais = "", genero = "";
            const paises = ["México","Argentina","España","Chile","Colombia","Perú","Brasil","Alemania","Suecia","Noruega","Finlandia","Estados Unidos","Reino Unido","Grecia","Italia","Francia","Canadá","Australia","Japón"];
            const generos = ["Death Metal","Black Metal","Thrash Metal","Heavy Metal","Power Metal","Doom Metal","Symphonic Metal","Folk Metal","Gothic Metal","Progressive Metal","Metal","Rock"];
            for (const p of paises) if (texto.includes(p)) { pais = p; break; }
            for (const g of generos) if (texto.includes(g)) { genero = g; break; }
            const biografia = texto.length > 400 ? texto.substring(0,400)+"..." : texto;
            if (pais || genero || biografia) return { pais, genero, biografia };
        }
        return null;
    } catch(e) { return null; }
}

// Buscar en DuckDuckGo
async function buscarDuckDuckGo(bandaNombre) {
    try {
        const busqueda = encodeURIComponent(`${bandaNombre} biografía género país`);
        const res = await axios.get(`https://api.duckduckgo.com/?q=${busqueda}&format=json&no_html=1&skip_disambig=1`, { timeout: 8000 });
        if (res.data && res.data.Abstract) {
            const texto = res.data.Abstract;
            let pais = "", genero = "";
            const paises = ["México","Argentina","España","Chile","Colombia","Perú","Brasil","Alemania","Suecia","Noruega","Finlandia","Estados Unidos","Reino Unido","Grecia","Italia","Francia","Canadá","Australia","Japón"];
            const generos = ["Death Metal","Black Metal","Thrash Metal","Heavy Metal","Power Metal","Doom Metal","Symphonic Metal","Folk Metal","Gothic Metal","Progressive Metal","Metal","Rock"];
            for (const p of paises) if (texto.includes(p)) { pais = p; break; }
            for (const g of generos) if (texto.includes(g)) { genero = g; break; }
            const biografia = texto.length > 400 ? texto.substring(0,400)+"..." : texto;
            if (pais || genero || biografia) return { pais, genero, biografia };
        }
        return null;
    } catch(e) { return null; }
}

async function enriquecerBanda(bandaNombre) {
    console.log(`🔍 Buscando: ${bandaNombre}`);
    let info = await buscarWikipedia(bandaNombre);
    if (info) return info;
    info = await buscarDuckDuckGo(bandaNombre);
    if (info) return info;
    console.log(`⚠️ No se encontró info para: ${bandaNombre}`);
    return null;
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

    // PRIMERO: Si no está vinculado, pedir número y mostrar código
    if (!state.creds.registered) {
        await delay(5000);
        const numero = await question("👉 Introduce tu número (con código de país, ej: 521...): ");
        const codigo = await sock.requestPairingCode(numero.trim());
        console.log(`\n🔑 CÓDIGO DE VINCULACIÓN: ${codigo}\n`);
    }

    sock.ev.on("connection.update", async (up) => {
        const { connection, lastDisconnect } = up;

        if (connection === "open") {
            console.log("\n✅ SISTEMA METAL CONECTADO Y VINCULADO");
            let config = obtenerConfig();

            // SEGUNDO: Capturar ID del canal si no existe
            if (!config.idCanal) {
                console.log("\n👉 Envía un mensaje a tu CANAL para capturar el ID.");
                sock.ev.on("messages.upsert", async (m) => {
                    const msg = m.messages[0];
                    if (msg.key.remoteJid.endsWith("@newsletter") && !config.idCanal) {
                        const realID = msg.key.remoteJid;
                        console.log(`✅ ID REAL CAPTURADO: ${realID}`);
                        guardarConfig({ idCanal: realID });
                        
                        // TERCERO: Pedir URL de Google Sheets
                        if (!config.urlGoogle) {
                            const url = await question("\n👉 Pega la URL de tu App Script: ");
                            guardarConfig({ urlGoogle: url.trim() });
                            console.log("✅ Configuración guardada. El bot ya está activo.");
                        }
                    }
                });
            }

            // CUARTO: Iniciar ciclo de publicación
            cron.schedule('* * * * *', async () => {
                const conf = obtenerConfig();
                if (!conf.urlGoogle || !conf.idCanal) return;

                try {
                    const { data } = await axios.get(conf.urlGoogle);
                    const ahora = new Date().toLocaleTimeString('es-MX', { 
                        hour12: false, hour: '2-digit', minute: '2-digit', timeZone: 'America/Mexico_City' 
                    });

                    for (const item of data) {
                        if (item.horario === ahora) {
                            console.log(`🚀 Publicando: ${item.banda}`);
                            const bandaNombre = item.banda.split(" - ")[0];
                            const info = await enriquecerBanda(bandaNombre);
                            const cuerpo = generarMensaje(item, info || {});
                            await sock.sendMessage(conf.idCanal, { text: cuerpo });
                        }
                    }
                } catch (e) {
                    console.log("Error: " + e.message);
                }
            });
        }

        if (connection === "close") {
            if (lastDisconnect?.error?.output?.statusCode !== DisconnectReason.loggedOut) {
                iniciar();
            }
        }
    });
}

iniciar();
EOF

node bot_metal.js
