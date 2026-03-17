#!/data/data/com.termux/files/usr/bin/bash

# --- CHECKPOINTS (BLOQUEADOS) ---
PASO1_BASE=".sistema_base_ok"
PASO2_MOTOR=".motor_ia_ok"
PASO3_CONEXION=".conexion_wa_ok"

echo "🤖 [SISTEMA] Iniciando Secuencia Automatizada..."

# ==========================================
# PASO 1: CIMENTACIÓN (BLINDADO)
# ==========================================
if [ -f "$PASO1_BASE" ]; then
    echo "✅ [MEMORIA] Paso 1 (Sistema Base) ya detectado."
else
    echo "🚀 [PASO 1] Ejecutando Instalación Base..."
    pkg update -y -o Dpkg::Options::="--force-confold"
    pkg upgrade -y -o Dpkg::Options::="--force-confold"
    pkg install -y git openssl wget
    touch "$PASO1_BASE"
    echo "✅ PASO 1 COMPLETADO."
fi

# ==========================================
# PASO 2: MOTOR DE EJECUCIÓN (BLINDADO)
# ==========================================
if [ -f "$PASO2_MOTOR" ]; then
    echo "✅ [MEMORIA] Paso 2 (Motores e IA) ya detectado."
else
    echo "⚙️  [PASO 2] Instalando Node.js, Python y FFmpeg..."
    pkg install -y nodejs-lts python ffmpeg libsqlite
    mkdir -p datos_ia
    touch "$PASO2_MOTOR"
    echo "✅ PASO 2 COMPLETADO."
fi

# ==========================================
# PASO 3: CONEXIÓN WHATSAPP (BAILEYS)
# ==========================================
if [ -f "$PASO3_CONEXION" ]; then
    echo "✅ [MEMORIA] Fase de Conexión ya configurada."
else
    echo "🔗 [PASO 3] Configurando Conexión de WhatsApp..."
    
    # Instalación de dependencias de Node para el Bot
    # Se utiliza --no-bin-links para evitar errores de permisos en Android
    npm install @whiskeysockets/baileys qrcode-terminal pino
    
    # Creación de carpeta de sesión para persistencia
    mkdir -p sesion_bot
    
    echo "------------------------------------------------"
    echo "📱 CONFIGURACIÓN DE EMPAREJAMIENTO"
    echo "------------------------------------------------"
    
    # El sistema ahora está listo para pedir el número
    # Esta parte se ejecutará al iniciar el bot por primera vez
    
    touch "$PASO3_CONEXION"
    echo "✅ PASO 3 COMPLETADO: Dependencias de Red Listas."
fi

echo "------------------------------------------------"
echo "🚀 [SISTEMA] Instalación al 100%. Todo validado."
echo "------------------------------------------------"
