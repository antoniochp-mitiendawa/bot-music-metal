# Activar persistencia
termux-wake-lock

# --- CHECKPOINTS (PROHIBIDO MODIFICAR - BLINDADO TOTAL) [cite: 1-5] ---
# --- CHECKPOINTS (PROHIBIDO MODIFICAR - BLINDADO TOTAL)  ---
PASO1_BASE=".sistema_base_ok"
PASO2_MOTOR=".motor_ia_ok"

if [ -f "$PASO1_BASE" ]; then
if [ -f "$PASO1_BASE" ];
then
echo "✅ [MEMORIA] Paso 1 listo."
else
pkg update -y -o Dpkg::Options::="--force-confold"
@@ -16,7 +17,8 @@ else
touch "$PASO1_BASE"
fi

if [ -f "$PASO2_MOTOR" ]; then
if [ -f "$PASO2_MOTOR" ];
then
echo "✅ [MEMORIA] Paso 2 listo."
else
pkg install -y nodejs-lts python ffmpeg libsqlite
@@ -27,7 +29,7 @@ else
fi

# ==========================================
# MOTOR DE IA Y GESTIÓN DE AGENDA (ARCHIVO ÚNICO) [cite: 6-41]
# MOTOR DE IA Y GESTIÓN DE AGENDA (ARCHIVO ÚNICO)
# ==========================================
cat << 'EOF' > bot_metal.js
const { 
@@ -68,7 +70,6 @@ function limpiarHorario(dato) {
}

async function investigarBandaPro(noticia) {
    // Base de datos local para evitar bloqueos de red en la validación [cite: 13-17]
   const databaseMetal = {
       "Septicflesh": { pais: "Grecia 🇬🇷", historia: "Pioneros del Death Metal Sinfónico." },
       "Rotting Christ": { pais: "Grecia 🇬🇷", historia: "Leyendas del Dark Metal." }
@@ -87,7 +88,6 @@ async function sincronizarConGoogle() {
           ...item,
           horarioLimpio: limpiarHorario(item.horario)
       })).filter(i => i.banda && i.horarioLimpio);
        
       fs.writeFileSync(LOCAL_DB, JSON.stringify(agenda));
       console.log(`📅 Agenda: ${agenda.length} bandas programadas.`);
       agenda.forEach(a => console.log(`   ⏰ ${a.horarioLimpio} -> ${a.banda}`));
@@ -105,12 +105,12 @@ async function dispararPublicacion(sock, noticia, esPrueba = false) {
   const info = await investigarBandaPro(noticia);
   const tit = esPrueba ? 'PRUEBA DE INSTALACIÓN' : 'NUEVO LANZAMIENTO 2026';
   const msg = `🎸 *${tit}* 🤘\n\n📢 *Disco:* ${noticia.banda}\n🌎 *Origen:* ${info.pais}\n📜 *Historia:* ${info.historia}${info.tracks}\n\n🔗 *Video:* ${noticia.youtube}`;
    

   try {
        await sock.sendMessage(config.idCanal, { text: msg, linkPreview: { "canonical-url": noticia.youtube } });
        await sock.sendMessage(config.idCanal, { text: msg });
       console.log(`🚀 ${esPrueba ? 'Mensaje de prueba enviado.' : 'Publicado: ' + noticia.banda}`);
   } catch (err) { 
        console.log("❌ Error en el envío a WhatsApp."); 
        console.log("❌ Error en el envío a WhatsApp.");
   }
}

@@ -132,22 +132,19 @@ async function iniciar() {
       } else if (connection === "open") {
           console.log("\n✅ ¡SISTEMA VINCULADO CORRECTAMENTE!");
           let config = obtenerConfig();
            
            // Configuración de Canal e ID [cite: 29-32]
          
           if (!config.idCanal) {
               const url = await question("👉 Pega la liga de tu Canal (URL): ");
               let id = url.trim().includes("channel/") ? url.split("/").pop() + "@newsletter" : url.trim() + "@newsletter";
               console.log(`✅ ID detectado: ${id}`);
               guardarConfig({ idCanal: id });
           }

            // Configuración de Google Sheets [cite: 33]
           if (!config.urlGoogle) {
               const url = await question("👉 Pega la URL de tu App Script: ");
               guardarConfig({ urlGoogle: url.trim(), esPrimeraVez: true });
           }
           
            // Carga inicial y mensaje de prueba 
           const agenda = await sincronizarConGoogle();
           config = obtenerConfig();

@@ -157,7 +154,6 @@ async function iniciar() {
               guardarConfig({ esPrimeraVez: false });
           }

            // Motor de disparo por minuto [cite: 36-37]
           cron.schedule('* * * * *', async () => {
               const ahora = new Date().toLocaleTimeString('es-MX', { 
                   hour12: false, hour: '2-digit', minute: '2-digit', timeZone: 'America/Mexico_City' 
@@ -173,12 +169,10 @@ async function iniciar() {
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
