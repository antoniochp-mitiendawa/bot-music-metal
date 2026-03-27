#!/data/data/com.termux/files/usr/bin/bash

# Activar persistencia para que Termux no se detenga en segundo plano
# Activar persistencia
termux-wake-lock

# --- CHECKPOINTS (PROHIBIDO MODIFICAR 1 Y 2 - BLINDADO) [cite: 15] ---
# --- CHECKPOINTS (PROHIBIDO MODIFICAR - BLINDADO TOTAL) [cite: 1-5] ---
PASO1_BASE=".sistema_base_ok"
PASO2_MOTOR=".motor_ia_ok"

echo "🤖 [SISTEMA] Cargando Motor de Gestión con Filtro de Tracks..."

# ==========================================
# PASO 1: CIMENTACIÓN (BLINDADO) [cite: 16-17]
# ==========================================
if [ -f "$PASO1_BASE" ]; then
echo "✅ [MEMORIA] Paso 1 listo."
else
@@ -21,9 +16,6 @@ else
touch "$PASO1_BASE"
fi

# ==========================================
# PASO 2: MOTOR DE EJECUCIÓN (BLINDADO) [cite: 18-19]
# ==========================================
if [ -f "$PASO2_MOTOR" ]; then
echo "✅ [MEMORIA] Paso 2 listo."
else
@@ -35,9 +27,9 @@ else
fi

# ==========================================
# PASO 3: MOTOR DE IA Y SINCRONIZACIÓN (BLINDADO Y CORREGIDO) [cite: 20-55]
# MOTOR DE IA Y GESTIÓN DE AGENDA (ARCHIVO ÚNICO) [cite: 6-41]
# ==========================================
cat << 'EOF' > index.js
cat << 'EOF' > bot_metal.js
const { 
   default: makeWASocket, 
   useMultiFileAuthState, 
@@ -67,138 +59,110 @@ function guardarConfig(data) {
   fs.writeFileSync(CONFIG_PATH, JSON.stringify({ ...actual, ...data }));
}

// --- SISTEMA SPINTAX PARA VARIEDAD (NUEVA FUNCIONALIDAD) ---
function aplicarSpintax(texto) {
    return texto.replace(/\{([^{}]+)\}/g, (match, opciones) => {
        const lista = opciones.split('|');
        return lista[Math.floor(Math.random() * lista.length)];
    });
}

function limpiarHorario(dato) {
   if (!dato) return null;
    const texto = String(dato);
    const match = texto.match(/(\d{1,2}:\d{2})/);
    const match = String(dato).match(/(\d{1,2}:\d{2})/);
   if (!match) return null;
    let [horas, minutos] = match[1].split(':');
    return `${horas.padStart(2, '0')}:${minutos}`;
    let [h, m] = match[1].split(':');
    return `${h.padStart(2, '0')}:${m.padStart(2, '0')}`;
}

async function investigarBandaPro(noticia) {
    console.log(`🔍 Filtrando y validando: ${noticia.banda}...`);
    // Base de datos local para evitar bloqueos de red en la validación [cite: 13-17]
   const databaseMetal = {
        "Septicflesh": { pais: "Grecia 🇬🇷", historia: "Pioneros del Death Metal Sinfónico con una atmósfera orquestal única." },
        "Rotting Christ": { pais: "Grecia 🇬🇷", historia: "Leyendas del Dark Metal con un sonido ritualista y oscuro." }
    };

    const nombreBanda = noticia.banda ? noticia.banda.split(" - ")[0] : "Desconocido";
    const info = databaseMetal[nombreBanda] || { 
        pais: "Origen Confirmado 🌎", 
        historia: "Agrupación destacada dentro de los nuevos lanzamientos de metal 2026." 
    };

    return {
        ...info,
        tracksFormatted: noticia.tracks ? `\n\n💿 *Tracks Destacados:*\n${noticia.tracks}` : ""
        "Septicflesh": { pais: "Grecia 🇬🇷", historia: "Pioneros del Death Metal Sinfónico." },
        "Rotting Christ": { pais: "Grecia 🇬🇷", historia: "Leyendas del Dark Metal." }
   };
    const nombre = noticia.banda ? noticia.banda.split(" - ")[0] : "Banda Metal";
    const info = databaseMetal[nombre] || { pais: "Origen Confirmado 🌎", historia: "Lanzamiento destacado 2026." };
    return { ...info, tracks: noticia.tracks ? `\n\n💿 *Tracks:*\n${noticia.tracks}` : "" };
}

async function sincronizarConGoogle() {
   const config = obtenerConfig();
   if (!config.urlGoogle) return [];

   try {
       const { data } = await axios.get(config.urlGoogle);
        // Mapeo espejo de Codigogs.txt 
        const agendaProcesada = data.map(item => ({
            banda: item.banda,
            youtube: item.youtube,
            horario: item.horario,
            tracks: item.tracks,
        const agenda = data.map(item => ({
            ...item,
           horarioLimpio: limpiarHorario(item.horario)
       })).filter(i => i.banda && i.horarioLimpio);
       
        fs.writeFileSync(LOCAL_DB, JSON.stringify(agendaProcesada));
        console.log(`📅 Agenda: ${agendaProcesada.length} bandas programadas.`);
        return agendaProcesada;
    } catch (e) {
        fs.writeFileSync(LOCAL_DB, JSON.stringify(agenda));
        console.log(`📅 Agenda: ${agenda.length} bandas programadas.`);
        agenda.forEach(a => console.log(`   ⏰ ${a.horarioLimpio} -> ${a.banda}`));
        return agenda;
    } catch (e) { 
       console.log("❌ Error al leer Google Sheets.");
        return [];
        return fs.existsSync(LOCAL_DB) ? JSON.parse(fs.readFileSync(LOCAL_DB)) : []; 
   }
}

async function dispararPublicacion(sock, noticia, esPrueba = false) {
   const config = obtenerConfig();
   if (!config.idCanal) return;

    const infoExtra = await investigarBandaPro(noticia);
    const encabezado = esPrueba ? 'PRUEBA DE INSTALACIÓN' : aplicarSpintax('{NUEVO LANZAMIENTO|ESTRENO METALERO|ACTUALIDAD METAL} 2026');
    const info = await investigarBandaPro(noticia);
    const tit = esPrueba ? 'PRUEBA DE INSTALACIÓN' : 'NUEVO LANZAMIENTO 2026';
    const msg = `🎸 *${tit}* 🤘\n\n📢 *Disco:* ${noticia.banda}\n🌎 *Origen:* ${info.pais}\n📜 *Historia:* ${info.historia}${info.tracks}\n\n🔗 *Video:* ${noticia.youtube}`;
   
    const mensaje = `🎸 *${encabezado}* 🤘\n\n` +
                   `📢 *Disco:* ${noticia.banda}\n` +
                   `🌎 *Origen:* ${infoExtra.pais}\n` +
                   `📜 *Historia:* ${infoExtra.historia}${infoExtra.tracksFormatted}\n\n` +
                   `🔗 *Video Oficial:* ${noticia.youtube}`;

    await sock.sendMessage(config.idCanal, { 
        text: mensaje,
        linkPreview: { "canonical-url": noticia.youtube } 
    });
    
    if (!esPrueba) console.log(`🚀 Publicado: ${noticia.banda} [${noticia.horarioLimpio}]`);
    try {
        await sock.sendMessage(config.idCanal, { text: msg, linkPreview: { "canonical-url": noticia.youtube } });
        console.log(`🚀 ${esPrueba ? 'Mensaje de prueba enviado.' : 'Publicado: ' + noticia.banda}`);
    } catch (err) { 
        console.log("❌ Error en el envío a WhatsApp."); 
    }
}

async function iniciarConexion() {
async function iniciar() {
   const { state, saveCreds } = await useMultiFileAuthState('sesion_bot');
   const { version } = await fetchLatestBaileysVersion();

    const sock = makeWASocket({
        version,
        logger: pino({ level: "silent" }),
    const sock = makeWASocket({ 
        version, 
        logger: pino({ level: "silent" }), 
        auth: state, 
       printQRInTerminal: false,
        auth: state,
        browser: ["Ubuntu", "Chrome", "20.0.04"]
        browser: ["Ubuntu", "Chrome", "20.0.04"] 
   });

    sock.ev.on("connection.update", async (update) => {
        const { connection, lastDisconnect } = update;
    sock.ev.on("connection.update", async (up) => {
        const { connection, lastDisconnect } = up;
       if (connection === "close") {
            if (lastDisconnect?.error?.output?.statusCode !== DisconnectReason.loggedOut) iniciarConexion();
            if (lastDisconnect?.error?.output?.statusCode !== DisconnectReason.loggedOut) iniciar();
       } else if (connection === "open") {
           console.log("\n✅ ¡SISTEMA VINCULADO CORRECTAMENTE!");
            
           let config = obtenerConfig();
           
            // Configuración de Canal e ID [cite: 29-32]
           if (!config.idCanal) {
                const urlCanal = await question("👉 Pega la liga de tu Canal (URL): ");
                let idLimpio = urlCanal.trim();
                if (idLimpio.includes("whatsapp.com/channel/")) {
                    idLimpio = idLimpio.split("/").pop() + "@newsletter";
                } else if (!idLimpio.includes("@")) {
                    idLimpio = idLimpio + "@newsletter";
                }
                console.log(`✅ ID detectado: ${idLimpio}`);
                guardarConfig({ idCanal: idLimpio });
                config = obtenerConfig(); 
                const url = await question("👉 Pega la liga de tu Canal (URL): ");
                let id = url.trim().includes("channel/") ? url.split("/").pop() + "@newsletter" : url.trim() + "@newsletter";
                console.log(`✅ ID detectado: ${id}`);
                guardarConfig({ idCanal: id });
           }

            // Configuración de Google Sheets [cite: 33]
           if (!config.urlGoogle) {
               const url = await question("👉 Pega la URL de tu App Script: ");
               guardarConfig({ urlGoogle: url.trim(), esPrimeraVez: true });
                config = obtenerConfig();
           }
           
            // Carga inicial y mensaje de prueba 
           const agenda = await sincronizarConGoogle();
            config = obtenerConfig();

            // --- MENSAJE DE PRUEBA RESTAURADO (AL INSTALAR) [cite: 48-49] ---
           if (config.esPrimeraVez && agenda.length > 0) {
               console.log("🧪 Disparando mensaje de prueba inmediato...");
               await dispararPublicacion(sock, agenda[0], true);
               guardarConfig({ esPrimeraVez: false });
           }

            // Motor de disparo por minuto [cite: 36-37]
           cron.schedule('* * * * *', async () => {
                const ahora = new Date().toLocaleTimeString('es-MX', { hour12: false, hour: '2-digit', minute: '2-digit' });
                const ahora = new Date().toLocaleTimeString('es-MX', { 
                    hour12: false, hour: '2-digit', minute: '2-digit', timeZone: 'America/Mexico_City' 
                });
                
               if (fs.existsSync(LOCAL_DB)) {
                   const datos = JSON.parse(fs.readFileSync(LOCAL_DB));
                   for (const item of datos) {
@@ -209,22 +173,22 @@ async function iniciarConexion() {
               }
           });

            // Resincronización diaria [cite: 38]
           cron.schedule('0 9 * * *', async () => { await sincronizarConGoogle(); });
       }
   });

    // Vinculación por código de 8 dígitos [cite: 39-40]
   if (!sock.authState.creds.registered) {
       await delay(5000);
       const numero = await question("👉 Tu número (ej: 521...): ");
       const codigo = await sock.requestPairingCode(numero.trim());
       console.log(`\n🔑 CÓDIGO DE VINCULACIÓN: ${codigo}\n`);
   }

   sock.ev.on("creds.update", saveCreds);
}

iniciarConexion();
iniciar();
EOF

# Ejecución final [cite: 33]
node index.js
node bot_metal.js
