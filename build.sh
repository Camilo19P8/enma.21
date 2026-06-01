#!/bin/bash
# Script de compilación personalizado para Vercel

# 1. Clonar el SDK de Flutter si no está en cache
if [ ! -d "flutter" ]; then
  echo "Clonando Flutter SDK (versión 3.35.6)..."
  git clone https://github.com/flutter/flutter.git --depth 1 -b 3.35.6
fi

# 2. Generar el archivo .env dinámicamente con las variables seguras de Vercel
echo "Generando archivo .env..."
echo "GROQ_API_KEY=$GROQ_API_KEY" > .env
echo "GROQ_MODEL=$GROQ_MODEL" >> .env

# 3. Habilitar soporte Web y compilar en modo Release
echo "Configurando Flutter..."
./flutter/bin/flutter config --enable-web

echo "Compilando aplicación para la Web..."
./flutter/bin/flutter build web --release
