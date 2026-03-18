#!/data/data/com.termux/files/usr/bin/bash

# --- ARCHIVOS DE CONTROL (CHECKPOINTS) ---
PASO1_BASE=".sistema_base_ok"
PASO2_MOTOR=".motor_ia_ok"

echo "🤖 [SISTEMA] Iniciando Secuencia Automatizada..."

# ==========================================
# PASO 1: CIMENTACIÓN (BLINDADO)
# ==========================================
if [ -f "$PASO1_BASE" ]; then
    echo "✅ [MEMORIA] Paso 1 (Sistema Base) ya detectado. Saltando al siguiente paso..."
else
    echo "🚀 [PASO 1] Ejecutando Instalación Base..."
    
    # Comandos validados del Paso 1
    pkg update -y -o Dpkg::Options::="--force-confold"
    pkg upgrade -y -o Dpkg::Options::="--force-confold"
    pkg install -y git openssl wget
    
    # Verificación de éxito para crear el seguro
    if command -v git >/dev/null 2>&1; then
        touch "$PASO1_BASE"
        echo "------------------------------------------------"
        echo "✅ PASO 1 COMPLETADO: Git instalado."
        echo "------------------------------------------------"
    else
        echo "❌ ERROR en Paso 1. Abortando."
        exit 1
    fi
fi

# ==========================================
# PASO 2: MOTOR DE EJECUCIÓN (AUTOMÁTICO)
# ==========================================
if [ -f "$PASO2_MOTOR" ]; then
    echo "✅ [MEMORIA] Paso 2 (Motores e IA) ya detectado."
else
    echo "⚙️  [PASO 2] Instalando Node.js, Python y FFmpeg..."
    
    # Instalación de los motores requeridos
    pkg install -y nodejs-lts python ffmpeg libsqlite
    
    # Verificación de éxito del Paso 2
    if command -v node >/dev/null 2>&1 && command -v python >/dev/null 2>&1; then
        # Carpeta para persistencia de datos de la IA
        mkdir -p datos_ia
        
        touch "$PASO2_MOTOR"
        echo "------------------------------------------------"
        echo "✅ PASO 2 COMPLETADO: Motores e IA listos."
        echo "------------------------------------------------"
    else
        echo "❌ ERROR en Paso 2: No se instalaron los motores."
        exit 1
    fi
fi

echo "🚀 [SISTEMA] Proceso finalizado al 100%."
