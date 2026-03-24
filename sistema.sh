#!/data/data/com.termux/files/usr/bin/bash

# --- INSTALACIÓN Y ACTUALIZACIÓN DESDE CERO (NO MODIFICAR) ---
termux-wake-lock
echo "🚀 Iniciando instalación completa de Sistema Metal..."

pkg update -y -o Dpkg::Options::="--force-confold"
pkg upgrade -y -o Dpkg::Options::="--force-confold"
pkg install -y git nodejs-lts python ffmpeg libsqlite openssl wget -o Dpkg::Options::="--force-confold"
# --- CHECKPOINTS (PROHIBIDO MODIFICAR)  ---
PASO1_BASE=".sistema_base_ok"
PASO2_MOTOR=".motor_ia_ok"

if [ ! -f "$PASO1_BASE" ]; then
    pkg update -y -o Dpkg::Options::="--force-confold"
    pkg upgrade -y -o Dpkg::Options::="--force-confold"
    pkg install -y git openssl wget
    touch "$PASO1_BASE"
fi

mkdir -p datos_ia sesion_bot
npm install @whiskeysockets/baileys pino readline axios node-cron cheerio
if [ ! -f "$PASO2_MOTOR" ]; then
    pkg install -y nodejs-lts python ffmpeg libsqlite
    mkdir -p datos_ia sesion_bot
    npm install @whiskeysockets/baileys pino readline axios cheerio node-cron
    touch "$PASO2_MOTOR"
fi

# --- GENERACIÓN DEL ARCHIVO DEL BOT ---
cat << 'EOF' > bot_metal.js
const { default: makeWASocket, useMultiFileAuthState, delay, fetchLatestBaileysVersion, DisconnectReason } = require("@whiskeysockets/baileys");
const pino = require("pino");
@@ -26,13 +33,15 @@ const question = (text) => new Promise((resolve) => rl.question(text, resolve));
const CONFIG_PATH = "./datos_ia/config.json";
const LOCAL_DB = "./datos_ia/agenda_dia.json";

// --- BASE DE DATOS DE BANDERAS ---
const banderas = {
   "Grecia": "🇬🇷", "Sweden": "🇸🇪", "Suecia": "🇸🇪", "Norway": "🇳🇴", "Noruega": "🇳🇴",
   "Germany": "🇩🇪", "Alemania": "🇩🇪", "USA": "🇺🇸", "EEUU": "🇺🇸", "Mexico": "🇲🇽",
   "México": "🇲🇽", "Finland": "🇫🇮", "Finlandia": "🇫🇮", "Brazil": "🇧🇷", "Brasil": "🇧🇷",
   "England": "🏴󠁧󠁢󠁥󠁮󠁧󠁿", "Inglaterra": "🏴󠁧󠁢󠁥󠁮󠁧󠁿", "Canada": "🇨🇦", "Canadá": "🇨🇦", "Poland": "🇵🇱", "Polonia": "🇵🇱"
};

// --- MOTOR DE SPINTAX NOTICIOSO ---
const spintax = {
   intro: ["🔥 *¡ALERTA DE ESTRENO!*", "🤘 *NOVEDAD BRUTAL*", "⚡ *IMPACTO METALERO*", "🎸 *CRÓNICA DEL DÍA*"],
   bio_label: ["📜 *Trasfondo:*", "📖 *La Historia:*", "🔍 *Análisis:*", "📄 *Ficha Técnica:*"],
@@ -59,21 +68,25 @@ async function sincronizarConGoogle() {
   if (!config.urlGoogle) return [];
   try {
       const { data } = await axios.get(config.urlGoogle);
        // Sincronización de 8 columnas (Banda, Género, País, Bio, YT, Tracks, Horario, Imagen)
       const agenda = data.map(i => ({ ...i, horarioLimpio: limpiarHorario(i.horario) })).filter(i => i.banda && i.horarioLimpio);
       fs.writeFileSync(LOCAL_DB, JSON.stringify(agenda));
        console.log(`📅 Sincronizado: ${agenda.length} bandas en agenda.`);
        console.log(`📅 Agenda: ${agenda.length} bandas listas.`);
       return agenda;
   } catch (e) { return fs.existsSync(LOCAL_DB) ? JSON.parse(fs.readFileSync(LOCAL_DB)) : []; }
}

async function dispararPublicacion(sock, noticia) {
async function dispararPublicacion(sock, noticia, esPrueba = false) {
   const config = obtenerConfig();
   if (!config.idCanal) return;

    // Simulación de escritura humana (10 segundos)
   await sock.sendPresenceUpdate('composing', config.idCanal);
    await delay(10000); // 10 segundos de typing real
    await delay(10000); 

   const emojiPais = banderas[noticia.pais] || "🌎";
    
    // Construcción del mensaje con negritas (*) e inclinadas (_)
   const msg = `${getSpin('intro')}\n\n` +
               `📢 *Banda:* _${noticia.banda}_\n` +
               `🎸 *Género:* ${noticia.genero}\n` +
@@ -82,6 +95,7 @@ async function dispararPublicacion(sock, noticia) {
               `${getSpin('tracks_label')}\n_${noticia.tracks}_\n\n` +
               `${getSpin('link_label')} ${noticia.youtube}`;

    // Envío de Imagen como contenedor (mediante Buffer para evitar fallos de Baileys)
   if (noticia.imagen && noticia.imagen.startsWith('http')) {
       try {
           const res = await axios.get(noticia.imagen, { responseType: 'arraybuffer' });
@@ -90,7 +104,7 @@ async function dispararPublicacion(sock, noticia) {
   } else {
       await sock.sendMessage(config.idCanal, { text: msg });
   }
    console.log(`🚀 Publicado: ${noticia.banda}`);
    console.log(`🚀 ${esPrueba?'Prueba enviada':'Publicado'}: ${noticia.banda}`);
}

async function iniciar() {
@@ -100,30 +114,39 @@ async function iniciar() {

   sock.ev.on("connection.update", async (up) => {
       const { connection, lastDisconnect } = up;
        if (connection === "close") { 
            if (lastDisconnect?.error?.output?.statusCode !== DisconnectReason.loggedOut) iniciar(); 
        } else if (connection === "open") {
            console.log("\n✅ VINCULADO CORRECTAMENTE");
        if (connection === "close") { if (lastDisconnect?.error?.output?.statusCode !== DisconnectReason.loggedOut) iniciar(); }
        else if (connection === "open") {
            console.log("\n✅ ¡SISTEMA METAL VINCULADO!");
           let config = obtenerConfig();

            // CAPTURA DE ID DE CANAL (Newsletter)
           if (!config.idCanal) {
                console.log("\n👉 PASO 2: Envía un mensaje a tu CANAL para capturar el ID.");
                console.log("\n👉 PASO 2: Envía un mensaje a tu CANAL de noticias ahora para capturar el ID.");
               sock.ev.on("messages.upsert", async (m) => {
                   const msg = m.messages[0];
                   if (msg.key.remoteJid.endsWith("@newsletter") && !config.idCanal) {
                       const realID = msg.key.remoteJid;
                        console.log(`✅ ID CAPTURADO: ${realID}`);
                        console.log(`✅ ID REAL CAPTURADO: ${realID}`);
                       guardarConfig({ idCanal: realID });
                       config = obtenerConfig();
                       if (!config.urlGoogle) {
                           const url = await question("\n👉 PASO 3: Pega la URL de tu App Script: ");
                            guardarConfig({ urlGoogle: url.trim() });
                            await sincronizarConGoogle();
                            guardarConfig({ urlGoogle: url.trim(), esPrimeraVez: true });
                            const agenda = await sincronizarConGoogle();
                            if (agenda.length > 0) { 
                                await dispararPublicacion(sock, agenda[0], true);
                                guardarConfig({ esPrimeraVez: false }); 
                            }
                       }
                   }
               });
            } else if (!config.urlGoogle) {
                const url = await question("👉 Pega la URL de tu App Script: ");
                guardarConfig({ urlGoogle: url.trim(), esPrimeraVez: true });
                await sincronizarConGoogle();
           }

            // CRONOGRAMA AUTOMÁTICO
           cron.schedule('* * * * *', async () => {
               const ahora = new Date().toLocaleTimeString('es-MX', { hour12: false, hour: '2-digit', minute: '2-digit', timeZone: 'America/Mexico_City' });
               if (fs.existsSync(LOCAL_DB)) {
@@ -141,13 +164,12 @@ async function iniciar() {

   if (!sock.authState.creds.registered) {
       await delay(5000);
        const numero = await question("👉 Tu número (con código de país): ");
        const numero = await question("👉 Tu número (ej: 521...): ");
       const codigo = await sock.requestPairingCode(numero.trim());
       console.log(`\n🔑 CÓDIGO DE VINCULACIÓN: ${codigo}\n`);
   }
   sock.ev.on("creds.update", saveCreds);
}
iniciar();
EOF

node bot_metal.js
