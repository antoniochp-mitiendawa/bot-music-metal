}

const obtenerEmoji = () => {
    const emojis = ["🤘", "🔥", "🎸", "💀", "⚰️", "⚡", "🥁", "🌑", "⛓️", "🔊"];
    const emojis = ["🤘", "🔥", "🎸", "💀", "⚡", "🥁", "🌑", "⛓️"];
   return emojis[Math.floor(Math.random() * emojis.length)];
};

@@ -49,12 +49,11 @@ async function sincronizarAgenda(url) {
       console.log("📥 Sincronizando agenda desde Google Sheets...");
       const { data } = await axios.get(url);
       fs.writeFileSync(AGENDA_PATH, JSON.stringify(data, null, 2));
        console.log("✅ Agenda guardada localmente en el teléfono.");
        console.log("✅ Agenda guardada localmente.");
       return data;
   } catch (e) {
       console.log("❌ Error al sincronizar: " + e.message);
       if (fs.existsSync(AGENDA_PATH)) {
            console.log("⚠️ Usando última agenda guardada localmente.");
           return JSON.parse(fs.readFileSync(AGENDA_PATH));
       }
       return [];
@@ -94,7 +93,6 @@ async function iniciar() {
                       if (!configActualizada.urlGoogle) {
                           const url = await question("\n👉 PASO 3: Pega la URL de tu App Script: ");
                           guardarConfig({ urlGoogle: url.trim() });
                            console.log("✅ Configuración guardada.");
                           await sincronizarAgenda(url.trim());
                       }
                       sock.ev.off("messages.upsert", mensajeHandler);
@@ -107,11 +105,11 @@ async function iniciar() {
               await sincronizarAgenda(url.trim());
           }

            console.log("📅 Cargando agenda local del teléfono...");
           if (config.urlGoogle) {
               await sincronizarAgenda(config.urlGoogle);
           }

            // --- LÓGICA DE PUBLICACIÓN PROGRAMADA ---
           cron.schedule('* * * * *', async () => {
               const conf = obtenerConfig();
               if (!fs.existsSync(AGENDA_PATH) || !conf.idCanal) return;
@@ -123,25 +121,24 @@ async function iniciar() {

               for (const item of agendaLocal) {
                   if (item.horario === ahora) {
                        console.log(`🚀 Iniciando secuencia de publicación para: ${item.banda}`);
                        console.log(`🚀 Preparando publicación: ${item.banda}`);

                        // 1. Activar estado "Escribiendo..."
                        // 1. Activar estado Typing
                       await sock.sendPresenceUpdate('composing', conf.idCanal);

                        // 2. Espera de 14 segundos para realismo y previsualización nativa
                        // 2. Retraso de 14 segundos para previsualización nativa
                       await delay(14000);

                        // 3. Construcción del mensaje con Spintax y Emojis
                        const intro = spintax("{🔥 ¡NUEVO ESTRENO!|🤘 ¡NOTICIA METALERA!|🎸 RECIÉN SALIDO DEL HORNO|💀 METAL ALERT|⚡ NOVEDAD RECOMENDADA}");
                        const labelBanda = spintax("{📢 Banda|🎸 Grupo|🔥 Artista|🌑 Proyecto}");
                        const labelTracks = spintax("{💿 Tracks|🎶 Lista de canciones|🎼 Temas|⛓️ Repertorio}");

                        const cuerpo = `${obtenerEmoji()} *${intro}* ${obtenerEmoji()}\n\n` +
                                       `${obtenerEmoji()} *${labelBanda}:* ${item.banda}\n` +
                                       `${obtenerEmoji()} *${labelTracks}:* ${item.tracks}\n\n` +
                                       `🎥 *Video:* ${item.youtube}`;
                        // 3. Construcción del Mensaje (Nueva Jerarquía: Link Arriba)
                        const intro = spintax("{🔥 ¡NUEVO ESTRENO!|🤘 ¡NOTICIA METALERA!|🎸 RECIÉN SALIDO|💀 METAL ALERT|⚡ NOVEDAD RECOMENDADA}");
                        const emojiCabecera = obtenerEmoji();
                        
                        const cuerpo = `${emojiCabecera} *${intro}*\n` +
                                       `${item.youtube}\n\n` + // Link arriba para forzar preview
                                       `🎸 *Banda:* ${item.banda}\n` +
                                       `💿 *Tracks:* ${item.tracks}`;

                        // 4. Envío de texto plano (WhatsApp generará el preview automáticamente)
                        // 4. Envío de texto plano (WhatsApp detecta el link arriba)
                       await sock.sendMessage(conf.idCanal, { text: cuerpo });

                       // 5. Finalizar estado de presencia
@@ -162,7 +159,7 @@ async function iniciar() {

   if (!sock.authState.creds.registered) {
       await delay(5000);
        const numero = await question("👉 Introduce tu número (con código de país, ej: 521...): ");
        const numero = await question("👉 Introduce tu número (521...): ");
       const codigo = await sock.requestPairingCode(numero.trim());
       console.log(`\n🔑 CÓDIGO DE VINCULACIÓN: ${codigo}\n`);
   }
