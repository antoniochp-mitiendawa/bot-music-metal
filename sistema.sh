#!/data/data/com.termux/files/usr/bin/bash

# --- CONFIGURACIÓN DE PUNTOS DE CONTROL ---
# Este archivo oculto es la memoria del sistema para el Paso 1.
PASO1_BASE=".sistema_base_ok"

echo "🤖 [SISTEMA] Iniciando Verificación de Fase 1..."

# 1. GESTIÓN AUTOMÁTICA DE PERMISOS
# Verifica si existe el enlace al almacenamiento de Android.
if [ ! -d ~/storage ]; then
    echo "📂 Solicitando permisos de almacenamiento..."
    termux-setup-storage
    sleep 4 
else
    echo "✅ Permisos de almacenamiento: OK"
fi

# 2. LÓGICA DE INTELIGENCIA Y MEMORIA
if [ -f "$PASO1_BASE" ]; then
    # El marcador existe, pero validamos que los binarios respondan realmente.
    if command -v python >/dev/null 2>&1 && command -v node >/dev/null 2>&1 && command -v git >/dev/null 2>&1; then
        echo "✅ El Paso 1 ya está verificado y completo. No se requiere acción."
    else
        echo "⚠️  Marcador presente pero herramientas ausentes o dañadas. Reparando..."
        rm "$PASO1_BASE"
        pkg update -y && pkg upgrade -y
        pkg install -y python nodejs-lts git ffmpeg openssl libsqlite wget
        touch "$PASO1_BASE"
        echo "✅ Reparación de Fase 1 finalizada con éxito."
    fi
else
    echo "🛠️  Instalando Sistema Base (Python, Node, Git, FFmpeg)..."
    
    # Configuración de repositorios para evitar errores 404 y actualización
    pkg update -y && pkg upgrade -y
    
    # Instalación de los paquetes fundamentales
    pkg install -y python nodejs-lts git ffmpeg openssl libsqlite wget

    # VERIFICACIÓN TÉCNICA FINAL
    # Solo si los tres comandos principales responden, se crea el punto de control.
    if command -v python >/dev/null 2>&1 && command -v node >/dev/null 2>&1 && command -v git >/dev/null 2>&1; then
        touch "$PASO1_BASE"
        echo "✅ Fase 1 terminada con éxito. Sistema blindado y listo."
    else
        echo "❌ ERROR CRÍTICO: No se pudieron validar las herramientas base. Reintenta."
        exit 1
    fi
fi

echo "------------------------------------------------"
echo "ESTADO: Fase 1 OK. Esperando validación del usuario."
echo "------------------------------------------------"
