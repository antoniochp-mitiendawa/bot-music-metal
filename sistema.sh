#!/data/data/com.termux/files/usr/bin/bash

# --- CONFIGURACIÓN DE AUTO-GESTIÓN ---
REPO_NAME="bot-music-metal"
CHECK_BASE=".sistema_base_ok"

echo "🤖 [SISTEMA] Iniciando Automatización Total - Fase 1"

# 1. AUTO-UBICACIÓN Y CLONACIÓN (Mantenimiento de Carpeta)
# El script verifica si ya está dentro de la carpeta del proyecto.
if [[ "$(basename "$PWD")" != "$REPO_NAME" ]]; then
    if [ -d "$REPO_NAME" ]; then
        echo "📂 Carpeta detectada. Entrando..."
        cd "$REPO_NAME" || exit 1
    else
        echo "📥 El script no está en la carpeta raíz. Reubicando..."
        # Aquí es donde el script se clonaría a sí mismo si fuera necesario, 
        # pero para esta prueba inicial, asumimos que ya estás en el entorno de Git.
    fi
fi

# 2. GESTIÓN AUTOMÁTICA DE PERMISOS DE ALMACENAMIENTO
if [ ! -d ~/storage ]; then
    echo "📂 Solicitando permisos de Android (Favor de aceptar en pantalla)..."
    termux-setup-storage
    sleep 5
else
    echo "✅ Acceso a almacenamiento: OK"
fi

# 3. LÓGICA DE INTELIGENCIA (Punto de Control)
if [ -f "$CHECK_BASE" ]; then
    # Verificación técnica de los binarios instalados
    if command -v python >/dev/null 2>&1 && command -v node >/dev/null 2>&1 && command -v git >/dev/null 2>&1; then
        echo "✅ Fase 1 ya fue completada y verificada anteriormente. Nada que hacer."
        echo "ESTADO: Listo para recibir instrucciones de la Fase 2."
        exit 0
    else
        echo "⚠️  Marcador corrupto o herramientas faltantes. Iniciando REPARACIÓN..."
        rm "$CHECK_BASE"
    fi
fi

# 4. INSTALACIÓN DE INFRAESTRUCTURA BASE
echo "🛠️  Instalando dependencias críticas (Python, Node, Git, FFmpeg)..."

# Actualización silenciosa y forzada de repositorios
pkg update -y -o Dpkg::Options::="--force-confold"
pkg upgrade -y -o Dpkg::Options::="--force-confold"

# Instalación de paquetes necesarios
pkg install -y python nodejs-lts git ffmpeg openssl libsqlite wget

# 5. VALIDACIÓN FINAL Y SELLADO
if command -v python >/dev/null 2>&1 && command -v node >/dev/null 2>&1 && command -v git >/dev/null 2>&1; then
    touch "$CHECK_BASE"
    echo "------------------------------------------------"
    echo "✅ FASE 1 COMPLETADA EXITOSAMENTE"
    echo "El sistema ha sido blindado y el marcador ha sido creado."
    echo "------------------------------------------------"
else
    echo "❌ ERROR CRÍTICO: La instalación falló. Verifica tu conexión."
    exit 1
fi
