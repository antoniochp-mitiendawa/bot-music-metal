fi

cat << 'EOF' > bot_metal.js
const { default: makeWASocket, useMultiFileAuthState, delay, fetchLatestBaileysVersion, DisconnectReason } = require("@whiskeysockets/baileys");
const { default: makeWASocket, useMultiFileAuthState, delay, fetchLatestBaileysVersion, DisconnectReason, getAggregateVotesInPollMessage } = require("@whiskeysockets/baileys");
const pino = require("pino");
const readline = require("readline");
const axios = require("axios");
@@ -64,7 +64,7 @@ async function sincronizarConGoogle() {
       const { data } = await axios.get(config.urlGoogle);
       const agenda = data.map(i => ({ ...i, horarioLimpio: limpiarHorario(i.horario) })).filter(i => i.banda && i.horarioLimpio);
       fs.writeFileSync(LOCAL_DB, JSON.stringify(agenda));
        console.log(`📅 Agenda Actualizada: ${agenda.length} registros.`);
        console.log(`📅 Agenda Sincronizada: ${agenda.length} registros.`);
       return agenda;
   } catch (e) { return fs.existsSync(LOCAL_DB) ? JSON.parse(fs.readFileSync(LOCAL_DB)) : []; }
}
@@ -73,12 +73,12 @@ async function dispararPublicacion(sock, noticia, esPrueba = false) {
   const config = obtenerConfig();
   if (!config.idCanal) return;

    console.log(`⏳ Intentando enviar a canal: ${noticia.banda}...`);
    console.log(`⏳ Procesando envío a Canal: ${noticia.banda}...`);
   await sock.sendPresenceUpdate('composing', config.idCanal);
    await delay(esPrueba ? 2000 : 8000); 
    await delay(esPrueba ? 2000 : 10000); 

   const emojiPais = banderas[noticia.pais] || "🌎";
    const msg = `${getSpin('intro')}\n\n` +
    const cuerpoMensaje = `${getSpin('intro')}\n\n` +
               `📢 *Banda:* _${noticia.banda}_\n` +
               `🎸 *Género:* ${noticia.genero}\n` +
               `🌎 *Origen:* ${noticia.pais} ${emojiPais}\n\n` +
@@ -87,25 +87,39 @@ async function dispararPublicacion(sock, noticia, esPrueba = false) {
               `${getSpin('link_label')} ${noticia.youtube}`;

   try {
        // TRATAMIENTO ESPECIAL PARA CANALES (NEWSLETTERS)
        const sendOptions = { newsletterJid: config.idCanal };

        // CORRECCIÓN QUIRÚRGICA: Protocolo de Newsletters/Channels
       if (noticia.imagen && noticia.imagen.startsWith('http')) {
           const res = await axios.get(noticia.imagen, { responseType: 'arraybuffer' });
            await sock.sendMessage(config.idCanal, { image: Buffer.from(res.data), caption: msg }, sendOptions);
            await sock.sendMessage(config.idCanal, { 
                image: Buffer.from(res.data), 
                caption: cuerpoMensaje,
                contextInfo: { isForwarded: false } 
            }, { newsletterJid: config.idCanal });
       } else {
            await sock.sendMessage(config.idCanal, { text: msg }, sendOptions);
            await sock.sendMessage(config.idCanal, { 
                text: cuerpoMensaje,
                contextInfo: { isForwarded: false }
            }, { newsletterJid: config.idCanal });
       }
       console.log(`🚀 ${esPrueba?'Prueba enviada':'Publicado'}: ${noticia.banda}`);
   } catch (err) {
        console.log("❌ Fallo en el envío al canal:", err.message);
        console.log("❌ Error crítico en el socket de WhatsApp:", err.message);
   }
}

async function iniciar() {
   const { state, saveCreds } = await useMultiFileAuthState('sesion_bot');
   const { version } = await fetchLatestBaileysVersion();
    const sock = makeWASocket({ version, logger: pino({ level: "silent" }), auth: state, printQRInTerminal: false, browser: ["Ubuntu", "Chrome", "20.0.04"] });
    
    // Configuración de socket optimizada para estabilidad
    const sock = makeWASocket({ 
        version, 
        logger: pino({ level: "silent" }), 
        auth: state, 
        printQRInTerminal: false, 
        browser: ["Ubuntu", "Chrome", "20.0.04"],
        generateHighQualityLinkPreview: true
    });

   sock.ev.on("connection.update", async (up) => {
       const { connection, lastDisconnect } = up;
