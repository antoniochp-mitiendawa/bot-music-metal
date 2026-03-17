#!/data/data/com.termux/files/usr/bin/bash

echo "🚀 [PASO 1] Iniciando Preparación de Termux desde Cero..."

# 1. Configurar repositorios para evitar fallos de conexión
termux-change-repo

# 2. Actualización total del sistema (Responde 'SÍ' a todo automáticamente)
pkg update -y -o Dpkg::Options::="--force-confold"
pkg upgrade -y -o Dpkg::Options::="--force-confold"

# 3. Instalación de la herramienta base para GitHub
pkg install -y git openssl wget

# 4. Verificación de éxito
if command -v git >/dev/null 2>&1; then
    echo "------------------------------------------------"
    echo "✅ PASO 1 COMPLETADO: Git está instalado."
    echo "Ahora el sistema ya puede comunicarse con GitHub."
    echo "------------------------------------------------"
else
    echo "❌ ERROR: No se pudo instalar Git. Revisa tu conexión."
    exit 1
fi
