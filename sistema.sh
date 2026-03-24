#!/data/data/com.termux/files/usr/bin/bash
termux-wake-lock

# --- CHECKPOINTS (PROHIBIDO MODIFICAR)  ---
# --- CHECKPOINTS (PROHIBIDO MODIFICAR) ---
PASO1_BASE=".sistema_base_ok"
PASO2_MOTOR=".motor_ia_ok"

@@ -29,24 +29,18 @@ const cron = require("node-cron");

const rl = readline.createInterface({ input: process.stdin, output: process.stdout });
const question = (text) => new Promise((resolve) => rl.question(text, resolve));

const CONFIG_PATH = "./datos_ia/config.json";
const LOCAL_DB = "./datos_ia/agenda_dia.json";

// --- BASE DE DATOS DE BANDERAS ---
const banderas = {
    "Grecia": "🇬🇷", "Sweden": "🇸🇪", "Suecia": "🇸🇪", "Norway": "🇳🇴", "Noruega": "🇳🇴",
    "Germany": "🇩🇪", "Alemania": "🇩🇪", "USA": "🇺🇸", "EEUU": "🇺🇸", "Mexico": "🇲🇽",
    "México": "🇲🇽", "Finland": "🇫🇮", "Finlandia": "🇫🇮", "Brazil": "🇧🇷", "Brasil": "🇧🇷",
    "England": "🏴󠁧󠁢󠁥󠁮󠁧U+E007F", "Inglaterra": "🏴󠁧󠁢󠁥󠁮󠁧U+E007F", "Canada": "🇨🇦", "Canadá": "🇨🇦", "Poland": "🇵🇱", "Polonia": "🇵🇱"
    "Grecia": "🇬🇷", "Sweden": "🇸🇪", "Norway": "🇳🇴", "Germany": "🇩🇪", "USA": "🇺🇸", "Mexico": "🇲🇽", "Finland": "🇫🇮", "Brazil": "🇧🇷", "Poland": "🇵🇱"
};

// --- MOTOR DE SPINTAX NOTICIOSO ---
const spintax = {
    intro: ["🔥 *¡ALERTA DE ESTRENO!*", "🤘 *NOVEDAD BRUTAL*", "⚡ *IMPACTO METALERO*", "🎸 *CRÓNICA DEL DÍA*"],
    bio_label: ["📜 *Trasfondo:*", "📖 *La Historia:*", "🔍 *Análisis:*", "📄 *Ficha Técnica:*"],
    tracks_label: ["💿 *Setlist del Álbum:*", "🎶 *Tracks Destacados:*", "🎼 *Lista de Temas:*"],
    link_label: ["🎥 *Video Oficial:*", "🔗 *Mira el video aquí:*", "🤘 *Ver en YouTube:*"]
    intro: ["🔥 *¡ALERTA DE ESTRENO!*", "🤘 *NOVEDAD BRUTAL*", "⚡ *IMPACTO METALERO*"],
    bio_label: ["📜 *Trasfondo:*", "📖 *La Historia:*", "🔍 *Análisis:*"],
    tracks_label: ["💿 *Setlist:*", "🎶 *Tracks:*"],
    link_label: ["🎥 *Video Oficial:*", "🔗 *Ver en YouTube:*"]
};
const getSpin = (t) => spintax[t][Math.floor(Math.random() * spintax[t].length)];

@@ -68,8 +62,11 @@ async function sincronizarConGoogle() {
   if (!config.urlGoogle) return [];
   try {
       const { data } = await axios.get(config.urlGoogle);
        // Sincronización de 8 columnas (Banda, Género, País, Bio, YT, Tracks, Horario, Imagen)
        const agenda = data.map(i => ({ ...i, horarioLimpio: limpiarHorario(i.horario) })).filter(i => i.banda && i.horarioLimpio);
        // Sincronización completa de 8 columnas
        const agenda = data.map(i => ({ 
            ...i, 
            horarioLimpio: limpiarHorario(i.horario) 
        })).filter(i => i.banda && i.horarioLimpio);
       fs.writeFileSync(LOCAL_DB, JSON.stringify(agenda));
       console.log(`📅 Agenda: ${agenda.length} bandas listas.`);
       return agenda;
@@ -80,13 +77,10 @@ async function dispararPublicacion(sock, noticia, esPrueba = false) {
   const config = obtenerConfig();
   if (!config.idCanal) return;

    // Simulación de escritura humana (10 segundos)
   await sock.sendPresenceUpdate('composing', config.idCanal);
    await delay(10000); 
    await delay(7000); 

   const emojiPais = banderas[noticia.pais] || "🌎";
    
    // Construcción del mensaje con negritas (*) e inclinadas (_)
   const msg = `${getSpin('intro')}\n\n` +
               `📢 *Banda:* _${noticia.banda}_\n` +
               `🎸 *Género:* ${noticia.genero}\n` +
@@ -95,7 +89,6 @@ async function dispararPublicacion(sock, noticia, esPrueba = false) {
               `${getSpin('tracks_label')}\n_${noticia.tracks}_\n\n` +
               `${getSpin('link_label')} ${noticia.youtube}`;

    // Envío de Imagen como contenedor (mediante Buffer para evitar fallos de Baileys)
   if (noticia.imagen && noticia.imagen.startsWith('http')) {
       try {
           const res = await axios.get(noticia.imagen, { responseType: 'arraybuffer' });
@@ -114,14 +107,15 @@ async function iniciar() {

   sock.ev.on("connection.update", async (up) => {
       const { connection, lastDisconnect } = up;
        if (connection === "close") { if (lastDisconnect?.error?.output?.statusCode !== DisconnectReason.loggedOut) iniciar(); }
        if (connection === "close") { 
            if (lastDisconnect?.error?.output?.statusCode !== DisconnectReason.loggedOut) iniciar(); 
        }
       else if (connection === "open") {
           console.log("\n✅ ¡SISTEMA METAL VINCULADO!");
           let config = obtenerConfig();

            // CAPTURA DE ID DE CANAL (Newsletter)
           if (!config.idCanal) {
                console.log("\n👉 PASO 2: Envía un mensaje a tu CANAL de noticias ahora para capturar el ID.");
                console.log("\n👉 PASO 2: Envía un mensaje a tu CANAL para capturar el ID.");
               sock.ev.on("messages.upsert", async (m) => {
                   const msg = m.messages[0];
                   if (msg.key.remoteJid.endsWith("@newsletter") && !config.idCanal) {
@@ -130,23 +124,19 @@ async function iniciar() {
                       guardarConfig({ idCanal: realID });
                       config = obtenerConfig();
                       if (!config.urlGoogle) {
                            const url = await question("\n👉 PASO 3: Pega la URL de tu App Script: ");
                            guardarConfig({ urlGoogle: url.trim(), esPrimeraVez: true });
                            const url = await question("\n👉 PASO 3: URL de App Script: ");
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
                guardarConfig({ urlGoogle: url.trim() });
               await sincronizarConGoogle();
           }

            // CRONOGRAMA AUTOMÁTICO
           cron.schedule('* * * * *', async () => {
               const ahora = new Date().toLocaleTimeString('es-MX', { hour12: false, hour: '2-digit', minute: '2-digit', timeZone: 'America/Mexico_City' });
               if (fs.existsSync(LOCAL_DB)) {
