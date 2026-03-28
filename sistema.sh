   });
}

const obtenerEmoji = () => {
const r = () => {
   const emojis = ["🤘", "🔥", "🎸", "💀", "⚡", "🥁", "🌑", "⛓️"];
   return emojis[Math.floor(Math.random() * emojis.length)];
};

const evideo = () => {
    const emjV = ["🎥", "🎬", "📺", "📼", "📀"];
    return emjV[Math.floor(Math.random() * emjV.length)];
};

// --- SINCRONIZACIÓN INTELIGENTE (GOOGLE SHEETS) ---
async function sincronizarAgenda(url) {
    if (!url) return;
   try {
        console.log("📥 Sincronizando agenda desde Google Sheets...");
        console.log("📥 [8:00 AM] Sincronizando agenda desde Google Sheets...");
       const { data } = await axios.get(url);
       fs.writeFileSync(AGENDA_PATH, JSON.stringify(data, null, 2));
        console.log("✅ Agenda guardada localmente.");
        console.log("✅ Datos guardados localmente. No habrá más peticiones a Google hoy.");
       return data;
   } catch (e) {
        console.log("❌ Error al sincronizar: " + e.message);
        if (fs.existsSync(AGENDA_PATH)) {
            return JSON.parse(fs.readFileSync(AGENDA_PATH));
        }
        return [];
        console.log("❌ Error de red: Usando base de datos local.");
        return fs.existsSync(AGENDA_PATH) ? JSON.parse(fs.readFileSync(AGENDA_PATH)) : [];
   }
}

@@ -81,6 +85,11 @@ async function iniciar() {
           console.log("\n✅ SISTEMA METAL CONECTADO Y VINCULADO");
           let config = obtenerConfig();

            // Sincronización inicial solo si no hay agenda
            if (!fs.existsSync(AGENDA_PATH) && config.urlGoogle) {
                await sincronizarAgenda(config.urlGoogle);
            }

           if (!config.idCanal) {
               console.log("\n👉 PASO 2: Envía un mensaje a tu CANAL para capturar el ID.");
               const mensajeHandler = async (m) => {
@@ -99,17 +108,15 @@ async function iniciar() {
                   }
               };
               sock.ev.on("messages.upsert", mensajeHandler);
            } else if (!config.urlGoogle) {
                const url = await question("\n👉 PASO EXTRA: Pega la URL de tu App Script: ");
                guardarConfig({ urlGoogle: url.trim() });
                await sincronizarAgenda(url.trim());
           }

            if (config.urlGoogle) {
                await sincronizarAgenda(config.urlGoogle);
            }
            // CRON 1: Sincronización ÚNICA a las 8:00 AM
            cron.schedule('0 8 * * *', async () => {
                const conf = obtenerConfig();
                await sincronizarAgenda(conf.urlGoogle);
            });

            // --- LÓGICA DE PUBLICACIÓN PROGRAMADA ---
            // CRON 2: Verificación de publicaciones (Cada minuto en local)
           cron.schedule('* * * * *', async () => {
               const conf = obtenerConfig();
               if (!fs.existsSync(AGENDA_PATH) || !conf.idCanal) return;
@@ -121,29 +128,39 @@ async function iniciar() {

               for (const item of agendaLocal) {
                   if (item.horario === ahora) {
                        console.log(`🚀 Preparando publicación: ${item.banda}`);

                        // 1. Activar estado Typing
                        console.log(`🚀 Iniciando secuencia para: ${item.banda}`);
                        
                        // Typing y Delay de 14 segundos
                       await sock.sendPresenceUpdate('composing', conf.idCanal);

                        // 2. Retraso de 14 segundos para previsualización nativa
                       await delay(14000);

                        // 3. Construcción del Mensaje (Nueva Jerarquía: Link Arriba)
                        const intro = spintax("{🔥 ¡NUEVO ESTRENO!|🤘 ¡NOTICIA METALERA!|🎸 RECIÉN SALIDO|💀 METAL ALERT|⚡ NOVEDAD RECOMENDADA}");
                        const emojiCabecera = obtenerEmoji();
                        
                        const cuerpo = `${emojiCabecera} *${intro}*\n` +
                                       `${item.youtube}\n\n` + // Link arriba para forzar preview
                                       `🎸 *Banda:* ${item.banda}\n` +
                                       `💿 *Tracks:* ${item.tracks}`;

                        // 4. Envío de texto plano (WhatsApp detecta el link arriba)
                        await sock.sendMessage(conf.idCanal, { text: cuerpo });
                        // Spintax y Variedad
                        const txt = spintax("{🔥 ¡NUEVO ESTRENO!|🤘 ¡NOTICIA METALERA!|🎸 RECIÉN SALIDO|💀 METAL ALERT|⚡ NOVEDAD RECOMENDADA}");
                        const bnd = spintax("{📢 Banda|🎸 Grupo|🔥 Artista|🌑 Proyecto}");
                        const trk = spintax("{💿 Tracks|🎶 Lista de canciones|🎼 Repertorio|⛓️ Canciones}");
                        const vtxt = spintax("{Ver video oficial aquí:|Haz clic para el estreno:|Liga del video oficial:|Disfruta el nuevo material:}");

                        // Construcción con Jerarquía (Link arriba + 3 espacios)
                        const cuerpo = `${r()} *${txt}*\n\n\n` + 
                                       `${evideo()} _${vtxt}_\n` +
                                       `${item.youtube}\n\n` + 
                                       `${r()} *${bnd}:* ${item.banda}\n` +
                                       `${r()} *${trk}:* ${item.tracks}`;

                        await sock.sendMessage(conf.idCanal, { 
                            text: cuerpo,
                            contextInfo: {
                                externalAdReply: {
                                    title: item.banda,
                                    body: "Reproducir ahora",
                                    mediaType: 1,
                                    sourceUrl: item.youtube,
                                    thumbnailUrl: "https://img.youtube.com/vi/" + (item.youtube.split('v=')[1] || "").split('&')[0] + "/0.jpg"
                                }
                            }
                        });

                        // 5. Finalizar estado de presencia
                       await sock.sendPresenceUpdate('paused', conf.idCanal);
                        
                       await delay(2000);
                   }
               }
