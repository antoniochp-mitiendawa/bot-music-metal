#!/data/data/com.termux/files/usr/bin/bash

# --- CONFIGURACIÓN DE PUNTOS DE CONTROL ---
PASO1_BASE=".sistema_base_ok"
PASO2_MOTOR=".motor_ia_ok"

echo "🤖 [SISTEMA] Iniciando Secuencia Automatizada..."

# ==========================================
# PASO 1: CIMENTACIÓN (BLINDADO - NO TOCAR)
# ==========================================
if [ -f "$PASO1_BASE" ]; then
    echo "✅ PASO 1 (Sistema Base) ya está instalado. Continuando..."
else
    echo "🚀 [PASO 1] Iniciando Preparación de Termux desde Cero..."
    # Configurar repositorios para evitar fallos de conexión
    termux-change-repo
    # Actualización total del sistema (Responde 'SÍ' a todo automáticamente)
    pkg update -y -o Dpkg::Options::="--force-confold"
    pkg upgrade -y -o Dpkg::Options::="--force-confold"
    # Instalación de la herramienta base para GitHub
    pkg install -y git openssl wget
    
    if command -v git >/dev/null 2>&1; then
        touch "$PASO1_BASE"
        echo "------------------------------------------------"
        echo "✅ PASO 1 COMPLETADO: Git está instalado."
        echo "------------------------------------------------"
    else
        echo "❌ ERROR: No se pudo instalar Git."
        exit 1
    fi
fi

# ==========================================
# PASO 2: MOTOR DE EJECUCIÓN (NODE, PYTHON, IA)
# ==========================================
if [ -f "$PASO2_MOTOR" ]; then
    echo "✅ PASO 2 (Motores e IA) ya está instalado."
else
    echo "⚙️  Iniciando Paso 2: Instalación de Motores (Node.js, Python, FFmpeg)..."
    
    # Instalación de los lenguajes necesarios
    pkg install -y nodejs-lts python ffmpeg libsqlite

    # Verificación técnica de los motores
    if command -v node >/dev/null 2>&1 && command -v python >/dev/null 2>&1; then
        # Estructura para la IA que reconoce al dueño y sus datos
        mkdir -p datos_ia
        
        touch "$PASO2_MOTOR"
        echo "------------------------------------------------"
        echo "✅ PASO 2 COMPLETADO: Motores e IA listos."
        echo "------------------------------------------------"
    else
        echo "❌ ERROR: No se pudieron instalar los motores en el Paso 2."
        exit 1
    fi
fi

echo "🚀 [SISTEMA] Secuencia completa al 100%."
