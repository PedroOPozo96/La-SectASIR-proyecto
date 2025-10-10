#!/bin/bash

# ========================================
# Script para eliminar un post y redeploy
# ========================================

RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

HTML_REPO="../La-SectASIR-html"

print_step()   { echo -e "${CYAN}==>${NC} $1"; }
print_success(){ echo -e "${GREEN}✓${NC} $1"; }
print_error()  { echo -e "${RED}✗${NC} $1"; }

clear
echo -e "${BLUE}===== ELIMINAR POST - La SectASIR =====${NC}\n"

# ========================================
# SELECCIÓN DE POST
# ========================================
print_step "Listando posts disponibles:"
POSTS=( _posts/*.md )

if [ ${#POSTS[@]} -eq 0 ]; then
  print_error "No hay posts en la carpeta _posts"
  exit 1
fi

for i in "${!POSTS[@]}"; do
  echo "$((i+1)). ${POSTS[$i]}"
done

read -p "Selecciona el número del post a eliminar: " num
((num--))
POST="${POSTS[$num]}"

if [ ! -f "$POST" ]; then
  print_error "El archivo seleccionado no existe"
  exit 1
fi

read -p "¿Seguro que deseas eliminar '$POST'? (s/n): " confirm
[[ "$confirm" =~ ^[sS]$ ]] || exit 0

# ========================================
# ELIMINACIÓN
# ========================================
rm "$POST"
print_success "Post eliminado: $POST"

# ========================================
# REGENERAR SITIO Y DESPLEGAR
# ========================================
print_step "Regenerando sitio..."
bundle exec jekyll build || { print_error "Error al generar el sitio"; exit 1; }

print_step "Sincronizando cambios con repositorio HTML..."
rsync -av --delete --exclude='.git' _site/ "$HTML_REPO/" >/dev/null 2>&1
print_success "Sincronización completada"

# Commit local
git add .
git commit -m "Eliminado post $(basename "$POST")" >/dev/null 2>&1
print_success "Commit realizado en repo fuente"

# Push opcional
read -p "¿Hacer push al repositorio remoto fuente? (s/n): " push_src
if [[ "$push_src" =~ ^[sS]$ ]]; then
  git push origin main && print_success "Push completado" || print_error "Error al hacer push"
fi

# Deploy producción
cd "$HTML_REPO" || exit 1
git add .
git commit -m "Eliminado post $(basename "$POST")" >/dev/null 2>&1

read -p "¿Hacer push al repositorio HTML remoto (producción)? (s/n): " push_html
if [[ "$push_html" =~ ^[sS]$ ]]; then
  git push origin main && print_success "Despliegue actualizado" || print_error "Error al hacer push"
else
  print_step "Push omitido"
fi

cd - >/dev/null
print_success "Post eliminado y sitio actualizado correctamente"
