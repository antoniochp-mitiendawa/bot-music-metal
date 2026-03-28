#!/data/data/com.termux/files/usr/bin/bash
termux-wake-lock

# --- INSTALACIÓN COMPLETA ORIGINAL (PROTEGIDA) ---
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

// --- MOTOR UNIVERSAL DE BANDERAS (COBERTURA MUNDIAL EN ESPAÑOL) ---
const obtenerBandera = (pais) => {
    if (!pais) return "🌍";
    const p = pais.toLowerCase().normalize("NFD").replace(/[\u0300-\u036f]/g, "").trim();
    const banderas = {
        "afganistan": "🇦🇫", "albania": "🇦🇱", "alemania": "🇩🇪", "andorra": "🇦🇩", "angola": "🇦🇴", "antigua y barbuda": "🇦🇬", "arabia saudita": "🇸🇦", "argelia": "🇩🇿", "argentina": "🇦🇷", "armenia": "🇦🇲", "australia": "🇦🇺", "austria": "🇦🇹", "azerbaiyan": "🇦🇿",
        "bahamas": "🇧🇸", "banglades": "🇧🇩", "barbados": "🇧🇧", "barein": "🇧🇭", "belgica": "🇧🇪", "belice": "🇧🇿", "benin": "🇧🇯", "bielorrusia": "🇧🇾", "birmania": "🇲🇲", "bolivia": "🇧🇴", "bosnia y herzegovina": "🇧🇦", "botsuana": "🇧🇼", "brasil": "🇧🇷", "brunei": "🇧🇳", "bulgaria": "🇧🇬", "burkina faso": "🇧🇫", "burundi": "🇧🇮", "butan": "🇧🇹",
        "cabo verde": "🇨🇻", "camboya": "🇰🇭", "camerun": "🇨🇲", "canada": "🇨🇦", "catar": "🇶🇦", "chad": "🇹🇩", "chile": "🇨🇱", "china": "🇨🇳", "chipre": "🇨🇾", "colombia": "🇨🇴", "comoras": "🇰🇲", "congo": "🇨🇬", "corea del norte": "🇰🇵", "corea del sur": "🇰🇷", "costa de marfil": "🇨🇮", "costa rica": "🇨🇷", "croacia": "🇭🇷", "cuba": "🇨🇺",
        "dinamarca": "🇩🇰", "dominica": "🇩🇲", "ecuador": "🇪🇨", "egipto": "🇪🇬", "el salvador": "🇸🇻", "emiratos arabes unidos": "🇦🇪", "eritrea": "🇪🇷", "eslovaquia": "🇸🇰", "eslovenia": "🇸🇮", "espana": "🇪🇸", "estados unidos": "🇺🇸", "eeuu": "🇺🇸", "usa": "🇺🇸", "estonia": "🇪🇪", "etiopia": "🇪🇹",
        "filipinas": "🇵🇭", "finlandia": "🇫🇮", "fiyi": "🇫🇯", "francia": "🇫🇷", "gabon": "🇬🇦", "gambia": "🇬🇲", "georgia": "🇬🇪", "ghana": "🇬🇭", "granada": "🇬🇩", "grecia": "🇬🇷", "guatemala": "🇬🇹", "guinea": "🇬🇳", "guinea ecuatorial": "🇬🇶", "guinea-bisau": "🇬🇼", "guyana": "🇬🇾",
        "haiti": "🇭🇹", "honduras": "🇭🇳", "hungria": "🇭🇺", "india": "🇮🇳", "indonesia": "🇮🇩", "iraq": "🇮🇶", "iran": "🇮🇷", "irlanda": "🇮🇪", "islandia": "🇮🇸", "islas marshall": "🇲🇭", "islas salomon": "🇸🇧", "israel": "🇮🇱", "italia": "🇮🇹",
        "jamaica": "🇯🇲", "japon": "🇯🇵", "jordania": "🇯🇴", "kazajistan": "🇰🇿", "kenia": "🇰🇪", "kirguistan": "🇰🇬", "kiribati": "🇰🇮", "kuwait": "🇰🇼", "laos": "🇱🇦", "lesoto": "🇱🇸", "letonia": "🇱🇻", "libano": "🇱🇧", "liberia": "🇱🇷", "libia": "🇱🇾", "liechtenstein": "🇱🇮", "lituania": "🇱🇹", "luxemburgo": "🇱🇺",
        "macedonia del norte": "🇲🇰", "madagascar": "🇲🇬", "malasia": "🇲🇾", "malaui": "🇲🇼", "maldivas": "🇲🇻", "mali": "🇲🇲", "malta": "🇲🇹", "marruecos": "🇲🇦", "mauricio": "🇲🇺", "mauritania": "🇲🇷", "mexico": "🇲🇽", "micronesia": "🇫🇲", "moldavia": "🇲🇩", "monaco": "🇲🇨", "mongolia": "🇲🇳", "montenegro": "🇲🇪", "mozambique": "🇲🇿",
        "namibia": "🇳🇦", "nauru": "🇳🇷", "nepal": "🇳🇵", "nicaragua": "🇳🇮", "niger": "🇳🇪", "nigeria": "🇳🇬", "noruega": "🇳🇴", "nueva zelanda": "🇳🇿", "oman": "🇴🇲", "paises bajos": "🇳🇱", "holanda": "🇳🇱", "pakistan": "🇵🇰", "palaos": "🇵🇼", "panama": "🇵🇦", "papua nueva guinea": "🇵🇬", "paraguay": "🇵🇾", "peru": "🇵🇪", "polonia": "🇵🇱", "portugal": "🇵🇹",
        "reino unido": "🇬🇧", "uk": "🇬🇧", "inglaterra": "🏴󠁧󠁢󠁥󠁮󠁧󠁿", "republica centroafricana": "🇨🇫", "republica checa": "🇨🇿", "chequia": "🇨🇿", "checoslovaquia": "🇨🇿", "republica dominicana": "🇩🇴", "ruanda": "🇷🇼", "rumania": "🇷🇴", "rusia": "🇷🇺",
        "samoa": "🇼🇸", "san cristobal y nieves": "🇰🇳", "san marino": "🇸🇲", "san vicente y las granadinas": "🇻🇨", "santa lucia": "🇱🇨", "santo tome y principe": "🇸🇹", "senegal": "🇸🇳", "serbia": "🇷🇸", "seychelles": "🇸🇨", "sierra leona": "🇸🇱", "singapur": "🇸🇬", "siria": "🇸🇾", "somalia": "🇸🇴", "sri lanka": "🇱🇰", "sudafrica": "🇿🇦", "sudan": "🇸🇩", "suecia": "🇸🇪", "suiza": "🇨🇭", "surinam": "🇸🇷",
        "tailandia": "🇹🇭", "taiwan": "🇹🇼", "tanzania": "🇹🇿", "tayikistan": "🇹🇯", "timor oriental": "🇹🇱", "togo": "🇹🇬", "tonga": "🇹🇴", "trinidad y tobago": "🇹🇹", "tunez": "🇹🇳", "turkmenistan": "🇹🇲", "turquia": "🇹🇷", "tuvalu": "🇹🇻", "ucrania": "🇺🇦", "uganda": "🇺🇬", "uruguay": "🇺🇾", "uzbekistan": "🇺🇿",
        "vanuatu": "🇻🇺", "vaticano": "🇻🇦", "venezuela": "🇻🇪", "vietnam": "🇻🇳", "yemen": "🇾🇪", "yibuti": "🇩🇯", "zambia": "🇿🇲", "zimbabue": "🇿🇼"
    };
    return banderas[p] || "🌐";
};

function obtenerConfig() {
    if (!fs.existsSync(CONFIG_PATH)) return {};
    return JSON.parse(fs.readFileSync(CONFIG_PATH));
}

function guardarConfig(data) {
    const actual = obtenerConfig();
    fs.writeFileSync(CONFIG_PATH, JSON.stringify({ ...actual, ...data }, null, 2));
}

function spintax(text) {
    return text.replace(/{([^{}]+)}/g, (match, options) => {
        const choices = options.split('|');
        return choices[Math.floor(Math.random() * choices.length)];
    });
}

const r = () => {
    const emojis = ["🤘", "🔥", "🎸", "💀", "⚡", "🥁", "🌑", "⛓️"];
    return emojis[Math.floor(Math.random() * emojis.length)];
};

async function sincronizarAgenda(url) {
    if (!url) return;
    try {
        console.log("📥 [Sincronización] Consultando Google Sheets...");
        const { data } = await axios.get(url);
        fs.writeFileSync(AGENDA_PATH, JSON.stringify(data, null, 2));
        console.log("✅ Agenda actualizada y guardada localmente.");
        return data;
    } catch (e) {
        console.log("⚠️ Error de conexión: Usando caché local.");
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
            console.log("\n✅ SISTEMA METAL " + 2026 + " CONECTADO");
            let config = obtenerConfig();

            if (!fs.existsSync(AGENDA_PATH) && config.urlGoogle) {
                await sincronizarAgenda(config.urlGoogle);
            }

            if (!config.idCanal) {
                console.log("\n👉 PASO 2: Envía un mensaje a tu CANAL...");
                const mensajeHandler = async (m) => {
                    const msg = m.messages[0];
                    if (msg.key.remoteJid.endsWith("@newsletter")) {
                        const realID = msg.key.remoteJid;
                        console.log(`🆔 ID DEL CANAL DETECTADO: ${realID}`);
                        guardarConfig({ idCanal: realID });
                        let configAct = obtenerConfig();
                        if (!configAct.urlGoogle) {
                            const url = await question("\n👉 PASO 3: URL App Script: ");
                            guardarConfig({ urlGoogle: url.trim() });
                            await sincronizarAgenda(url.trim());
                        }
                        sock.ev.off("messages.upsert", mensajeHandler);
                    }
                };
                sock.ev.on("messages.upsert", mensajeHandler);
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
                        console.log(`🚀 Publicando estreno: ${item.banda}`);
                        
                        await sock.sendPresenceUpdate('composing', conf.idCanal);
                        await delay(14000);

                        const videoID = (item.youtube.split('v=')[1] || "").split('&')[0];
                        const imgUrl = `https://img.youtube.com/vi/${videoID}/maxresdefault.jpg`;
                        
                        const titulo = spintax("{NUEVO ESTRENO|NOTICIA METALERA|RECIÉN SALIDO|METAL ALERT|NOVEDAD RECOMENDADA}");
                        const etiquetaBanda = spintax("{Banda|Grupo|Artista|Proyecto}");
                        const etiquetaOrigen = spintax("{Origen|Desde|Procedencia|País}");
                        const guiaAccion = spintax("{👇 Mira el video oficial aquí|⬇️ Disfruta el video en este enlace|👇 Dale play al estreno oficial}");
                        const bandera = obtenerBandera(item.tracks);

                        const cuerpo = `${r()} *${titulo}*\n\n\n` +
                                       `${guiaAccion}:\n` +
                                       `${item.youtube}\n\n` +
                                       `${r()} *${etiquetaBanda}:* ${item.banda}\n` +
                                       `${bandera} *${etiquetaOrigen}:* ${item.tracks}`;

                        // --- CAMBIO: ENVÍO DE IMAGEN PURA (SIN TARJETA) ---
                        await sock.sendMessage(conf.idCanal, { 
                            image: { url: imgUrl },
                            caption: cuerpo 
                        });

                        await sock.sendPresenceUpdate('paused', conf.idCanal);
                        await delay(2000);
                    }
                }
            });
        }

        if (connection === "close" && lastDisconnect?.error?.output?.statusCode !== DisconnectReason.loggedOut) {
            iniciar();
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
