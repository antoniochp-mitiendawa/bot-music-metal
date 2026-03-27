#!/data/data/com.termux/files/usr/bin/bash

# Activar persistencia
termux-wake-lock

# --- CHECKPOINTS (PROHIBIDO MODIFICAR - BLINDADO TOTAL)  ---
# --- CHECKPOINTS (PROHIBIDO MODIFICAR)  ---
PASO1_BASE=".sistema_base_ok"
PASO2_MOTOR=".motor_ia_ok"

if [ -f "$PASO1_BASE" ];
then
    echo "✅ [MEMORIA] Paso 1 listo."
else
if [ ! -f "$PASO1_BASE" ]; then
pkg update -y -o Dpkg::Options::="--force-confold"
pkg upgrade -y -o Dpkg::Options::="--force-confold"
pkg install -y git openssl wget
touch "$PASO1_BASE"
fi

if [ -f "$PASO2_MOTOR" ];
then
    echo "✅ [MEMORIA] Paso 2 listo."
else
if [ ! -f "$PASO2_MOTOR" ]; then
pkg install -y nodejs-lts python ffmpeg libsqlite
    mkdir -p datos_ia
    mkdir -p sesion_bot
    mkdir -p datos_ia sesion_bot
npm install @whiskeysockets/baileys pino readline axios cheerio node-cron
touch "$PASO2_MOTOR"
fi

# ==========================================
# MOTOR DE IA Y GESTIÓN DE AGENDA (ARCHIVO ÚNICO)
# ==========================================
cat << 'EOF' > bot_metal.js
const { 
    default: makeWASocket, 
    useMultiFileAuthState, 
    delay, 
    fetchLatestBaileysVersion, 
    DisconnectReason 
} = require("@whiskeysockets/baileys");
const { default: makeWASocket, useMultiFileAuthState, delay, fetchLatestBaileysVersion, DisconnectReason } = require("@whiskeysockets/baileys");
const pino = require("pino");
const readline = require("readline");
const axios = require("axios");
@@ -47,35 +29,26 @@ const cron = require("node-cron");

const rl = readline.createInterface({ input: process.stdin, output: process.stdout });
const question = (text) => new Promise((resolve) => rl.question(text, resolve));

const CONFIG_PATH = "./datos_ia/config.json";
const LOCAL_DB = "./datos_ia/agenda_dia.json";

function obtenerConfig() {
function obtenerConfig() { 
   if (!fs.existsSync(CONFIG_PATH)) return {};
   try { return JSON.parse(fs.readFileSync(CONFIG_PATH)); } catch { return {}; }
}

function guardarConfig(data) {
    const actual = obtenerConfig();
    fs.writeFileSync(CONFIG_PATH, JSON.stringify({ ...actual, ...data }));
}
function guardarConfig(data) { fs.writeFileSync(CONFIG_PATH, JSON.stringify({ ...obtenerConfig(), ...data })); }

function limpiarHorario(dato) {
    if (!dato) return null;
   const match = String(dato).match(/(\d{1,2}:\d{2})/);
   if (!match) return null;
   let [h, m] = match[1].split(':');
   return `${h.padStart(2, '0')}:${m.padStart(2, '0')}`;
}

async function investigarBandaPro(noticia) {
    const databaseMetal = {
        "Septicflesh": { pais: "Grecia 🇬🇷", historia: "Pioneros del Death Metal Sinfónico." },
        "Rotting Christ": { pais: "Grecia 🇬🇷", historia: "Leyendas del Dark Metal." }
    };
    const nombre = noticia.banda ? noticia.banda.split(" - ")[0] : "Banda Metal";
    const info = databaseMetal[nombre] || { pais: "Origen Confirmado 🌎", historia: "Lanzamiento destacado 2026." };
    const db = { "Septicflesh": { p: "Grecia 🇬🇷", h: "Pioneros del Death Sinfónico." }, "Rotting Christ": { p: "Grecia 🇬🇷", h: "Leyendas del Dark Metal." } };
    const nombre = noticia.banda ? noticia.banda.split(" - ")[0] : "Banda";
    const info = db[nombre] || { p: "Origen Confirmado 🌎", h: "Lanzamiento 2026." };
   return { ...info, tracks: noticia.tracks ? `\n\n💿 *Tracks:*\n${noticia.tracks}` : "" };
}

@@ -84,92 +57,67 @@ async function sincronizarConGoogle() {
   if (!config.urlGoogle) return [];
   try {
       const { data } = await axios.get(config.urlGoogle);
        const agenda = data.map(item => ({
            ...item,
            horarioLimpio: limpiarHorario(item.horario)
        })).filter(i => i.banda && i.horarioLimpio);
        const agenda = data.map(i => ({ ...i, horarioLimpio: limpiarHorario(i.horario) })).filter(i => i.banda && i.horarioLimpio);
       fs.writeFileSync(LOCAL_DB, JSON.stringify(agenda));
        console.log(`📅 Agenda: ${agenda.length} bandas programadas.`);
        agenda.forEach(a => console.log(`   ⏰ ${a.horarioLimpio} -> ${a.banda}`));
        console.log(`📅 Agenda: ${agenda.length} bandas listas.`);
       return agenda;
    } catch (e) { 
        console.log("❌ Error al leer Google Sheets.");
        return fs.existsSync(LOCAL_DB) ? JSON.parse(fs.readFileSync(LOCAL_DB)) : []; 
    }
    } catch (e) { return fs.existsSync(LOCAL_DB) ? JSON.parse(fs.readFileSync(LOCAL_DB)) : []; }
}

async function dispararPublicacion(sock, noticia, esPrueba = false) {
   const config = obtenerConfig();
   if (!config.idCanal) return;

   const info = await investigarBandaPro(noticia);
    const tit = esPrueba ? 'PRUEBA DE INSTALACIÓN' : 'NUEVO LANZAMIENTO 2026';
    const msg = `🎸 *${tit}* 🤘\n\n📢 *Disco:* ${noticia.banda}\n🌎 *Origen:* ${info.pais}\n📜 *Historia:* ${info.historia}${info.tracks}\n\n🔗 *Video:* ${noticia.youtube}`;

    try {
        await sock.sendMessage(config.idCanal, { text: msg });
        console.log(`🚀 ${esPrueba ? 'Mensaje de prueba enviado.' : 'Publicado: ' + noticia.banda}`);
    } catch (err) { 
        console.log("❌ Error en el envío a WhatsApp.");
    }
    const msg = `🎸 *${esPrueba?'PRUEBA':'NOTICIA'}* 🤘\n\n📢 *Disco:* ${noticia.banda}\n🌎 *Origen:* ${info.p}\n📜 *Historia:* ${info.h}${info.tracks}\n\n🔗 *Video:* ${noticia.youtube}`;
    await sock.sendMessage(config.idCanal, { text: msg });
    console.log(`🚀 ${esPrueba?'Prueba enviada':'Publicado'}: ${noticia.banda}`);
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
    const sock = makeWASocket({ version, logger: pino({ level: "silent" }), auth: state, printQRInTerminal: false, browser: ["Ubuntu", "Chrome", "20.0.04"] });

   sock.ev.on("connection.update", async (up) => {
       const { connection, lastDisconnect } = up;
        if (connection === "close") {
            if (lastDisconnect?.error?.output?.statusCode !== DisconnectReason.loggedOut) iniciar();
        } else if (connection === "open") {
            console.log("\n✅ ¡SISTEMA VINCULADO CORRECTAMENTE!");
        if (connection === "close") { if (lastDisconnect?.error?.output?.statusCode !== DisconnectReason.loggedOut) iniciar(); }
        else if (connection === "open") {
            console.log("\n✅ ¡VINCULADO!");
           let config = obtenerConfig();
          
            if (!config.idCanal) {
                const url = await question("👉 Pega la liga de tu Canal (URL): ");
                let id = url.trim().includes("channel/") ? url.split("/").pop() + "@newsletter" : url.trim() + "@newsletter";
                console.log(`✅ ID detectado: ${id}`);
                guardarConfig({ idCanal: id });
            }

            if (!config.urlGoogle) {
            if (!config.idCanal) {
                console.log("\n👉 PASO 2: Por favor, envía un mensaje (ej: 'Hola') a tu CANAL de noticias ahora.");
                console.log("⏳ Esperando a detectar el ID real del canal...");
                
                sock.ev.on("messages.upsert", async (m) => {
                    const msg = m.messages[0];
                    if (msg.key.remoteJid.endsWith("@newsletter") && !config.idCanal) {
                        const realID = msg.key.remoteJid;
                        console.log(`✅ ID REAL CAPTURADO: ${realID}`);
                        guardarConfig({ idCanal: realID });
                        config = obtenerConfig();
                        
                        if (!config.urlGoogle) {
                            const url = await question("\n👉 PASO 3: Pega la URL de tu App Script: ");
                            guardarConfig({ urlGoogle: url.trim(), esPrimeraVez: true });
                            const agenda = await sincronizarConGoogle();
                            if (agenda.length > 0) { await dispararPublicacion(sock, agenda[0], true); guardarConfig({ esPrimeraVez: false }); }
                        }
                    }
                });
            } else if (!config.urlGoogle) {
               const url = await question("👉 Pega la URL de tu App Script: ");
               guardarConfig({ urlGoogle: url.trim(), esPrimeraVez: true });
            }
            
            const agenda = await sincronizarConGoogle();
            config = obtenerConfig();

            if (config.esPrimeraVez && agenda.length > 0) {
                console.log("🧪 Disparando mensaje de prueba inmediato...");
                await dispararPublicacion(sock, agenda[0], true);
                guardarConfig({ esPrimeraVez: false });
                await sincronizarConGoogle();
           }

           cron.schedule('* * * * *', async () => {
                const ahora = new Date().toLocaleTimeString('es-MX', { 
                    hour12: false, hour: '2-digit', minute: '2-digit', timeZone: 'America/Mexico_City' 
                });
                
                const ahora = new Date().toLocaleTimeString('es-MX', { hour12: false, hour: '2-digit', minute: '2-digit', timeZone: 'America/Mexico_City' });
               if (fs.existsSync(LOCAL_DB)) {
                   const datos = JSON.parse(fs.readFileSync(LOCAL_DB));
                    for (const item of datos) {
                        if (item.horarioLimpio === ahora) {
                            await dispararPublicacion(sock, item);
                        }
                    }
                    for (const item of datos) { if (item.horarioLimpio === ahora) await dispararPublicacion(sock, item); }
               }
           });

            cron.schedule('0 9 * * *', async () => { await sincronizarConGoogle(); });
       }
   });

@@ -181,8 +129,6 @@ async function iniciar() {
   }
   sock.ev.on("creds.update", saveCreds);
}

iniciar();
EOF

node bot_metal.js
