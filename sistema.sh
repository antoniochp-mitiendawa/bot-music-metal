#!/data/data/com.termux/files/usr/bin/bash
termux-wake-lock

# --- CHECKPOINTS (MANTENIDOS) ---
# --- CHECKPOINTS (INTOCABLES) --- [cite: 1]
# --- CHECKPOINTS (PROHIBIDO MODIFICAR) ---
# --- CAPA DE INSTALACIÓN BLINDADA ---
PASO1_BASE=".sistema_base_ok"
PASO2_MOTOR=".motor_ia_ok"

@@ -10,92 +10,79 @@ if [ ! -f "$PASO1_BASE" ]; then
pkg upgrade -y -o Dpkg::Options::="--force-confold"
pkg install -y git openssl wget
touch "$PASO1_BASE"
fi
fi [cite: 2]

@@ -15,7 +15,7 @@ fi
if [ ! -f "$PASO2_MOTOR" ]; then
pkg install -y nodejs-lts python ffmpeg libsqlite
    mkdir -p datos_ia sesion_bot temp_media
    mkdir -p datos_ia sesion_bot
npm install @whiskeysockets/baileys pino readline axios cheerio node-cron
mkdir -p datos_ia sesion_bot
    npm install @whiskeysockets/baileys pino readline axios cheerio node-cron
    npm install @whiskeysockets/baileys pino readline axios node-cron
touch "$PASO2_MOTOR"
fi
fi [cite: 3]

cat << 'EOF' > bot_metal.js
const { default: makeWASocket, useMultiFileAuthState, delay, fetchLatestBaileysVersion, DisconnectReason } = require("@whiskeysockets/baileys");
const { default: makeWASocket, useMultiFileAuthState, delay, fetchLatestBaileysVersion, DisconnectReason } = require("@whiskeysockets/baileys"); [cite: 3]
@@ -24,7 +24,6 @@ const { default: makeWASocket, useMultiFileAuthState, delay, fetchLatestBaileysV
const pino = require("pino");
const readline = require("readline");
const axios = require("axios");
const cheerio = require("cheerio");
const fs = require("fs");
const cron = require("node-cron");
const cron = require("node-cron"); [cite: 4]

const rl = readline.createInterface({ input: process.stdin, output: process.stdout });
const rl = readline.createInterface({ input: process.stdin, output: process.stdout }); [cite: 5]
const question = (text) => new Promise((resolve) => rl.question(text, resolve));

@@ -34,14 +33,22 @@ const question = (text) => new Promise((resolve) => rl.question(text, resolve));
const CONFIG_PATH = "./datos_ia/config.json";
const CONFIG_PATH = "./datos_ia/config.json"; [cite: 6]
const LOCAL_DB = "./datos_ia/agenda_dia.json";

// --- DICCIONARIOS LOCALES (SPINTAX) ---
// --- NUEVO: SPINTAX Y BANDERAS (ADICIÓN SIN ALTERAR LÓGICA) ---
const spintax = {
    intro: ["🔥 ¡BRUTAL ESTRENO!", "🤘 NOVEDAD METALERA", "⚡ RECIÉN DESENTERRADO", "🎸 IMPACTO TOTAL"],
    bio_label: ["📜 La historia:", "📖 Biografía:", "🔍 Tras la banda:", "📄 Contexto:"],
    cierre: ["🔥 ¡Escúchalo ahora!", "🤘 No te lo pierdas:", "🎸 Dale play aquí:", "💀 Metal or Die:"]
// Diccionarios Spintax y Banderas
// --- BASE DE DATOS DE BANDERAS ---
const banderas = {
    "Grecia": "🇬🇷", "Sweden": "🇸🇪", "Suecia": "🇸🇪", "Norway": "🇳🇴", "Noruega": "🇳🇴",
    "Germany": "🇩🇪", "Alemania": "🇩🇪", "USA": "🇺🇸", "EEUU": "🇺🇸", "Mexico": "🇲🇽",
    "México": "🇲🇽", "Finland": "🇫🇮", "Finlandia": "🇫🇮", "Brazil": "🇧🇷", "Brasil": "🇧🇷",
    "England": "🏴󠁧󠁢󠁥󠁮󠁧󠁿", "Inglaterra": "🏴󠁧󠁢󠁥󠁮󠁧󠁿", "Canada": "🇨🇦", "Canadá": "🇨🇦"
};

const getSpintax = (tipo) => spintax[tipo][Math.floor(Math.random() * spintax[tipo].length)];

// --- MAPEO DE BANDERAS ---
const banderas = {
    "Greece": "🇬🇷", "Grecia": "🇬🇷", "Sweden": "🇸🇪", "Suecia": "🇸🇪", "Norway": "🇳🇴", "Noruega": "🇳🇴",
    "USA": "🇺🇸", "EEUU": "🇺🇸", "Germany": "🇩🇪", "Alemania": "🇩🇪", "Canada": "🇨🇦", "Australia": "🇦🇺"
// --- MOTOR DE SPINTAX NOTICIOSO ---
const spintax = {
intro: ["🔥 ¡ESTRENO BRUTAL!", "🤘 NOVEDAD METALERA", "⚡ RECIÉN SALIDO", "🎸 IMPACTO TOTAL"],
bio: ["📜 Historia:", "📖 Biografía:", "🔍 Sobre la banda:", "📄 Ficha técnica:"],
link: ["🔗 Video oficial:", "🎥 Mira el video:", "🤘 Escúchalo aquí:"]
    intro: ["🔥 *¡ALERTA DE ESTRENO!*", "🤘 *NOVEDAD BRUTAL*", "⚡ *IMPACTO METALERO*", "🎸 *CRÓNICA DEL DÍA*"],
    bio_label: ["📜 *Trasfondo:*", "📖 *La Historia:*", "🔍 *Análisis:*", "📄 *Ficha Técnica:*"],
    tracks_label: ["💿 *Setlist del Álbum:*", "🎶 *Tracks Destacados:*", "🎼 *Lista de Temas:*"],
    link_label: ["🎥 *Video Oficial:*", "🔗 *Mira el video aquí:*", "🤘 *Ver en YouTube:*"]
};
const getSpin = (t) => spintax[t][Math.floor(Math.random() * spintax[t].length)];
const banderas = { "Greece": "🇬🇷", "Sweden": "🇸🇪", "Norway": "🇳🇴", "Germany": "🇩🇪", "USA": "🇺🇸", "Canada": "🇨🇦", "Finland": "🇫🇮" };
const banderas = { "Greece": "🇬🇷", "Sweden": "🇸🇪", "Norway": "🇳🇴", "Germany": "🇩🇪", "USA": "🇺🇸", "Finland": "🇫🇮" };

function obtenerConfig() { 
if (!fs.existsSync(CONFIG_PATH)) return {};
   try { return JSON.parse(fs.readFileSync(CONFIG_PATH)); } catch { return {}; }
}
function guardarConfig(data) { fs.writeFileSync(CONFIG_PATH, JSON.stringify({ ...obtenerConfig(), ...data })); }
} [cite: 7]
function guardarConfig(data) { fs.writeFileSync(CONFIG_PATH, JSON.stringify({ ...obtenerConfig(), ...data })); } [cite: 7]

function limpiarHorario(dato) {
   const match = String(dato).match(/(\d{1,2}:\d{2})/);
   if (!match) return null;
   let [h, m] = match[1].split(':');
@@ -56,32 +63,15 @@ function limpiarHorario(dato) {
return `${h.padStart(2, '0')}:${m.padStart(2, '0')}`;
}
} [cite: 9]

// --- INVESTIGACIÓN AUTOMÁTICA (SCRAPING GRATUITO) ---
// --- INVESTIGACIÓN MEJORADA (MANTIENE ESTRUCTURA ORIGINAL) --- [cite: 10]
async function investigarBandaPro(noticia) {
   const query = noticia.banda.split(" - ")[0];
    let origen = "Origen desconocido 🌎";
    let historia = "Nueva fuerza del metal emergente.";
    let bandera = "🤘";

    const query = noticia.banda.split(" - ")[0];
let origen = "Origen Confirmado 🌎";
let historia = "Lanzamiento 2026.";

   try {
        // Intento en Metal Archives (Búsqueda simple)
        const searchUrl = `https://www.metal-archives.com/search?searchString=${encodeURIComponent(query)}&type=band_name`;
        const { data } = await axios.get(searchUrl, { timeout: 5000 });
    try {
const { data } = await axios.get(`https://www.metal-archives.com/search?searchString=${encodeURIComponent(query)}&type=band_name`, { timeout: 4000 });
       const $ = cheerio.load(data);
        
        // Si hay resultados, extraemos país (Este es un ejemplo de lógica de scraping)
       const countryFound = $("table tr:first-child td:nth-child(2)").text().trim();
       if (countryFound) {
            origen = countryFound;
            bandera = banderas[countryFound] || "🌎";
        const $ = cheerio.load(data);
        const countryFound = $("table tr:first-child td:nth-child(2)").text().trim();
        if (countryFound) {
const flag = banderas[countryFound] || "🌎";
origen = `${countryFound} ${flag}`;
       }
    } catch (e) {
        console.log("⚠️ Búsqueda externa fallida, usando datos básicos.");
    }
    } catch (e) { /* Silencioso para no romper flujo */ }
        }
    } catch (e) { }

    return { p: `${origen} ${bandera}`, h: historia };
    return { p: origen, h: historia, tracks: noticia.tracks ? `\n\n💿 *Tracks:*\n${noticia.tracks}` : "" }; [cite: 12]
    return { p: origen, h: historia, tracks: noticia.tracks ? `\n\n💿 *Tracks:*\n${noticia.tracks}` : "" };
}

async function sincronizarConGoogle() {
const config = obtenerConfig();
if (!config.urlGoogle) return [];
try {
        const { data } = await axios.get(config.urlGoogle);
        const { data } = await axios.get(config.urlGoogle); [cite: 14]
       const { data } = await axios.get(config.urlGoogle);
        // El bot ahora espera 8 columnas según la nueva hoja
const agenda = data.map(i => ({ ...i, horarioLimpio: limpiarHorario(i.horario) })).filter(i => i.banda && i.horarioLimpio);
fs.writeFileSync(LOCAL_DB, JSON.stringify(agenda));
        console.log(`📅 Agenda: ${agenda.length} noticias listas.`);
        console.log(`📅 Agenda: ${agenda.length} bandas listas.`); [cite: 16]
        console.log(`📅 Agenda: ${agenda.length} bandas listas.`);
        console.log(`📅 Sincronización exitosa: ${agenda.length} publicaciones en agenda.`);
return agenda;
} catch (e) { return fs.existsSync(LOCAL_DB) ? JSON.parse(fs.readFileSync(LOCAL_DB)) : []; }
}
@@ -104,75 +91,74 @@ async function dispararPublicacion(sock, noticia, esPrueba = false) {
@@ -90,21 +80,37 @@ async function dispararPublicacion(sock, noticia, esPrueba = false) {
const config = obtenerConfig();
if (!config.idCanal) return;

    // 1. Simular "Escribiendo..."
    // Simulación Humana (Typing)
    // 1. Simulación Humana (Typing) de 8 segundos
await sock.sendPresenceUpdate('composing', config.idCanal);
    await delay(4000 + Math.random() * 3000); // 4 a 7 segundos aleatorios
await delay(3000 + Math.random() * 3000);
    await delay(8000);

    // 2. Procesamiento de Bandera
    const emojiPais = banderas[noticia.pais] || "🌎";

    // 2. Investigar datos
const info = await investigarBandaPro(noticia);
    
    // 3. Construir mensaje con Spintax
    const msg = `${getSpintax('intro')}\n\n📢 *Disco:* ${noticia.banda}\n🌎 *Origen:* ${info.p}\n${getSpintax('bio_label')} ${info.h}\n\n💿 *Tracks:*\n${noticia.tracks || "No disponibles"}\n\n${getSpintax('cierre')}\n🔗 ${noticia.youtube}`;
    const info = await investigarBandaPro(noticia); [cite: 18]
const msg = `🎸 *${esPrueba?'PRUEBA':getSpin('intro')}* 🤘\n\n📢 *Disco:* ${noticia.banda}\n🌎 *Origen:* ${info.p}\n${getSpin('bio')} ${info.h}${info.tracks}\n\n${getSpin('link')} ${noticia.youtube}`;

    // 4. Enviar con Imagen si existe
    // Envío con Imagen si existe URL [cite: 19]
    // 3. Construcción del Mensaje con Formato Noticioso (Negritas y Cursivas)
    const msg = `${getSpin('intro')}\n\n` +
                `📢 *Banda:* _${noticia.banda}_\n` +
                `🎸 *Género:* ${noticia.genero}\n` +
                `🌎 *Origen:* ${noticia.pais} ${emojiPais}\n\n` +
                `${getSpin('bio_label')}\n${noticia.bio}\n\n` +
                `${getSpin('tracks_label')}\n_${noticia.tracks}_\n\n` +
                `${getSpin('link_label')} ${noticia.youtube}`;

    // 4. Envío de Imagen como Contenedor (Si existe URL)
if (noticia.imagen && noticia.imagen.startsWith('http')) {
try {
            const response = await axios.get(noticia.imagen, { responseType: 'arraybuffer' });
            await sock.sendMessage(config.idCanal, { image: Buffer.from(response.data), caption: msg });
        } catch (e) {
            await sock.sendMessage(config.idCanal, { text: msg }); // Plan B: Solo texto
        }
            const res = await axios.get(noticia.imagen, { responseType: 'arraybuffer' });
           const res = await axios.get(noticia.imagen, { responseType: 'arraybuffer' });
await sock.sendMessage(config.idCanal, { image: Buffer.from(res.data), caption: msg });
} catch (e) { await sock.sendMessage(config.idCanal, { text: msg }); }
            await sock.sendMessage(config.idCanal, { 
                image: Buffer.from(res.data), 
                caption: msg 
            });
        } catch (e) { 
            await sock.sendMessage(config.idCanal, { text: msg }); 
        }
} else {
await sock.sendMessage(config.idCanal, { text: msg });
}
    
    console.log(`🚀 Publicado: ${noticia.banda}`);
console.log(`🚀 ${esPrueba?'Prueba enviada':'Publicado'}: ${noticia.banda}`);
    console.log(`🚀 Publicado: ${noticia.banda}`);
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
    const { version } = await fetchLatestBaileysVersion(); [cite: 21]
    const sock = makeWASocket({ version, logger: pino({ level: "silent" }), auth: state, printQRInTerminal: false, browser: ["Ubuntu", "Chrome", "20.0.04"] });
@@ -114,60 +120,59 @@ async function iniciar() {

sock.ev.on("connection.update", async (up) => {
const { connection, lastDisconnect } = up;
        if (connection === "close") { 
            if (lastDisconnect?.error?.output?.statusCode !== DisconnectReason.loggedOut) iniciar(); 
        }
if (connection === "close") { if (lastDisconnect?.error?.output?.statusCode !== DisconnectReason.loggedOut) iniciar(); }
       else if (connection === "open") {
            console.log("\n✅ SISTEMA VINCULADO Y SEGURO");
        else if (connection === "open") {
console.log("\n✅ ¡VINCULADO!");
        if (connection === "close") { 
            if (lastDisconnect?.error?.output?.statusCode !== DisconnectReason.loggedOut) iniciar(); 
        } else if (connection === "open") {
            console.log("\n✅ SISTEMA METAL 2026 VINCULADO");
let config = obtenerConfig();

            // Lógica de detección de ID de canal (Mantenida intacta)
            // FLUJO DE CONFIGURACIÓN ORIGINAL (PROTEGIDO) [cite: 23]
            // PASO 2: CAPTURA DE ID (PROTEGIDO)
if (!config.idCanal) {
                console.log("\n👉 PASO 2: Envía un mensaje a tu CANAL ahora.");
console.log("\n👉 PASO 2: Por favor, envía un mensaje a tu CANAL ahora.");
                console.log("\n👉 PASO 2: Envía un mensaje a tu CANAL para capturar el ID.");
sock.ev.on("messages.upsert", async (m) => {
const msg = m.messages[0];
                    if (msg.key.remoteJid.endsWith("@newsletter")) {
                    if (msg.key.remoteJid.endsWith("@newsletter") && !config.idCanal) {
                   if (msg.key.remoteJid.endsWith("@newsletter") && !config.idCanal) {
const realID = msg.key.remoteJid;
                        console.log(`✅ ID CAPTURADO: ${realID}`);
console.log(`✅ ID REAL CAPTURADO: ${realID}`);
                        console.log(`✅ ID CAPTURADO: ${realID}`);
guardarConfig({ idCanal: realID });
config = obtenerConfig();
                        if (!config.urlGoogle) {
                            const url = await question("\n👉 PASO 3: Pega la URL de tu App Script: "); [cite: 26]
                       if (!config.urlGoogle) {
                           const url = await question("\n👉 PASO 3: Pega la URL de tu App Script: ");
guardarConfig({ urlGoogle: url.trim(), esPrimeraVez: true });
                            const agenda = await sincronizarConGoogle();
                            guardarConfig({ urlGoogle: url.trim() });
                           const agenda = await sincronizarConGoogle();
if (agenda.length > 0) { 
                                await dispararPublicacion(sock, agenda[0], true); [cite: 27]
                                await dispararPublicacion(sock, agenda[0], true);
guardarConfig({ esPrimeraVez: false }); 
}
                        }
                            if (agenda.length > 0) await dispararPublicacion(sock, agenda[0], true);
                       }
}
});
} else if (!config.urlGoogle) {
                const url = await question("👉 Pega la URL de tu App Script: "); [cite: 29]
                const url = await question("👉 Pega la URL de tu App Script: ");
guardarConfig({ urlGoogle: url.trim(), esPrimeraVez: true });
await sincronizarConGoogle();
}

            // Cronograma (Mantenido con margen de error aleatorio)
            // Cronograma original [cite: 31]
            // CRONOGRAMA DE PUBLICACIÓN
cron.schedule('* * * * *', async () => {
const ahora = new Date().toLocaleTimeString('es-MX', { hour12: false, hour: '2-digit', minute: '2-digit', timeZone: 'America/Mexico_City' });
if (fs.existsSync(LOCAL_DB)) {
const datos = JSON.parse(fs.readFileSync(LOCAL_DB));
for (const item of datos) { 
if (item.horarioLimpio === ahora) {
                            const delayMinutos = Math.floor(Math.random() * 5) * 60000; 
                            setTimeout(() => dispararPublicacion(sock, item), delayMinutos);
                        } 
                            const wait = Math.floor(Math.random() * 60000); // Variación de segundos
                            const wait = Math.floor(Math.random() * 60000);
setTimeout(() => dispararPublicacion(sock, item), wait);
                        }
                            // Delay aleatorio para evitar detección de bot
                            setTimeout(() => dispararPublicacion(sock, item), Math.random() * 10000);
                       }
}
}
                // Sincronizar con la hoja cada 30 min automáticamente
                if (new Date().getMinutes() % 30 === 0) await sincronizarConGoogle();
});
@@ -181,7 +167,7 @@ async function iniciar() {
       }
   });

if (!sock.authState.creds.registered) {
await delay(5000);
const numero = await question("👉 Tu número (ej: 521...): ");
        const numero = await question("👉 Tu número (ej: 521...): "); [cite: 33]
        const numero = await question("👉 Introduce tu número (con código de país): ");
const codigo = await sock.requestPairingCode(numero.trim());
       console.log(`\n🔑 CÓDIGO DE VINCULACIÓN: ${codigo}\n`);
        console.log(`\n🔑 CÓDIGO DE VINCULACIÓN: ${codigo}\n`);
        console.log(`\n🔑 TU CÓDIGO DE VINCULACIÓN: ${codigo}\n`);
}
   sock.ev.on("creds.update", saveCreds);
}
iniciar();
EOF

node bot_metal.js
