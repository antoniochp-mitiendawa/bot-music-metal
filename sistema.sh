#!/data/data/com.termux/files/usr/bin/bash

# --- CONFIGURACIÓN DE PUNTOS DE CONTROL ---
# Estos archivos invisibles permiten que el script "recuerde" su progreso
PASO1_BASE=".sistema_base_ok"
PASO2_MOTOR=".motor_ia_ok"

echo "🤖 [SISTEMA] Iniciando Secuencia de Instalación Automatizada..."

# ==========================================
# PASO 1: CIMENTACIÓN (ESTRICTAMENTE BLINDADO)
# ==========================================
# Este bloque no se toca, es el que ya confirmamos que funciona.
if [ -f "$PASO1_BASE" ]; then
    echo "✅ [MEMORIA] Paso 1 (Sistema Base) ya verificado. Saltando..."
else
    echo "🛠️  Ejecutando Paso 1: Preparación Crítica de Termux..."
    
    # Configuración de repositorios y actualización forzada
    pkg update -y -o Dpkg::Options::="--force-confold"
    pkg upgrade -y -o Dpkg::Options::="--force-confold"
    
    # Instalación de herramientas de comunicación
    pkg install -y git openssl wget
    
    # Verificación de éxito del Paso 1
    if command -v git >/dev/null 2>&1; then
        touch "$PASO1_BASE"
        echo "✅ Paso 1 Finalizado con éxito."
    else
        echo "❌ ERROR CRÍTICO en Paso 1. Abortando instalación."
        exit 1
    fi
fi

# ==========================================
# PASO 2: MOTOR DE EJECUCIÓN E IA (AUTOMÁTICO)
# ==========================================
# El script pasa aquí inmediatamente después de terminar el Paso 1
if [ -f "$PASO2_MOTOR" ]; then
    echo "✅ [MEMORIA] Paso 2 (Motores e IA) ya verificado. Saltando..."
else
    echo "⚙️  Iniciando Paso 2: Instalación de Motores (Node.js, Python, FFmpeg)..."
    
    # Instalación silenciosa de los lenguajes para el Bot y la IA
    pkg install -y nodejs-lts python ffmpeg libsqlite
    
    # Verificación técnica de los motores recién instalados
    if command -v node >/dev/null 2>&1 && command -v python >/dev/null 2>&1; then
        
        # Creación de la estructura de datos persistente para la IA del dueño
        mkdir -p datos_ia
        
        touch "$PASO2_MOTOR"
        echo "------------------------------------------------"
        echo "✅ PASO 2 COMPLETADO: Motores e IA configurados."
        echo "------------------------------------------------"
    else
        echo "❌ ERROR: No se pudieron validar los motores en el Paso 2."
        exit 1
    fi
fi

# ==========================================
# CIERRE DE SECUENCIA
# ==========================================
echo "------------------------------------------------"
echo "🚀 [SISTEMA] Secuencia completa al 100%."
echo "Todos los pasos activos han sido validados."
echo "------------------------------------------------"
