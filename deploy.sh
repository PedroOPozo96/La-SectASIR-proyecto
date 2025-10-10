#!/bin/bash

# ========================================
# Script de Despliegue - La SectASIR (versión corregida)
# ========================================

# Colores
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

HTML_REPO="../La-SectASIR-html"

print_header() { echo -e "\n${BLUE}==== $1 ====${NC}\n"; }
print_step()   { echo -e "${CYAN}==>${NC} $1"; }
print_success(){ echo -e "${GREEN}✓${NC} $1"; }
print_error()  { echo -e "${RED}✗${NC} $1"; }
print_warning(){ echo -e "${YELLOW}!${NC} $1"; }

clear
print_header "Despliegue - La SectASIR"

# ========================================
# VERIFICACIONES INICIALES
# ========================================
print_step "Verificando entorno..."

if [ ! -f "_config.yml" ]; then
  print_error "No se encuentra _config.yml. Ejecuta el script desde la raíz del proyecto Jekyll."
  exit 1
fi

if [ ! -d "$HTML_REPO" ]; then
  print_error "No existe el directorio destino: $HTML_REPO"
  exit 1
fi

print_success "Entorno verificado"

# ========================================
# COMPROBAR CAMBIOS
# ========================================
print_step "Verificando cambios en el repositorio fuente..."

if [[ -z $(git status -s) ]]; then
  print_warning "No hay cambios pendientes."
  read -p "¿Deseas forzar el despliegue de todas formas? (s/n): " force
  [[ "$force" =~ ^[sS]$ ]] || exit 0
fi

# ========================================
# MENSAJE DE COMMIT
# ========================================
read -p "Introduce el mensaje del commit (Enter para usar mensaje por defecto): " commit_message
[[ -z "$commit_message" ]] && commit_message="Actualización del sitio - $(date '+%d/%m/%Y %H:%M:%S')"

# ========================================
# GENERAR SITIO
# ========================================
print_header "Generando sitio con Jekyll"

bundle exec jekyll build
if [ $? -ne 0 ]; then
  print_error "Error al generar el sitio con Jekyll"
  exit 1
fi
print_success "Sitio generado correctamente"

# ========================================
# SINCRONIZAR CON REPO HTML (sin borrar recursos extra)
# ========================================
print_step "Sincronizando _site con el repositorio HTML..."

rsync -av --delete --exclude='.git' _site/ "$HTML_REPO/" >/dev/null 2>&1

if [ $? -eq 0 ]; then
  print_success "Sincronización completada sin eliminar recursos extra"
else
  print_error "Error durante la sincronización con el repositorio HTML"
  exit 1
fi

# ========================================
# COMMIT EN REPO FUENTE
# ========================================
print_step "Guardando cambios en repositorio fuente..."

git add .
if git diff --staged --quiet; then
  print_warning "No hay cambios para commit en el repositorio fuente"
else
  git commit -m "$commit_message"
  print_success "Commit realizado en repo fuente"
fi

read -p "¿Hacer push al repositorio fuente remoto? (s/n): " push_src
if [[ "$push_src" =~ ^[sS]$ ]]; then
  print_step "Haciendo push al repositorio fuente..."
  git push origin main && print_success "Push completado" || print_error "Error al hacer push"
fi

# ========================================
# DEPLOY PRODUCCIÓN
# ========================================
print_step "Desplegando en producción..."
cd "$HTML_REPO" || exit 1

if [ ! -d ".git" ]; then
  print_error "El directorio HTML no es un repositorio Git."
  exit 1
fi

git add .
if git diff --staged --quiet; then
  print_warning "No hay cambios nuevos en producción."
  cd - >/dev/null
  exit 0
fi

git commit -m "$commit_message"

read -p "¿Hacer push al repositorio HTML remoto (producción)? (s/n): " push_prod
if [[ "$push_prod" =~ ^[sS]$ ]]; then
  print_step "Haciendo push a producción..."
  git push origin main && print_success "Despliegue completado" || print_error "Error en push a producción"
else
  print_warning "Push omitido"
fi

cd - >/dev/null
print_header "✓ Despliegue completado correctamente"
