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

# Comprobar si la clave es de Groq o xAI
if [[ "$GROQ_API_KEY" =~ ^gsk_ ]]; then
  echo "Clave detectada como Groq (GSK)."
  # Si el modelo está vacío o contiene "grok", cambiar a llama-3.3-70b-versatile
  if [ -z "$GROQ_MODEL" ] || [[ "$GROQ_MODEL" =~ grok ]]; then
    echo "Modelo inválido para Groq detectado. Usando llama-3.3-70b-versatile por defecto."
    echo "GROQ_MODEL=llama-3.3-70b-versatile" >> .env
  else
    echo "GROQ_MODEL=$GROQ_MODEL" >> .env
  fi
else
  echo "Clave detectada como xAI o por defecto."
  # Si GROQ_MODEL es grok-beta o está vacío, usar grok-2 por defecto
  if [ "$GROQ_MODEL" = "grok-beta" ] || [ -z "$GROQ_MODEL" ]; then
    echo "Modelo detectado como grok-beta o vacío. Usando grok-2 por defecto."
    echo "GROQ_MODEL=grok-2" >> .env
  else
    echo "GROQ_MODEL=$GROQ_MODEL" >> .env
  fi
fi

# 3. Habilitar soporte Web y compilar en modo Release
echo "Configurando Flutter..."
./flutter/bin/flutter config --enable-web

echo "Compilando aplicación para la Web..."
./flutter/bin/flutter build web --release
