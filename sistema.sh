#!/data/data/com.termux/files/usr/bin/bash
termux-wake-lock

# --- CHECKPOINTS (PROHIBIDO MODIFICAR)  ---
# --- CHECKPOINTS (PROHIBIDO MODIFICAR) [cite: 16-18] ---
PASO1_BASE=".sistema_base_ok"
PASO2_MOTOR=".motor_ia_ok"

@@ -45,11 +45,25 @@ function limpiarHorario(dato) {
   return `${h.padStart(2, '0')}:${m.padStart(2, '0')}`;
}

// --- INNOVACIÓN: INVESTIGACIÓN ENRIQUECIDA Y EMOJIS ---
async function investigarBandaPro(noticia) {
    const db = { "Septicflesh": { p: "Grecia 🇬🇷", h: "Pioneros del Death Sinfónico." }, "Rotting Christ": { p: "Grecia 🇬🇷", h: "Leyendas del Dark Metal." } };
    const nombre = noticia.banda ? noticia.banda.split(" - ")[0] : "Banda";
    const info = db[nombre] || { p: "Origen Confirmado 🌎", h: "Lanzamiento 2026." };
    return { ...info, tracks: noticia.tracks ? `\n\n💿 *Tracks:*\n${noticia.tracks}` : "" };
    const emojis = ["🤘", "🎸", "🔥", "💀", "⚰️", "🖤", "⛓️", "🌋", "🌘", "🕯️"];
    const randomEmoji = () => emojis[Math.floor(Math.random() * emojis.length)];
    
    const dbMetal = {
        "Septicflesh": { pais: "Grecia 🇬🇷", bio: "Maestros del Death Metal Sinfónico con una trayectoria de más de 30 años, fusionando orquestación real con brutalidad extrema." },
        "Rotting Christ": { pais: "Grecia 🇬🇷", bio: "Iconos del Dark/Black Metal helénico, conocidos por su evolución constante y su atmósfera ritualística única en la escena mundial." },
        "Behemoth": { pais: "Polonia 🇵🇱", bio: "Líderes indiscutibles del blackened death metal, destacando por su imponente puesta en escena y producciones de altísimo nivel." }
    };

    const nombre = noticia.banda || "Banda";
    const info = dbMetal[nombre] || { pais: "Origen Internacional 🌎", bio: "Destacado exponente del metal extremo con un lanzamiento imprescindible para este 2026." };
    
    return {
        ...info,
        emojis: `${randomEmoji()} ${randomEmoji()} ${randomEmoji()}`,
        tracks: noticia.tracks ? `\n\n💿 *Tracklist Confirmado:*\n${noticia.tracks}` : ""
    };
}

async function sincronizarConGoogle() {
@@ -59,44 +73,50 @@ async function sincronizarConGoogle() {
       const { data } = await axios.get(config.urlGoogle);
       const agenda = data.map(i => ({ ...i, horarioLimpio: limpiarHorario(i.horario) })).filter(i => i.banda && i.horarioLimpio);
       fs.writeFileSync(LOCAL_DB, JSON.stringify(agenda));
        console.log(`📅 Agenda: ${agenda.length} bandas listas.`);
        console.log(`📅 Agenda Actualizada: ${agenda.length} bandas listas.`);
       return agenda;
   } catch (e) { return fs.existsSync(LOCAL_DB) ? JSON.parse(fs.readFileSync(LOCAL_DB)) : []; }
}

// --- INNOVACIÓN: PREVIEW DE YOUTUBE ---
async function dispararPublicacion(sock, noticia, esPrueba = false) {
   const config = obtenerConfig();
   if (!config.idCanal) return;
    
   const info = await investigarBandaPro(noticia);
    const msg = `🎸 *${esPrueba?'PRUEBA':'NOTICIA'}* 🤘\n\n📢 *Disco:* ${noticia.banda}\n🌎 *Origen:* ${info.p}\n📜 *Historia:* ${info.h}${info.tracks}\n\n🔗 *Video:* ${noticia.youtube}`;
    await sock.sendMessage(config.idCanal, { text: msg });
    console.log(`🚀 ${esPrueba?'Prueba enviada':'Publicado'}: ${noticia.banda}`);
    const encabezado = esPrueba ? "🛡️ VERIFICACIÓN DE SISTEMA 🛡️" : "🆕 LANZAMIENTO METAL 2026";
    
    const cuerpoMensaje = `${info.emojis}\n*${encabezado}*\n\n📢 *Banda:* ${noticia.banda}\n💿 *Álbum:* ${noticia.album || 'Nuevos Temas'}\n🌎 *Origen:* ${info.pais}\n\n📜 *Reseña:* ${info.bio}${info.tracks}\n\n🎬 *Video Oficial:*\n${noticia.youtube}`;

    await sock.sendMessage(config.idCanal, { 
        text: cuerpoMensaje,
        linkPreview: { "matched-text": noticia.youtube } // Habilita la previsualización del link
    });
    console.log(`🚀 Enviado con éxito: ${noticia.banda}`);
}

async function iniciar() {
   const { state, saveCreds } = await useMultiFileAuthState('sesion_bot');
   const { version } = await fetchLatestBaileysVersion();
    const sock = makeWASocket({ version, logger: pino({ level: "silent" }), auth: state, printQRInTerminal: false, browser: ["Ubuntu", "Chrome", "20.0.04"] });
    const sock = makeWASocket({ version, logger: pino({ level: "silent" }), auth: state, printQRInTerminal: false, browser: ["Ubuntu", "Chrome", "2.0.04"] });

   sock.ev.on("connection.update", async (up) => {
       const { connection, lastDisconnect } = up;
       if (connection === "close") { if (lastDisconnect?.error?.output?.statusCode !== DisconnectReason.loggedOut) iniciar(); }
       else if (connection === "open") {
            console.log("\n✅ ¡VINCULADO!");
            console.log("\n✅ ¡SISTEMA VINCULADO!");
           let config = obtenerConfig();

            // CAPTURA DE ID POR MENSAJE [cite: 38-40]
           if (!config.idCanal) {
                console.log("\n👉 PASO 2: Por favor, envía un mensaje (ej: 'Hola') a tu CANAL de noticias ahora.");
                console.log("⏳ Esperando a detectar el ID real del canal...");
                
                console.log("\n👉 PASO 2: Envía un mensaje a tu CANAL ahora para capturar el ID...");
               sock.ev.on("messages.upsert", async (m) => {
                   const msg = m.messages[0];
                   if (msg.key.remoteJid.endsWith("@newsletter") && !config.idCanal) {
                       const realID = msg.key.remoteJid;
                        console.log(`✅ ID REAL CAPTURADO: ${realID}`);
                        console.log(`✅ ID DETECTADO: ${realID}`);
                       guardarConfig({ idCanal: realID });
                       config = obtenerConfig();
                        
                       if (!config.urlGoogle) {
                           const url = await question("\n👉 PASO 3: Pega la URL de tu App Script: ");
                           guardarConfig({ urlGoogle: url.trim(), esPrimeraVez: true });
@@ -111,6 +131,7 @@ async function iniciar() {
               await sincronizarConGoogle();
           }

            // MOTOR CRON MINUTO A MINUTO [cite: 46]
           cron.schedule('* * * * *', async () => {
               const ahora = new Date().toLocaleTimeString('es-MX', { hour12: false, hour: '2-digit', minute: '2-digit', timeZone: 'America/Mexico_City' });
               if (fs.existsSync(LOCAL_DB)) {
