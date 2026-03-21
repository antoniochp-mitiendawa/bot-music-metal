#!/data/data/com.termux/files/usr/bin/bash
termux-wake-lock

# --- CHECKPOINTS (PROHIBIDO MODIFICAR) ---
# --- CAPA DE INSTALACIÓN BLINDADA ---
PASO1_BASE=".sistema_base_ok"
PASO2_MOTOR=".motor_ia_ok"

@@ -15,7 +15,7 @@ fi
if [ ! -f "$PASO2_MOTOR" ]; then
pkg install -y nodejs-lts python ffmpeg libsqlite
mkdir -p datos_ia sesion_bot
    npm install @whiskeysockets/baileys pino readline axios cheerio node-cron
    npm install @whiskeysockets/baileys pino readline axios node-cron
touch "$PASO2_MOTOR"
fi

@@ -24,7 +24,6 @@ const { default: makeWASocket, useMultiFileAuthState, delay, fetchLatestBaileysV
const pino = require("pino");
const readline = require("readline");
const axios = require("axios");
const cheerio = require("cheerio");
const fs = require("fs");
const cron = require("node-cron");

@@ -34,14 +33,22 @@ const question = (text) => new Promise((resolve) => rl.question(text, resolve));
const CONFIG_PATH = "./datos_ia/config.json";
const LOCAL_DB = "./datos_ia/agenda_dia.json";

// Diccionarios Spintax y Banderas
// --- BASE DE DATOS DE BANDERAS ---
const banderas = {
    "Grecia": "🇬🇷", "Sweden": "🇸🇪", "Suecia": "🇸🇪", "Norway": "🇳🇴", "Noruega": "🇳🇴",
    "Germany": "🇩🇪", "Alemania": "🇩🇪", "USA": "🇺🇸", "EEUU": "🇺🇸", "Mexico": "🇲🇽",
    "México": "🇲🇽", "Finland": "🇫🇮", "Finlandia": "🇫🇮", "Brazil": "🇧🇷", "Brasil": "🇧🇷",
    "England": "🏴󠁧󠁢󠁥󠁮󠁧󠁿", "Inglaterra": "🏴󠁧󠁢󠁥󠁮󠁧󠁿", "Canada": "🇨🇦", "Canadá": "🇨🇦"
};

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
const banderas = { "Greece": "🇬🇷", "Sweden": "🇸🇪", "Norway": "🇳🇴", "Germany": "🇩🇪", "USA": "🇺🇸", "Finland": "🇫🇮" };

function obtenerConfig() { 
   if (!fs.existsSync(CONFIG_PATH)) return {};
@@ -56,32 +63,15 @@ function limpiarHorario(dato) {
   return `${h.padStart(2, '0')}:${m.padStart(2, '0')}`;
}

async function investigarBandaPro(noticia) {
    const query = noticia.banda.split(" - ")[0];
    let origen = "Origen Confirmado 🌎";
    let historia = "Lanzamiento 2026.";
    
    try {
        const { data } = await axios.get(`https://www.metal-archives.com/search?searchString=${encodeURIComponent(query)}&type=band_name`, { timeout: 4000 });
        const $ = cheerio.load(data);
        const countryFound = $("table tr:first-child td:nth-child(2)").text().trim();
        if (countryFound) {
            const flag = banderas[countryFound] || "🌎";
            origen = `${countryFound} ${flag}`;
        }
    } catch (e) { }

    return { p: origen, h: historia, tracks: noticia.tracks ? `\n\n💿 *Tracks:*\n${noticia.tracks}` : "" };
}

async function sincronizarConGoogle() {
   const config = obtenerConfig();
   if (!config.urlGoogle) return [];
   try {
       const { data } = await axios.get(config.urlGoogle);
        // El bot ahora espera 8 columnas según la nueva hoja
       const agenda = data.map(i => ({ ...i, horarioLimpio: limpiarHorario(i.horario) })).filter(i => i.banda && i.horarioLimpio);
       fs.writeFileSync(LOCAL_DB, JSON.stringify(agenda));
        console.log(`📅 Agenda: ${agenda.length} bandas listas.`);
        console.log(`📅 Sincronización exitosa: ${agenda.length} publicaciones en agenda.`);
       return agenda;
   } catch (e) { return fs.existsSync(LOCAL_DB) ? JSON.parse(fs.readFileSync(LOCAL_DB)) : []; }
}
@@ -90,21 +80,37 @@ async function dispararPublicacion(sock, noticia, esPrueba = false) {
   const config = obtenerConfig();
   if (!config.idCanal) return;

    // 1. Simulación Humana (Typing) de 8 segundos
   await sock.sendPresenceUpdate('composing', config.idCanal);
    await delay(3000 + Math.random() * 3000);
    await delay(8000);

    // 2. Procesamiento de Bandera
    const emojiPais = banderas[noticia.pais] || "🌎";

    const info = await investigarBandaPro(noticia);
    const msg = `🎸 *${esPrueba?'PRUEBA':getSpin('intro')}* 🤘\n\n📢 *Disco:* ${noticia.banda}\n🌎 *Origen:* ${info.p}\n${getSpin('bio')} ${info.h}${info.tracks}\n\n${getSpin('link')} ${noticia.youtube}`;
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
    console.log(`🚀 ${esPrueba?'Prueba enviada':'Publicado'}: ${noticia.banda}`);
    console.log(`🚀 Publicado: ${noticia.banda}`);
}

async function iniciar() {
@@ -114,60 +120,59 @@ async function iniciar() {

   sock.ev.on("connection.update", async (up) => {
       const { connection, lastDisconnect } = up;
        if (connection === "close") { if (lastDisconnect?.error?.output?.statusCode !== DisconnectReason.loggedOut) iniciar(); }
        else if (connection === "open") {
            console.log("\n✅ ¡VINCULADO!");
        if (connection === "close") { 
            if (lastDisconnect?.error?.output?.statusCode !== DisconnectReason.loggedOut) iniciar(); 
        } else if (connection === "open") {
            console.log("\n✅ SISTEMA METAL 2026 VINCULADO");
           let config = obtenerConfig();

            // PASO 2: CAPTURA DE ID (PROTEGIDO)
           if (!config.idCanal) {
                console.log("\n👉 PASO 2: Por favor, envía un mensaje a tu CANAL ahora.");
                console.log("\n👉 PASO 2: Envía un mensaje a tu CANAL para capturar el ID.");
               sock.ev.on("messages.upsert", async (m) => {
                   const msg = m.messages[0];
                   if (msg.key.remoteJid.endsWith("@newsletter") && !config.idCanal) {
                       const realID = msg.key.remoteJid;
                        console.log(`✅ ID REAL CAPTURADO: ${realID}`);
                        console.log(`✅ ID CAPTURADO: ${realID}`);
                       guardarConfig({ idCanal: realID });
                       config = obtenerConfig();
                       if (!config.urlGoogle) {
                           const url = await question("\n👉 PASO 3: Pega la URL de tu App Script: ");
                            guardarConfig({ urlGoogle: url.trim(), esPrimeraVez: true });
                            guardarConfig({ urlGoogle: url.trim() });
                           const agenda = await sincronizarConGoogle();
                            if (agenda.length > 0) { 
                                await dispararPublicacion(sock, agenda[0], true);
                                guardarConfig({ esPrimeraVez: false }); 
                            }
                            if (agenda.length > 0) await dispararPublicacion(sock, agenda[0], true);
                       }
                   }
               });
            } else if (!config.urlGoogle) {
                const url = await question("👉 Pega la URL de tu App Script: ");
                guardarConfig({ urlGoogle: url.trim(), esPrimeraVez: true });
                await sincronizarConGoogle();
           }

            // CRONOGRAMA DE PUBLICACIÓN
           cron.schedule('* * * * *', async () => {
               const ahora = new Date().toLocaleTimeString('es-MX', { hour12: false, hour: '2-digit', minute: '2-digit', timeZone: 'America/Mexico_City' });
               if (fs.existsSync(LOCAL_DB)) {
                   const datos = JSON.parse(fs.readFileSync(LOCAL_DB));
                   for (const item of datos) { 
                       if (item.horarioLimpio === ahora) {
                            const wait = Math.floor(Math.random() * 60000);
                            setTimeout(() => dispararPublicacion(sock, item), wait);
                            // Delay aleatorio para evitar detección de bot
                            setTimeout(() => dispararPublicacion(sock, item), Math.random() * 10000);
                       }
                   }
               }
                // Sincronizar con la hoja cada 30 min automáticamente
                if (new Date().getMinutes() % 30 === 0) await sincronizarConGoogle();
           });
       }
   });

   if (!sock.authState.creds.registered) {
       await delay(5000);
        const numero = await question("👉 Tu número (ej: 521...): ");
        const numero = await question("👉 Introduce tu número (con código de país): ");
       const codigo = await sock.requestPairingCode(numero.trim());
        console.log(`\n🔑 CÓDIGO DE VINCULACIÓN: ${codigo}\n`);
        console.log(`\n🔑 TU CÓDIGO DE VINCULACIÓN: ${codigo}\n`);
   }
   sock.ev.on("creds.update", saveCreds);
}
iniciar();
EOF

node bot_metal.js
