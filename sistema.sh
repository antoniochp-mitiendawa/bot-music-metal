const spintax = {
   intro: ["🔥 *¡ALERTA DE ESTRENO!*", "🤘 *NOVEDAD BRUTAL*", "⚡ *IMPACTO METALERO*"],
   bio_label: ["📜 *Trasfondo:*", "📖 *La Historia:*", "🔍 *Análisis:*"],
    tracks_label: ["💿 *Setlist:*", "🎶 *Tracks:*"],
    link_label: ["🎥 *Video Oficial:*", "🔗 *Ver en YouTube:*"]
    tracks_label: ["💿 *Setlist del Álbum:*", "🎶 *Tracks Destacados:*"],
    link_label: ["🎥 *Video Oficial:*", "🔗 *Mira el video aquí:*"]
};
const getSpin = (t) => spintax[t][Math.floor(Math.random() * spintax[t].length)];

@@ -62,11 +62,7 @@ async function sincronizarConGoogle() {
   if (!config.urlGoogle) return [];
   try {
       const { data } = await axios.get(config.urlGoogle);
        // Sincronización completa de 8 columnas
        const agenda = data.map(i => ({ 
            ...i, 
            horarioLimpio: limpiarHorario(i.horario) 
        })).filter(i => i.banda && i.horarioLimpio);
        const agenda = data.map(i => ({ ...i, horarioLimpio: limpiarHorario(i.horario) })).filter(i => i.banda && i.horarioLimpio);
       fs.writeFileSync(LOCAL_DB, JSON.stringify(agenda));
       console.log(`📅 Agenda: ${agenda.length} bandas listas.`);
       return agenda;
@@ -78,7 +74,7 @@ async function dispararPublicacion(sock, noticia, esPrueba = false) {
   if (!config.idCanal) return;

   await sock.sendPresenceUpdate('composing', config.idCanal);
    await delay(7000); 
    await delay(10000); 

   const emojiPais = banderas[noticia.pais] || "🌎";
   const msg = `${getSpin('intro')}\n\n` +
