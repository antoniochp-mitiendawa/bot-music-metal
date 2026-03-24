
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
};

// --- MOTOR DE SPINTAX NOTICIOSO ---
const spintax = {
    intro: ["🔥 *¡ALERTA DE ESTRENO!*", "🤘 *NOVEDAD BRUTAL*", "⚡ *IMPACTO METALERO*", "🎸 *CRÓNICA DEL DÍA*"],
    bio_label: ["📜 *Trasfondo:*", "📖 *La Historia:*", "🔍 *Análisis:*", "📄 *Ficha Técnica:*"],
    tracks_label: ["💿 *Setlist del Álbum:*", "🎶 *Tracks Destacados:*", "🎼 *Lista de Temas:*"],
    link_label: ["🎥 *Video Oficial:*", "🔗 *Mira el video aquí:*", "🤘 *Ver en YouTube:*"]
};
const getSpin = (t) => spintax[t][Math.floor(Math.random() * spintax[t].length)];

function obtenerConfig() { 
   if (!fs.existsSync(CONFIG_PATH)) return {};
   try { return JSON.parse(fs.readFileSync(CONFIG_PATH)); } catch { return {}; }
@@ -45,18 +63,12 @@ function limpiarHorario(dato) {
   return `${h.padStart(2, '0')}:${m.padStart(2, '0')}`;
}

async function investigarBandaPro(noticia) {
    const db = { "Septicflesh": { p: "Grecia 🇬🇷", h: "Pioneros del Death Sinfónico." }, "Rotting Christ": { p: "Grecia 🇬🇷", h: "Leyendas del Dark Metal." } };
    const nombre = noticia.banda ? noticia.banda.split(" - ")[0] : "Banda";
    const info = db[nombre] || { p: "Origen Confirmado 🌎", h: "Lanzamiento 2026." };
    return { ...info, tracks: noticia.tracks ? `\n\n💿 *Tracks:*\n${noticia.tracks}` : "" };
}

async function sincronizarConGoogle() {
   const config = obtenerConfig();
   if (!config.urlGoogle) return [];
   try {
       const { data } = await axios.get(config.urlGoogle);
        // Sincronización de 8 columnas (Banda, Género, País, Bio, YT, Tracks, Horario, Imagen)
       const agenda = data.map(i => ({ ...i, horarioLimpio: limpiarHorario(i.horario) })).filter(i => i.banda && i.horarioLimpio);
       fs.writeFileSync(LOCAL_DB, JSON.stringify(agenda));
       console.log(`📅 Agenda: ${agenda.length} bandas listas.`);
@@ -67,9 +79,31 @@ async function sincronizarConGoogle() {
async function dispararPublicacion(sock, noticia, esPrueba = false) {
   const config = obtenerConfig();
   if (!config.idCanal) return;
    const info = await investigarBandaPro(noticia);
    const msg = `🎸 *${esPrueba?'PRUEBA':'NOTICIA'}* 🤘\n\n📢 *Disco:* ${noticia.banda}\n🌎 *Origen:* ${info.p}\n📜 *Historia:* ${info.h}${info.tracks}\n\n🔗 *Video:* ${noticia.youtube}`;
    await sock.sendMessage(config.idCanal, { text: msg });

    // Simulación de escritura humana (10 segundos)
    await sock.sendPresenceUpdate('composing', config.idCanal);
    await delay(10000); 

    const emojiPais = banderas[noticia.pais] || "🌎";
    
    // Construcción del mensaje con negritas (*) e inclinadas (_)
    const msg = `${getSpin('intro')}\n\n` +
                `📢 *Banda:* _${noticia.banda}_\n` +
                `🎸 *Género:* ${noticia.genero}\n` +
                `🌎 *Origen:* ${noticia.pais} ${emojiPais}\n\n` +
                `${getSpin('bio_label')}\n${noticia.bio}\n\n` +
                `${getSpin('tracks_label')}\n_${noticia.tracks}_\n\n` +
                `${getSpin('link_label')} ${noticia.youtube}`;

    // Envío de Imagen como contenedor (mediante Buffer para evitar fallos de Baileys)
    if (noticia.imagen && noticia.imagen.startsWith('http')) {
        try {
            const res = await axios.get(noticia.imagen, { responseType: 'arraybuffer' });
            await sock.sendMessage(config.idCanal, { image: Buffer.from(res.data), caption: msg });
        } catch (e) { await sock.sendMessage(config.idCanal, { text: msg }); }
    } else {
        await sock.sendMessage(config.idCanal, { text: msg });
    }
   console.log(`🚀 ${esPrueba?'Prueba enviada':'Publicado'}: ${noticia.banda}`);
}

@@ -82,26 +116,27 @@ async function iniciar() {
       const { connection, lastDisconnect } = up;
       if (connection === "close") { if (lastDisconnect?.error?.output?.statusCode !== DisconnectReason.loggedOut) iniciar(); }
       else if (connection === "open") {
            console.log("\n✅ ¡VINCULADO!");
            console.log("\n✅ ¡SISTEMA METAL VINCULADO!");
           let config = obtenerConfig();

            // CAPTURA DE ID DE CANAL (Newsletter)
           if (!config.idCanal) {
                console.log("\n👉 PASO 2: Por favor, envía un mensaje (ej: 'Hola') a tu CANAL de noticias ahora.");
                console.log("⏳ Esperando a detectar el ID real del canal...");
                
                console.log("\n👉 PASO 2: Envía un mensaje a tu CANAL de noticias ahora para capturar el ID.");
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
                            if (agenda.length > 0) { 
                                await dispararPublicacion(sock, agenda[0], true);
                                guardarConfig({ esPrimeraVez: false }); 
                            }
                       }
                   }
               });
@@ -111,12 +146,18 @@ async function iniciar() {
               await sincronizarConGoogle();
           }

            // CRONOGRAMA AUTOMÁTICO
           cron.schedule('* * * * *', async () => {
               const ahora = new Date().toLocaleTimeString('es-MX', { hour12: false, hour: '2-digit', minute: '2-digit', timeZone: 'America/Mexico_City' });
               if (fs.existsSync(LOCAL_DB)) {
                   const datos = JSON.parse(fs.readFileSync(LOCAL_DB));
                    for (const item of datos) { if (item.horarioLimpio === ahora) await dispararPublicacion(sock, item); }
                    for (const item of datos) { 
                        if (item.horarioLimpio === ahora) {
                            setTimeout(() => dispararPublicacion(sock, item), Math.random() * 5000);
                        }
                    }
               }
                if (new Date().getMinutes() % 15 === 0) await sincronizarConGoogle();
           });
       }
   });
