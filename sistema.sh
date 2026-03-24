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
}#!/data/data/com.termux/files/usr/bin/bash
termux-wake-lock

# --- CHECKPOINTS DE INSTALACIÓN (BLINDADOS) ---
# --- CHECKPOINTS DE INSTALACIÓN ---
PASO1_BASE=".sistema_base_ok"
PASO2_MOTOR=".motor_ia_ok"

@@ -20,7 +20,7 @@ if [ ! -f "$PASO2_MOTOR" ]; then
fi

cat << 'EOF' > bot_metal.js
const { default: makeWASocket, useMultiFileAuthState, delay, fetchLatestBaileysVersion, DisconnectReason, getAggregateVotesInPollMessage } = require("@whiskeysockets/baileys");
const { default: makeWASocket, useMultiFileAuthState, delay, fetchLatestBaileysVersion, DisconnectReason } = require("@whiskeysockets/baileys");
const pino = require("pino");
const readline = require("readline");
const axios = require("axios");
@@ -64,7 +64,7 @@ async function sincronizarConGoogle() {
       const { data } = await axios.get(config.urlGoogle);
       const agenda = data.map(i => ({ ...i, horarioLimpio: limpiarHorario(i.horario) })).filter(i => i.banda && i.horarioLimpio);
       fs.writeFileSync(LOCAL_DB, JSON.stringify(agenda));
        console.log(`📅 Agenda Sincronizada: ${agenda.length} registros.`);
        console.log(`📅 Sincronizado: ${agenda.length} bandas.`);
       return agenda;
   } catch (e) { return fs.existsSync(LOCAL_DB) ? JSON.parse(fs.readFileSync(LOCAL_DB)) : []; }
}
@@ -73,12 +73,14 @@ async function dispararPublicacion(sock, noticia, esPrueba = false) {
   const config = obtenerConfig();
   if (!config.idCanal) return;

    console.log(`⏳ Procesando envío a Canal: ${noticia.banda}...`);
    console.log(`⏳ [Canal] Preparando publicación: ${noticia.banda}...`);
    
    // RESTAURADO: Simulación de escritura prolongada (vital para canales)
   await sock.sendPresenceUpdate('composing', config.idCanal);
    await delay(esPrueba ? 2000 : 10000); 
    await delay(esPrueba ? 5000 : 15000); 

   const emojiPais = banderas[noticia.pais] || "🌎";
    const cuerpoMensaje = `${getSpin('intro')}\n\n` +
    const msg = `${getSpin('intro')}\n\n` +
               `📢 *Banda:* _${noticia.banda}_\n` +
               `🎸 *Género:* ${noticia.genero}\n` +
               `🌎 *Origen:* ${noticia.pais} ${emojiPais}\n\n` +
@@ -87,47 +89,36 @@ async function dispararPublicacion(sock, noticia, esPrueba = false) {
               `${getSpin('link_label')} ${noticia.youtube}`;

   try {
        // CORRECCIÓN QUIRÚRGICA: Protocolo de Newsletters/Channels
        // MOTOR DE ENVÍO RESTAURADO (Protocolo Newsletter/Channel)
        const opcionesEnvio = { newsletterJid: config.idCanal };

       if (noticia.imagen && noticia.imagen.startsWith('http')) {
           const res = await axios.get(noticia.imagen, { responseType: 'arraybuffer' });
           await sock.sendMessage(config.idCanal, { 
               image: Buffer.from(res.data), 
                caption: cuerpoMensaje,
                contextInfo: { isForwarded: false } 
            }, { newsletterJid: config.idCanal });
                caption: msg 
            }, opcionesEnvio);
       } else {
            await sock.sendMessage(config.idCanal, { 
                text: cuerpoMensaje,
                contextInfo: { isForwarded: false }
            }, { newsletterJid: config.idCanal });
            await sock.sendMessage(config.idCanal, { text: msg }, opcionesEnvio);
       }
        console.log(`🚀 ${esPrueba?'Prueba enviada':'Publicado'}: ${noticia.banda}`);
        console.log(`🚀 Publicado con éxito: ${noticia.banda}`);
   } catch (err) {
        console.log("❌ Error crítico en el socket de WhatsApp:", err.message);
        console.log("❌ Error en el envío al canal:", err.message);
   }
}

async function iniciar() {
   const { state, saveCreds } = await useMultiFileAuthState('sesion_bot');
   const { version } = await fetchLatestBaileysVersion();
    
    // Configuración de socket optimizada para estabilidad
    const sock = makeWASocket({ 
        version, 
        logger: pino({ level: "silent" }), 
        auth: state, 
        printQRInTerminal: false, 
        browser: ["Ubuntu", "Chrome", "20.0.04"],
        generateHighQualityLinkPreview: true
    });
    const sock = makeWASocket({ version, logger: pino({ level: "silent" }), auth: state, printQRInTerminal: false, browser: ["Ubuntu", "Chrome", "20.0.04"] });

   sock.ev.on("connection.update", async (up) => {
       const { connection, lastDisconnect } = up;
       if (connection === "close") { 
           if (lastDisconnect?.error?.output?.statusCode !== DisconnectReason.loggedOut) iniciar(); 
       }
       else if (connection === "open") {
            console.log("\n✅ ¡SISTEMA METAL VINCULADO!");
            console.log("\n✅ SISTEMA CONECTADO");
           let config = obtenerConfig();

           if (!config.idCanal) {
@@ -136,7 +127,7 @@ async function iniciar() {
                   const msg = m.messages[0];
                   if (msg.key.remoteJid.endsWith("@newsletter") && !config.idCanal) {
                       const realID = msg.key.remoteJid;
                        console.log(`✅ ID REAL CAPTURADO: ${realID}`);
                        console.log(`✅ ID CAPTURADO: ${realID}`);
                       guardarConfig({ idCanal: realID });
                       config = obtenerConfig();
                       if (!config.urlGoogle) {
@@ -159,6 +150,7 @@ async function iniciar() {
                   const datos = JSON.parse(fs.readFileSync(LOCAL_DB));
                   for (const item of datos) { 
                       if (item.horarioLimpio === ahora) {
                            // Delay aleatorio extra para seguridad
                           setTimeout(() => dispararPublicacion(sock, item), Math.random() * 5000);
                       }
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
