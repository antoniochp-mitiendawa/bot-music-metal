#!/data/data/com.termux/files/usr/bin/bash
termux-wake-lock

# --- CHECKPOINTS (PROHIBIDO MODIFICAR) ---
# --- CHECKPOINTS DE INSTALACIÓN (BLINDADOS) ---
PASO1_BASE=".sistema_base_ok"
PASO2_MOTOR=".motor_ia_ok"

@@ -64,7 +64,7 @@ async function sincronizarConGoogle() {
       const { data } = await axios.get(config.urlGoogle);
       const agenda = data.map(i => ({ ...i, horarioLimpio: limpiarHorario(i.horario) })).filter(i => i.banda && i.horarioLimpio);
       fs.writeFileSync(LOCAL_DB, JSON.stringify(agenda));
        console.log(`📅 Agenda: ${agenda.length} bandas listas.`);
        console.log(`📅 Agenda Actualizada: ${agenda.length} registros.`);
       return agenda;
   } catch (e) { return fs.existsSync(LOCAL_DB) ? JSON.parse(fs.readFileSync(LOCAL_DB)) : []; }
}
@@ -73,8 +73,9 @@ async function dispararPublicacion(sock, noticia, esPrueba = false) {
   const config = obtenerConfig();
   if (!config.idCanal) return;

    console.log(`⏳ Intentando enviar a canal: ${noticia.banda}...`);
   await sock.sendPresenceUpdate('composing', config.idCanal);
    await delay(10000); 
    await delay(esPrueba ? 2000 : 8000); 

   const emojiPais = banderas[noticia.pais] || "🌎";
   const msg = `${getSpin('intro')}\n\n` +
@@ -85,15 +86,20 @@ async function dispararPublicacion(sock, noticia, esPrueba = false) {
               `${getSpin('tracks_label')}\n_${noticia.tracks}_\n\n` +
               `${getSpin('link_label')} ${noticia.youtube}`;

    if (noticia.imagen && noticia.imagen.startsWith('http')) {
        try {
    try {
        // TRATAMIENTO ESPECIAL PARA CANALES (NEWSLETTERS)
        const sendOptions = { newsletterJid: config.idCanal };

        if (noticia.imagen && noticia.imagen.startsWith('http')) {
           const res = await axios.get(noticia.imagen, { responseType: 'arraybuffer' });
            await sock.sendMessage(config.idCanal, { image: Buffer.from(res.data), caption: msg });
        } catch (e) { await sock.sendMessage(config.idCanal, { text: msg }); }
    } else {
        await sock.sendMessage(config.idCanal, { text: msg });
            await sock.sendMessage(config.idCanal, { image: Buffer.from(res.data), caption: msg }, sendOptions);
        } else {
            await sock.sendMessage(config.idCanal, { text: msg }, sendOptions);
        }
        console.log(`🚀 ${esPrueba?'Prueba enviada':'Publicado'}: ${noticia.banda}`);
    } catch (err) {
        console.log("❌ Fallo en el envío al canal:", err.message);
   }
    console.log(`🚀 ${esPrueba?'Prueba enviada':'Publicado'}: ${noticia.banda}`);
}

async function iniciar() {
