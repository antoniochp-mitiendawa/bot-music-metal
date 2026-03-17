#!/data/data/com.termux/files/usr/bin/bash

echo "🧹 Iniciando limpieza total de Termux..."
# Borramos cualquier rastro de carpetas que se llamen igual para empezar de cero
rm -rf ~/bot-music-metal
rm -rf ~/node_modules
rm -rf ~/.npm

echo "⚙️ Configurando repositorios oficiales..."
# Esto asegura que Termux busque en los servidores correctos
termux-setup-storage
pkg update -y && pkg upgrade -y

echo "✅ Sistema actualizado. Esperando siguiente paso."
