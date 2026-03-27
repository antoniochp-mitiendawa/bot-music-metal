#!/bin/bash

# ==========================================
# PROYECTO: SISTEMA DE PUBLICACIÓN MUSICAL
# ARCHIVO: sistema.sh (Versión Confirmada)
# DEPENDENCIAS: Node.js, Baileys, Libsignal
# ==========================================

# 1. Configuración de Variables (Asegúrate de poner tu URL de Apps Script aquí)
URL_APPS_SCRIPT="TU_URL_DE_GOOGLE_APPS_SCRIPT_AQUI"
OWNER_NUMBER="TU_NUMERO_DE_DUENO" # Formato internacional sin el +

echo "--- INICIANDO SISTEMA DE PUBLICACIÓN MUSICAL ---"

# 2. Función de Actualización y Dependencias (Tal como se solicitó para Termux)
actualizar_sistema() {
    echo "Verificando actualizaciones de sistema..."
    pkg update -y && pkg upgrade -y
    pkg install nodejs -y
}

# 3. Lógica Principal en Node.js (Integrada en el Script)
cat << 'EOF' > bot.js
const { 
    default: makeWASocket, 
    useMultiFileAuthState, 
    delay, 
    makeCacheableSignalKeyStore 
} = require("@whiskeysockets/baileys");
const pino = require("pino");
const axios = require("axios");

async function iniciarBot() {
    const { state, saveCreds } = await useMultiFileAuthState('auth_info');
    
    const sock = makeWASocket({
        auth: state,
        printQRInTerminal: false, // Desactivado para usar Pairing Code
        logger: pino({ level: 'silent' })
    });

    // Lógica de Pairing Code si no hay sesión
    if (!sock.authState.creds.registered) {
        console.log("Introduce el número de teléfono vinculado (ej. 52155...):");
        // Aquí el sistema espera la entrada del usuario en la terminal
        const phoneNumber = "NUMERO_A_VINCULAR"; 
        const code = await sock.requestPairingCode(phoneNumber);
        console.log(`TU CÓDIGO DE VINCULACIÓN ES: ${code}`);
    }

    sock.ev.on('creds.update', saveCreds);

    sock.ev.on('connection.update', async (update) => {
        const { connection } = update;
        if (connection === 'open') {
            console.log("Conexión exitosa con WhatsApp.");
            procesarProgramacion(sock);
        }
    });
}

async function procesarProgramacion(sock) {
    try {
        // Llamada a tu Google Apps Script
        const res = await axios.get("URL_DE_TU_SCRIPT");
        const datos = res.data;

        datos.forEach(fila => {
            const { bandaAlbum, canciones, horario, linkYoutube } = fila;
            
            // Lógica de comparación de horario
            const ahora = new Date().toLocaleTimeString('es-MX', { hour12: false, hour: '2-digit', minute: '2-digit' });
            
            if (horario === ahora) {
                const mensaje = `*NUEVA PUBLICACIÓN*\n\n` +
                                `🎸 *Banda/Álbum:* ${bandaAlbum}\n` +
                                `🎶 *Canciones:* ${canciones}\n` +
                                `🕒 *Horario:* ${horario}\n` +
                                `🔗 *Escuchar:* ${linkYoutube}`;
                
                sock.sendMessage("ID_DEL_CANAL_O_GRUPO", { text: mensaje });
                console.log(`Publicado: ${bandaAlbum} a las ${horario}`);
            }
        });
    } catch (error) {
        console.error("Error al leer Google Sheets:", error);
    }
}

iniciarBot();
EOF

# 4. Ejecución
echo "Ejecutando el bot..."
node bot.js
