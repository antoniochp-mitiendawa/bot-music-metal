#!/data/data/com.termux/files/usr/bin/bash
termux-wake-lock

# --- CHECKPOINTS DE INSTALACIÓN ---
# --- CHECKPOINTS (PROHIBIDO MODIFICAR)  ---
# --- CHECKPOINTS (MANTENIDOS) ---
PASO1_BASE=".sistema_base_ok"
PASO2_MOTOR=".motor_ia_ok"

if [ ! -f "$PASO1_BASE" ]; then
    pkg update -y -o Dpkg::Options::="--force-confold"
    pkg upgrade -y -o Dpkg::Options::="--force-confold"
    pkg install -y git openssl wget
    touch "$PASO1_BASE"
fi
@@ -14,7 +14,7 @@ fi

if [ ! -f "$PASO2_MOTOR" ]; then
    pkg install -y nodejs-lts python ffmpeg libsqlite
pkg install -y nodejs-lts python ffmpeg libsqlite
mkdir -p datos_ia sesion_bot
    npm install @whiskeysockets/baileys pino readline axios cheerio node-cron
    touch "$PASO2_MOTOR"
    mkdir -p datos_ia sesion_bot temp_media
npm install @whiskeysockets/baileys pino readline axios cheerio node-cron
touch "$PASO2_MOTOR"
fi

cat << 'EOF' > bot_metal.js
const { default: makeWASocket, useMultiFileAuthState, delay, fetchLatestBaileysVersion, DisconnectReason } = require("@whiskeysockets/baileys");
@@ -24,14 +24,31 @@ const { default: makeWASocket, useMultiFileAuthState, delay, fetchLatestBaileysV
const pino = require("pino");
const readline = require("readline");
const axios = require("axios");
const cheerio = require("cheerio");
const fs = require("fs");
const cron = require("node-cron");

const rl = readline.createInterface({ input: process.stdin, output: process.stdout });
const question = (text) => new Promise((resolve) => rl.question(text, resolve));

const CONFIG_PATH = "./datos_ia/config.json";
const LOCAL_DB = "./datos_ia/agenda_dia.json";

const banderas = {
    "Grecia": "🇬🇷", "Sweden": "🇸🇪", "Norway": "🇳🇴", "Germany": "🇩🇪", "USA": "🇺🇸", "Mexico": "🇲🇽", "Finland": "🇫🇮", "Brazil": "🇧🇷", "Poland": "🇵🇱"
// --- DICCIONARIOS LOCALES (SPINTAX) ---
const spintax = {
    intro: ["🔥 ¡BRUTAL ESTRENO!", "🤘 NOVEDAD METALERA", "⚡ RECIÉN DESENTERRADO", "🎸 IMPACTO TOTAL"],
    bio_label: ["📜 La historia:", "📖 Biografía:", "🔍 Tras la banda:", "📄 Contexto:"],
    cierre: ["🔥 ¡Escúchalo ahora!", "🤘 No te lo pierdas:", "🎸 Dale play aquí:", "💀 Metal or Die:"]
};

const spintax = {
    intro: ["🔥 *¡ALERTA DE ESTRENO!*", "🤘 *NOVEDAD BRUTAL*", "⚡ *IMPACTO METALERO*"],
    bio_label: ["📜 *Trasfondo:*", "📖 *La Historia:*", "🔍 *Análisis:*"],
    tracks_label: ["💿 *Setlist del Álbum:*", "🎶 *Tracks Destacados:*"],
    link_label: ["🎥 *Video Oficial:*", "🔗 *Mira el video aquí:*"]
const getSpintax = (tipo) => spintax[tipo][Math.floor(Math.random() * spintax[tipo].length)];

// --- MAPEO DE BANDERAS ---
const banderas = {
    "Greece": "🇬🇷", "Grecia": "🇬🇷", "Sweden": "🇸🇪", "Suecia": "🇸🇪", "Norway": "🇳🇴", "Noruega": "🇳🇴",
    "USA": "🇺🇸", "EEUU": "🇺🇸", "Germany": "🇩🇪", "Alemania": "🇩🇪", "Canada": "🇨🇦", "Australia": "🇦🇺"
};
const getSpin = (t) => spintax[t][Math.floor(Math.random() * spintax[t].length)];

function obtenerConfig() { 
    if (!fs.existsSync(CONFIG_PATH)) return {};
    try { return JSON.parse(fs.readFileSync(CONFIG_PATH)); } catch { return {}; }
   if (!fs.existsSync(CONFIG_PATH)) return {};
   try { return JSON.parse(fs.readFileSync(CONFIG_PATH)); } catch { return {}; }
@@ -45,11 +62,30 @@ function limpiarHorario(dato) {
   return `${h.padStart(2, '0')}:${m.padStart(2, '0')}`;
}
function guardarConfig(data) { fs.writeFileSync(CONFIG_PATH, JSON.stringify({ ...obtenerConfig(), ...data })); }

function limpiarHorario(dato) {
    const match = String(dato).match(/(\d{1,2}:\d{2})/);
    if (!match) return null;
    let [h, m] = match[1].split(':');
    return `${h.padStart(2, '0')}:${m.padStart(2, '0')}`;
// --- INVESTIGACIÓN AUTOMÁTICA (SCRAPING GRATUITO) ---
async function investigarBandaPro(noticia) {
    const db = { "Septicflesh": { p: "Grecia 🇬🇷", h: "Pioneros del Death Sinfónico." }, "Rotting Christ": { p: "Grecia 🇬🇷", h: "Leyendas del Dark Metal." } };
    const nombre = noticia.banda ? noticia.banda.split(" - ")[0] : "Banda";
    const info = db[nombre] || { p: "Origen Confirmado 🌎", h: "Lanzamiento 2026." };
    return { ...info, tracks: noticia.tracks ? `\n\n💿 *Tracks:*\n${noticia.tracks}` : "" };
    const query = noticia.banda.split(" - ")[0];
    let origen = "Origen desconocido 🌎";
    let historia = "Nueva fuerza del metal emergente.";
    let bandera = "🤘";

    try {
        // Intento en Metal Archives (Búsqueda simple)
        const searchUrl = `https://www.metal-archives.com/search?searchString=${encodeURIComponent(query)}&type=band_name`;
        const { data } = await axios.get(searchUrl, { timeout: 5000 });
        const $ = cheerio.load(data);
        
        // Si hay resultados, extraemos país (Este es un ejemplo de lógica de scraping)
        const countryFound = $("table tr:first-child td:nth-child(2)").text().trim();
        if (countryFound) {
            origen = countryFound;
            bandera = banderas[countryFound] || "🌎";
        }
    } catch (e) {
        console.log("⚠️ Búsqueda externa fallida, usando datos básicos.");
    }

    return { p: `${origen} ${bandera}`, h: historia };
}

async function sincronizarConGoogle() {
    const config = obtenerConfig();
    if (!config.urlGoogle) return [];
    try {
        const { data } = await axios.get(config.urlGoogle);
        const agenda = data.map(i => ({ ...i, horarioLimpio: limpiarHorario(i.horario) })).filter(i => i.banda && i.horarioLimpio);
        fs.writeFileSync(LOCAL_DB, JSON.stringify(agenda));
        console.log(`📅 Sincronizado: ${agenda.length} bandas.`);
        return agenda;
    } catch (e) { return fs.existsSync(LOCAL_DB) ? JSON.parse(fs.readFileSync(LOCAL_DB)) : []; }
@@ -59,63 +95,85 @@ async function sincronizarConGoogle() {
       const { data } = await axios.get(config.urlGoogle);
       const agenda = data.map(i => ({ ...i, horarioLimpio: limpiarHorario(i.horario) })).filter(i => i.banda && i.horarioLimpio);
       fs.writeFileSync(LOCAL_DB, JSON.stringify(agenda));
        console.log(`📅 Agenda: ${agenda.length} bandas listas.`);
        console.log(`📅 Agenda: ${agenda.length} noticias listas.`);
       return agenda;
   } catch (e) { return fs.existsSync(LOCAL_DB) ? JSON.parse(fs.readFileSync(LOCAL_DB)) : []; }
}

async function dispararPublicacion(sock, noticia, esPrueba = false) {
    const config = obtenerConfig();
    if (!config.idCanal) return;
   const config = obtenerConfig();
   if (!config.idCanal) return;

    console.log(`⏳ [Canal] Preparando publicación: ${noticia.banda}...`);
    
    // RESTAURADO: Simulación de escritura prolongada (vital para canales)
    // 1. Simular "Escribiendo..."
await sock.sendPresenceUpdate('composing', config.idCanal);
    await delay(esPrueba ? 5000 : 15000); 

    const emojiPais = banderas[noticia.pais] || "🌎";
    const msg = `${getSpin('intro')}\n\n` +
                `📢 *Banda:* _${noticia.banda}_\n` +
                `🎸 *Género:* ${noticia.genero}\n` +
                `🌎 *Origen:* ${noticia.pais} ${emojiPais}\n\n` +
                `${getSpin('bio_label')}\n${noticia.bio}\n\n` +
                `${getSpin('tracks_label')}\n_${noticia.tracks}_\n\n` +
                `${getSpin('link_label')} ${noticia.youtube}`;
    await delay(4000 + Math.random() * 3000); // 4 a 7 segundos aleatorios

    try {
        // MOTOR DE ENVÍO RESTAURADO (Protocolo Newsletter/Channel)
        const opcionesEnvio = { newsletterJid: config.idCanal };

        if (noticia.imagen && noticia.imagen.startsWith('http')) {
            const res = await axios.get(noticia.imagen, { responseType: 'arraybuffer' });
            await sock.sendMessage(config.idCanal, { 
                image: Buffer.from(res.data), 
                caption: msg 
            }, opcionesEnvio);
        } else {
            await sock.sendMessage(config.idCanal, { text: msg }, opcionesEnvio);
    // 2. Investigar datos
   const info = await investigarBandaPro(noticia);
    const msg = `🎸 *${esPrueba?'PRUEBA':'NOTICIA'}* 🤘\n\n📢 *Disco:* ${noticia.banda}\n🌎 *Origen:* ${info.p}\n📜 *Historia:* ${info.h}${info.tracks}\n\n🔗 *Video:* ${noticia.youtube}`;
    await sock.sendMessage(config.idCanal, { text: msg });
    console.log(`🚀 ${esPrueba?'Prueba enviada':'Publicado'}: ${noticia.banda}`);
    
    // 3. Construir mensaje con Spintax
    const msg = `${getSpintax('intro')}\n\n📢 *Disco:* ${noticia.banda}\n🌎 *Origen:* ${info.p}\n${getSpintax('bio_label')} ${info.h}\n\n💿 *Tracks:*\n${noticia.tracks || "No disponibles"}\n\n${getSpintax('cierre')}\n🔗 ${noticia.youtube}`;

    // 4. Enviar con Imagen si existe
    if (noticia.imagen && noticia.imagen.startsWith('http')) {
        try {
            const response = await axios.get(noticia.imagen, { responseType: 'arraybuffer' });
            await sock.sendMessage(config.idCanal, { image: Buffer.from(response.data), caption: msg });
        } catch (e) {
            await sock.sendMessage(config.idCanal, { text: msg }); // Plan B: Solo texto
}
        console.log(`🚀 Publicado con éxito: ${noticia.banda}`);
    } catch (err) {
        console.log("❌ Error en el envío al canal:", err.message);
    } else {
        await sock.sendMessage(config.idCanal, { text: msg });
}
    
    console.log(`🚀 Publicado: ${noticia.banda}`);
}

async function iniciar() {
    const { state, saveCreds } = await useMultiFileAuthState('sesion_bot');
    const { version } = await fetchLatestBaileysVersion();
   const { state, saveCreds } = await useMultiFileAuthState('sesion_bot');
   const { version } = await fetchLatestBaileysVersion();
const sock = makeWASocket({ version, logger: pino({ level: "silent" }), auth: state, printQRInTerminal: false, browser: ["Ubuntu", "Chrome", "20.0.04"] });
    const sock = makeWASocket({ 
        version, 
        logger: pino({ level: "silent" }), 
        auth: state, 
        printQRInTerminal: false, 
        browser: ["Ubuntu", "Chrome", "20.0.04"] 
    });

    sock.ev.on("connection.update", async (up) => {
        const { connection, lastDisconnect } = up;
   sock.ev.on("connection.update", async (up) => {
       const { connection, lastDisconnect } = up;
        if (connection === "close") { if (lastDisconnect?.error?.output?.statusCode !== DisconnectReason.loggedOut) iniciar(); }
if (connection === "close") { 
if (lastDisconnect?.error?.output?.statusCode !== DisconnectReason.loggedOut) iniciar(); 
}
        else if (connection === "open") {
            console.log("\n✅ SISTEMA CONECTADO");
            let config = obtenerConfig();

            if (!config.idCanal) {
                console.log("\n👉 PASO 2: Envía un mensaje a tu CANAL para capturar el ID.");
                sock.ev.on("messages.upsert", async (m) => {
                    const msg = m.messages[0];
       else if (connection === "open") {
            console.log("\n✅ ¡VINCULADO!");
            console.log("\n✅ SISTEMA VINCULADO Y SEGURO");
           let config = obtenerConfig();

            // Lógica de detección de ID de canal (Mantenida intacta)
           if (!config.idCanal) {
                console.log("\n👉 PASO 2: Por favor, envía un mensaje (ej: 'Hola') a tu CANAL de noticias ahora.");
                console.log("⏳ Esperando a detectar el ID real del canal...");
                
                console.log("\n👉 PASO 2: Envía un mensaje a tu CANAL ahora.");
               sock.ev.on("messages.upsert", async (m) => {
                   const msg = m.messages[0];
if (msg.key.remoteJid.endsWith("@newsletter") && !config.idCanal) {
                        const realID = msg.key.remoteJid;
                    if (msg.key.remoteJid.endsWith("@newsletter")) {
                       const realID = msg.key.remoteJid;
                        console.log(`✅ ID REAL CAPTURADO: ${realID}`);
console.log(`✅ ID CAPTURADO: ${realID}`);
                        guardarConfig({ idCanal: realID });
                        config = obtenerConfig();
                       guardarConfig({ idCanal: realID });
                       config = obtenerConfig();
                        
if (!config.urlGoogle) {
                            const url = await question("\n👉 PASO 3: URL de App Script: ");
                            guardarConfig({ urlGoogle: url.trim() });
                            const url = await question("\n👉 PASO 3: Pega la URL de tu App Script: ");
                            guardarConfig({ urlGoogle: url.trim(), esPrimeraVez: true });
const agenda = await sincronizarConGoogle();
                            if (agenda.length > 0) await dispararPublicacion(sock, agenda[0], true);
                            if (agenda.length > 0) { await dispararPublicacion(sock, agenda[0], true); guardarConfig({ esPrimeraVez: false }); }
}
                    }
                });
                   }
               });
} else if (!config.urlGoogle) {
const url = await question("👉 Pega la URL de tu App Script: ");
                guardarConfig({ urlGoogle: url.trim() });
                guardarConfig({ urlGoogle: url.trim(), esPrimeraVez: true });
await sincronizarConGoogle();
            }

            cron.schedule('* * * * *', async () => {
                const ahora = new Date().toLocaleTimeString('es-MX', { hour12: false, hour: '2-digit', minute: '2-digit', timeZone: 'America/Mexico_City' });
                if (fs.existsSync(LOCAL_DB)) {
                    const datos = JSON.parse(fs.readFileSync(LOCAL_DB));
           }

            // Cronograma (Mantenido con margen de error aleatorio)
           cron.schedule('* * * * *', async () => {
               const ahora = new Date().toLocaleTimeString('es-MX', { hour12: false, hour: '2-digit', minute: '2-digit', timeZone: 'America/Mexico_City' });
               if (fs.existsSync(LOCAL_DB)) {
                   const datos = JSON.parse(fs.readFileSync(LOCAL_DB));
                    for (const item of datos) { if (item.horarioLimpio === ahora) await dispararPublicacion(sock, item); }
for (const item of datos) { 
if (item.horarioLimpio === ahora) {
                            // Delay aleatorio extra para seguridad
                            setTimeout(() => dispararPublicacion(sock, item), Math.random() * 5000);
                        }
                            const delayMinutos = Math.floor(Math.random() * 5) * 60000; 
                            setTimeout(() => dispararPublicacion(sock, item), delayMinutos);
                        } 
}
                }
                if (new Date().getMinutes() % 15 === 0) await sincronizarConGoogle();
            });
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
iniciar();
EOF
node bot_metal.js
               }
           });
       }
