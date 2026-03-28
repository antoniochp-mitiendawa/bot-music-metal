#!/data/data/com.termux/files/usr/bin/bash
termux-wake-lock

# --- INSTALACIÓN COMPLETA PROTEGIDA ---
pkg update -y && pkg upgrade -y
pkg install -y git nodejs-lts python ffmpeg libsqlite openssl wget
mkdir -p datos_ia sesion_bot
npm install @whiskeysockets/baileys pino headline axios node-cron

cat << 'EOF' > bot_metal.js
const { default: makeWASocket, useMultiFileAuthState, delay, fetchLatestBaileysVersion, DisconnectReason, generateWAMessageFromContent, prepareWAMessageMedia } = require("@whiskeysockets/baileys");
const pino = require("pino");
const headline = require("readline");
const axios = require("axios");
const fs = require("fs");
const cron = require("node-cron");

const rl = headline.createInterface({ input: process.stdin, output: process.stdout });
const question = (text) => new Promise((resolve) => rl.question(text, resolve));
const CONFIG_PATH = "./datos_ia/config.json";
const AGENDA_PATH = "./datos_ia/agenda.json";
const MEMORIA_PATH = "./datos_ia/memoria_uso.json";

// --- MOTOR UNIVERSAL DE BANDERAS (ESPAÑOL) ---
const obtenerBandera = (pais) => {
    if (!pais) return "🌍";
    const p = pais.toLowerCase().normalize("NFD").replace(/[\u0300-\u036f]/g, "").trim();
    const banderas = {
        "mexico": "🇲🇽", "usa": "🇺🇸", "eeuu": "🇺🇸", "estados unidos": "🇺🇸", "alemania": "🇩🇪", "germany": "🇩🇪",
        "suecia": "🇸🇪", "sweden": "🇸🇪", "noruega": "🇳🇴", "norway": "🇳🇴", "finlandia": "🇫🇮", "finland": "🇫🇮",
        "rusia": "🇷🇺", "russia": "🇷🇺", "brasil": "🇧🇷", "brazil": "🇧🇷", "reino unido": "🇬🇧", "uk": "🇬🇧",
        "inglaterra": "🏴󠁧󠁢󠁥󠁮󠁧󠁿", "grecia": "🇬🇷", "greece": "🇬🇷", "francia": "🇫🇷", "france": "🇫🇷",
        "italia": "🇮🇹", "italy": "🇮🇹", "espana": "🇪🇸", "spain": "🇪🇸", "canada": "🇨🇦", "australia": "🇦🇺",
        "argentina": "🇦🇷", "chile": "🇨🇱", "colombia": "🇨🇴", "polonia": "🇵🇱", "poland": "🇵🇱", "japon": "🇯🇵",
        "chequia": "🇨🇿", "republica checa": "🇨🇿", "afganistan": "🇦🇫", "panama": "🇵🇦"
    };
    return banderas[p] || "🌐";
};

// --- MEMORIA DE NO REPETICIÓN (SIN TOCAR NÚCLEO) ---
function obtenerVariedad(lista, clave) {
    if (!fs.existsSync(MEMORIA_PATH)) fs.writeFileSync(MEMORIA_PATH, "{}");
    let memoria = JSON.parse(fs.readFileSync(MEMORIA_PATH));
    let ultima = memoria[clave] || "";
    let disponible = lista.filter(item => item !== ultima);
    let elegida = disponible[Math.floor(Math.random() * disponible.length)];
    memoria[clave] = elegida;
    fs.writeFileSync(MEMORIA_PATH, JSON.stringify(memoria));
    return elegida;
}

function obtenerConfig() {
    if (!fs.existsSync(CONFIG_PATH)) return {};
    return JSON.parse(fs.readFileSync(CONFIG_PATH));
}

function guardarConfig(data) {
    const actual = obtenerConfig();
    fs.writeFileSync(CONFIG_PATH, JSON.stringify({ ...actual, ...data }, null, 2));
}

async function sincronizarAgenda(url) {
    if (!url) return;
    try {
        const { data } = await axios.get(url);
        fs.writeFileSync(AGENDA_PATH, JSON.stringify(data, null, 2));
        console.log("✅ Sincronización Exitosa con Google Sheets");
        return data;
    } catch (e) {
        return fs.existsSync(AGENDA_PATH) ? JSON.parse(fs.readFileSync(AGENDA_PATH)) : [];
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
            console.log("\n🤘 SISTEMA METAL CONECTADO Y BLINDADO");
            let config = obtenerConfig();
            
            if (config.idCanal) console.log(`📢 CANAL ACTIVO: ${config.idCanal}`);

            sock.ev.on("messages.upsert", async (m) => {
                const msg = m.messages[0];
                if (!msg.message) return;
                const jid = msg.key.remoteJid;

                // MOSTRAR ID SIEMPRE (RESTAURADO)
                if (jid.endsWith("@newsletter")) {
                    console.log(`🆔 ID DEL CANAL DETECTADO: ${jid}`);
                    if (!config.idCanal) {
                        guardarConfig({ idCanal: jid });
                        console.log("✅ ID Guardado Correctamente.");
                    }
                }
            });

            if (!config.urlGoogle) {
                const url = await question("\n🔗 URL App Script: ");
                guardarConfig({ urlGoogle: url.trim() });
                await sincronizarAgenda(url.trim());
            }

            cron.schedule('0 8 * * *', async () => {
                const conf = obtenerConfig();
                await sincronizarAgenda(conf.urlGoogle);
            });

            cron.schedule('* * * * *', async () => {
                const conf = obtenerConfig();
                if (!fs.existsSync(AGENDA_PATH) || !conf.idCanal) return;

                const agenda = JSON.parse(fs.readFileSync(AGENDA_PATH));
                const ahora = new Date().toLocaleTimeString('es-MX', { 
                    hour12: false, hour: '2-digit', minute: '2-digit', timeZone: 'America/Mexico_City' 
                });

                for (const item of agenda) {
                    if (item.horario === ahora) {
                        console.log(`🚀 Procesando envío para: ${item.banda}`);
                        await sock.sendPresenceUpdate('composing', conf.idCanal);
                        
                        // Lógica de YouTube Protegida
                        const urlYT = item.youtube || "";
                        const videoID = urlYT.includes('v=') ? urlYT.split('v=')[1].split('&')[0] : 
                                      urlYT.includes('youtu.be/') ? urlYT.split('youtu.be/')[1].split('?')[0] : "";
                        
                        if (!videoID) {
                            console.log("❌ Error: No se pudo extraer ID de YouTube para " + item.banda);
                            continue;
                        }

                        const titulos = ["NUEVO ESTRENO", "NOTICIA METALERA", "BRUTAL LANZAMIENTO", "METAL ALERT", "ESTRENO ABSOLUTO"];
                        const etiquetasBanda = ["Banda", "Grupo", "Artista", "Proyecto"];
                        const etiquetasOrigen = ["Origen", "Desde", "Procedencia", "Nacionalidad"];
                        const guiasVideo = ["Mira el video oficial aqui", "Disfruta del estreno en este enlace", "Dale play al nuevo material"];
                        const emojis = ["🤘", "🔥", "🎸", "💀", "⚡", "🥁"];

                        const tituloElegido = obtenerVariedad(titulos, "tit");
                        const bandaElegida = obtenerVariedad(etiquetasBanda, "bnd");
                        const origenElegido = obtenerVariedad(etiquetasOrigen, "ori");
                        const guiaElegida = obtenerVariedad(guiasVideo, "gui");
                        const emo1 = obtenerVariedad(emojis, "e1");
                        const emo2 = obtenerVariedad(emojis, "e2");
                        
                        const bandera = obtenerBandera(item.tracks);
                        const imgUrl = `https://img.youtube.com/vi/${videoID}/maxresdefault.jpg`;

                        const cuerpo = `${emo1} *${tituloElegido}*\n\n\n` +
                                       `👇 *${guiaElegida}:*\n` +
                                       `${item.youtube}\n\n` +
                                       `${emo2} *${bandaElegida}:* ${item.banda}\n` +
                                       `${bandera} *${origenElegido}:* ${item.tracks}`;

                        // ENVÍO DE IMAGEN CON PREVISUALIZACIÓN GRANDE (RESTAURADO)
                        await sock.sendMessage(conf.idCanal, { 
                            image: { url: imgUrl },
                            caption: cuerpo,
                            contextInfo: {
                                externalAdReply: {
                                    title: item.banda,
                                    body: "YouTube Video",
                                    mediaType: 1,
                                    sourceUrl: item.youtube,
                                    thumbnailUrl: imgUrl
                                }
                            }
                        });

                        await delay(5000);
                        await sock.sendPresenceUpdate('paused', conf.idCanal);
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
        console.log(`\n🔑 CÓDIGO DE VINCULACIÓN: ${codigo}\n`);
    }
}
iniciar();
EOF

node bot_metal.js
