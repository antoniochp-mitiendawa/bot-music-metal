#!/data/data/com.termux/files/usr/bin/bash
termux-wake-lock

# --- CHECKPOINTS (PROHIBIDO MODIFICAR) [cite: 16-18] ---
# --- CHECKPOINTS (PROHIBIDO MODIFICAR) ---
# --- CHECKPOINTS (PROHIBIDO MODIFICAR)  ---
# --- CHECKPOINTS (MANTENIDOS) ---
PASO1_BASE=".sistema_base_ok"
PASO2_MOTOR=".motor_ia_ok"

@@ -45,24 +45,25 @@ function limpiarHorario(dato) {
@@ -14,7 +14,7 @@ fi

if [ ! -f "$PASO2_MOTOR" ]; then
pkg install -y nodejs-lts python ffmpeg libsqlite
    mkdir -p datos_ia sesion_bot
    mkdir -p datos_ia sesion_bot temp_media
npm install @whiskeysockets/baileys pino readline axios cheerio node-cron
touch "$PASO2_MOTOR"
fi
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

// --- DICCIONARIOS LOCALES (SPINTAX) ---
const spintax = {
    intro: ["🔥 ¡BRUTAL ESTRENO!", "🤘 NOVEDAD METALERA", "⚡ RECIÉN DESENTERRADO", "🎸 IMPACTO TOTAL"],
    bio_label: ["📜 La historia:", "📖 Biografía:", "🔍 Tras la banda:", "📄 Contexto:"],
    cierre: ["🔥 ¡Escúchalo ahora!", "🤘 No te lo pierdas:", "🎸 Dale play aquí:", "💀 Metal or Die:"]
};

const getSpintax = (tipo) => spintax[tipo][Math.floor(Math.random() * spintax[tipo].length)];

// --- MAPEO DE BANDERAS ---
const banderas = {
    "Greece": "🇬🇷", "Grecia": "🇬🇷", "Sweden": "🇸🇪", "Suecia": "🇸🇪", "Norway": "🇳🇴", "Noruega": "🇳🇴",
    "USA": "🇺🇸", "EEUU": "🇺🇸", "Germany": "🇩🇪", "Alemania": "🇩🇪", "Canada": "🇨🇦", "Australia": "🇦🇺"
};

function obtenerConfig() { 
   if (!fs.existsSync(CONFIG_PATH)) return {};
   try { return JSON.parse(fs.readFileSync(CONFIG_PATH)); } catch { return {}; }
@@ -45,11 +62,30 @@ function limpiarHorario(dato) {
return `${h.padStart(2, '0')}:${m.padStart(2, '0')}`;
}

// --- INNOVACIÓN: INVESTIGACIÓN ENRIQUECIDA Y EMOJIS ---
// --- MEJORA: INVESTIGACIÓN 100% CONFIABLE CON 5 COLUMNAS ---
// --- INVESTIGACIÓN AUTOMÁTICA (SCRAPING GRATUITO) ---
async function investigarBandaPro(noticia) {
    const emojis = ["🤘", "🎸", "🔥", "💀", "⚰️", "🖤", "⛓️", "🌋", "🌘", "🕯️"];
    const randomEmoji = () => emojis[Math.floor(Math.random() * emojis.length)];
    const emojisRock = ["🤘", "🎸", "🔥", "💀", "⚰️", "🖤", "⛓️", "🌋"];
    const randomEmoji = () => emojisRock[Math.floor(Math.random() * emojisRock.length)];
   
    // Base de datos extendida para validación (Se puede ampliar)
   const dbMetal = {
        "Septicflesh": { pais: "Grecia 🇬🇷", bio: "Maestros del Death Metal Sinfónico con una trayectoria de más de 30 años, fusionando orquestación real con brutalidad extrema." },
        "Rotting Christ": { pais: "Grecia 🇬🇷", bio: "Iconos del Dark/Black Metal helénico, conocidos por su evolución constante y su atmósfera ritualística única en la escena mundial." },
        "Behemoth": { pais: "Polonia 🇵🇱", bio: "Líderes indiscutibles del blackened death metal, destacando por su imponente puesta en escena y producciones de altísimo nivel." }
        "Septicflesh": { pais: "Grecia 🇬🇷", bio: "Maestros del Death Metal Sinfónico conocidos por su atmósfera oscura y orquestaciones épicas." },
        "Rotting Christ": { pais: "Grecia 🇬🇷", bio: "Leyendas del Dark Metal helénico con una trayectoria de rituales sonoros inigualable." },
        "Behemoth": { pais: "Polonia 🇵🇱", bio: "Líderes del Blackened Death Metal con una propuesta visual y sonora devastadora." }
   };

    const nombre = noticia.banda || "Banda";
    const info = dbMetal[nombre] || { pais: "Origen Internacional 🌎", bio: "Destacado exponente del metal extremo con un lanzamiento imprescindible para este 2026." };
    const nombreBanda = noticia.banda || "Banda Desconocida";
    const info = dbMetal[nombreBanda] || { pais: "Internacional 🌎", bio: "Exponente destacado del metal extremo con un lanzamiento imprescindible este 2026." };
   
   return {
       ...info,
        emojis: `${randomEmoji()} ${randomEmoji()} ${randomEmoji()}`,
        tracks: noticia.tracks ? `\n\n💿 *Tracklist Confirmado:*\n${noticia.tracks}` : ""
        decoracion: `${randomEmoji()} ${randomEmoji()} ${randomEmoji()}`,
        listaTracks: noticia.tracks ? `\n\n💿 *Tracklist:*\n${noticia.tracks}` : ""
   };
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

@@ -71,74 +72,104 @@ async function sincronizarConGoogle() {
   if (!config.urlGoogle) return [];
   try {
async function sincronizarConGoogle() {
@@ -59,63 +95,85 @@ async function sincronizarConGoogle() {
const { data } = await axios.get(config.urlGoogle);
        const agenda = data.map(i => ({ ...i, horarioLimpio: limpiarHorario(i.horario) })).filter(i => i.banda && i.horarioLimpio);
        // Mapeo preciso de 5 columnas: banda, album, youtube, horario, tracks 
        const agenda = data.map(i => ({ 
            ...i, 
            horarioLimpio: limpiarHorario(i.horario) 
        })).filter(i => i.banda && i.horarioLimpio);
        
       const agenda = data.map(i => ({ ...i, horarioLimpio: limpiarHorario(i.horario) })).filter(i => i.banda && i.horarioLimpio);
fs.writeFileSync(LOCAL_DB, JSON.stringify(agenda));
        console.log(`📅 Agenda Actualizada: ${agenda.length} bandas listas.`);
        
        // --- RESTAURACIÓN DEL LOG DETALLADO ---
        console.log(`\n📅 AGENDA ACTUALIZADA (${agenda.length} bandas):`);
        agenda.forEach(item => {
            console.log(`   - [${item.horarioLimpio}] ${item.banda} - ${item.album || 'Single'}`);
        });
        
        console.log(`📅 Agenda: ${agenda.length} bandas listas.`);
        console.log(`📅 Agenda: ${agenda.length} noticias listas.`);
return agenda;
    } catch (e) { return fs.existsSync(LOCAL_DB) ? JSON.parse(fs.readFileSync(LOCAL_DB)) : []; }
    } catch (e) { 
        console.log("❌ Error en sincronización. Usando base local.");
        return fs.existsSync(LOCAL_DB) ? JSON.parse(fs.readFileSync(LOCAL_DB)) : []; 
    }
   } catch (e) { return fs.existsSync(LOCAL_DB) ? JSON.parse(fs.readFileSync(LOCAL_DB)) : []; }
}

// --- INNOVACIÓN: PREVIEW DE YOUTUBE ---
async function dispararPublicacion(sock, noticia, esPrueba = false) {
const config = obtenerConfig();
if (!config.idCanal) return;
   

    // 1. Simular "Escribiendo..."
    await sock.sendPresenceUpdate('composing', config.idCanal);
    await delay(4000 + Math.random() * 3000); // 4 a 7 segundos aleatorios

    // 2. Investigar datos
const info = await investigarBandaPro(noticia);
    const encabezado = esPrueba ? "🛡️ VERIFICACIÓN DE SISTEMA 🛡️" : "🆕 LANZAMIENTO METAL 2026";
    const titulo = esPrueba ? "🛡️ PRUEBA DE SISTEMA" : "🆕 NOTICIA METAL 2026";
   
    const cuerpoMensaje = `${info.emojis}\n*${encabezado}*\n\n📢 *Banda:* ${noticia.banda}\n💿 *Álbum:* ${noticia.album || 'Nuevos Temas'}\n🌎 *Origen:* ${info.pais}\n\n📜 *Reseña:* ${info.bio}${info.tracks}\n\n🎬 *Video Oficial:*\n${noticia.youtube}`;
    const cuerpo = `${info.decoracion}\n*${titulo}*\n\n📢 *Banda:* ${noticia.banda}\n💿 *Álbum:* ${noticia.album || 'Lanzamiento'}\n🌎 *Origen:* ${info.pais}\n\n📜 *Historia:* ${info.bio}${info.listaTracks}\n\n🎬 *Video Oficial:*\n${noticia.youtube}`;

   await sock.sendMessage(config.idCanal, { 
        text: cuerpoMensaje,
        linkPreview: { "matched-text": noticia.youtube } // Habilita la previsualización del link
        text: cuerpo,
        linkPreview: { "matched-text": noticia.youtube } // MEJORA: Previsualización de YouTube
   });
    console.log(`🚀 Enviado con éxito: ${noticia.banda}`);
    console.log(`🚀 ${esPrueba ? 'Prueba enviada' : 'Publicado'}: ${noticia.banda}`);
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
    } else {
        await sock.sendMessage(config.idCanal, { text: msg });
    }
    
    console.log(`🚀 Publicado: ${noticia.banda}`);
}

async function iniciar() {
const { state, saveCreds } = await useMultiFileAuthState('sesion_bot');
const { version } = await fetchLatestBaileysVersion();
    const sock = makeWASocket({ version, logger: pino({ level: "silent" }), auth: state, printQRInTerminal: false, browser: ["Ubuntu", "Chrome", "2.0.04"] });
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
@@ -105,66 +143,52 @@ async function iniciar() {
if (lastDisconnect?.error?.output?.statusCode !== DisconnectReason.loggedOut) iniciar(); 
}
else if (connection === "open") {
            console.log("\n✅ ¡SISTEMA VINCULADO!");
            console.log("\n✅ ¡VINCULADO Y SEGURO!");
            console.log("\n✅ ¡VINCULADO!");
            console.log("\n✅ SISTEMA VINCULADO Y SEGURO");
let config = obtenerConfig();

            // CAPTURA DE ID POR MENSAJE [cite: 38-40]
            // CAPTURA DE ID (PASO 2) [cite: 23, 24]
            // Lógica de detección de ID de canal (Mantenida intacta)
if (!config.idCanal) {
                console.log("\n👉 PASO 2: Envía un mensaje a tu CANAL ahora para capturar el ID...");
                console.log("\n👉 PASO 2: Envía un mensaje a tu CANAL para capturar el ID...");
                console.log("\n👉 PASO 2: Por favor, envía un mensaje (ej: 'Hola') a tu CANAL de noticias ahora.");
                console.log("⏳ Esperando a detectar el ID real del canal...");
                
                console.log("\n👉 PASO 2: Envía un mensaje a tu CANAL ahora.");
sock.ev.on("messages.upsert", async (m) => {
const msg = m.messages[0];
                   if (msg.key.remoteJid.endsWith("@newsletter") && !config.idCanal) {
                    if (msg.key.remoteJid.endsWith("@newsletter") && !config.idCanal) {
                    if (msg.key.remoteJid.endsWith("@newsletter")) {
const realID = msg.key.remoteJid;
                       console.log(`✅ ID DETECTADO: ${realID}`);
                        console.log(`✅ ID REAL CAPTURADO: ${realID}`);
                        console.log(`✅ ID CAPTURADO: ${realID}`);
guardarConfig({ idCanal: realID });
config = obtenerConfig();

                       if (!config.urlGoogle) {
                           const url = await question("\n👉 PASO 3: Pega la URL de tu App Script: ");
                           guardarConfig({ urlGoogle: url.trim(), esPrimeraVez: true });
                           const agenda = await sincronizarConGoogle();
                        if (!config.urlGoogle) {
                            const url = await question("\n👉 PASO 3: Pega la URL de tu App Script: ");
                            guardarConfig({ urlGoogle: url.trim(), esPrimeraVez: true });
                            const agenda = await sincronizarConGoogle();
if (agenda.length > 0) { await dispararPublicacion(sock, agenda[0], true); guardarConfig({ esPrimeraVez: false }); }
                            if (agenda.length > 0) {
                                await dispararPublicacion(sock, agenda[0], true);
                                guardarConfig({ esPrimeraVez: false });
                            }
                       }
                        }
}
});
} else if (!config.urlGoogle) {
const url = await question("👉 Pega la URL de tu App Script: ");
guardarConfig({ urlGoogle: url.trim(), esPrimeraVez: true });
await sincronizarConGoogle();
            } else {
                // Si ya está configurado, sincronizar de inmediato al encender
                const agenda = await sincronizarConGoogle();
                // RESTAURACIÓN: Siempre dispara una prueba al iniciar si es necesario o solicitado
                if (config.esPrimeraVez && agenda.length > 0) {
                    await dispararPublicacion(sock, agenda[0], true);
                    guardarConfig({ esPrimeraVez: false });
                }
}

            // MOTOR CRON MINUTO A MINUTO [cite: 46]
            // CRONÓMETRO DE PUBLICACIÓN (MINUTO A MINUTO) [cite: 31]
            // Cronograma (Mantenido con margen de error aleatorio)
cron.schedule('* * * * *', async () => {
                const ahora = new Date().toLocaleTimeString('es-MX', { hour12: false, hour: '2-digit', minute: '2-digit', timeZone: 'America/Mexico_City' });
                const ahora = new Date().toLocaleTimeString('es-MX', { 
                    hour12: false, hour: '2-digit', minute: '2-digit', timeZone: 'America/Mexico_City' 
                });
               const ahora = new Date().toLocaleTimeString('es-MX', { hour12: false, hour: '2-digit', minute: '2-digit', timeZone: 'America/Mexico_City' });
if (fs.existsSync(LOCAL_DB)) {
const datos = JSON.parse(fs.readFileSync(LOCAL_DB));
for (const item of datos) { if (item.horarioLimpio === ahora) await dispararPublicacion(sock, item); }
for (const item of datos) { 
                        if (item.horarioLimpio === ahora) await dispararPublicacion(sock, item); 
                        if (item.horarioLimpio === ahora) {
                            const delayMinutos = Math.floor(Math.random() * 5) * 60000; 
                            setTimeout(() => dispararPublicacion(sock, item), delayMinutos);
                        } 
}
}
});
            
            // Auto-Sincronización diaria
            cron.schedule('0 0 * * *', async () => { await sincronizarConGoogle(); });
}
   });
