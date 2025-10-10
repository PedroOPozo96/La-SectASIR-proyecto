#!/bin/bash

# ========================================
# Script de Despliegue - La SectASIR
# ========================================
# Despliega los cambios en ambos repositorios
# sin crear nuevos posts
# ========================================

# Colores
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

# Directorio del repositorio HTML
HTML_REPO="../La-SectASIR-html"

# Funciones de mensajes
print_header() {
    echo -e "${BLUE}========================================${NC}"
    echo -e "${BLUE}  $1${NC}"
    echo -e "${BLUE}========================================${NC}\n"
}

print_step() {
    echo -e "${CYAN}==>${NC} $1"
}

print_success() {
    echo -e "${GREEN}✓${NC} $1"
}

print_error() {
    echo -e "${RED}✗${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}!${NC} $1"
}

# Banner
clear
print_header "Despliegue - La SectASIR"

# ========================================
# VERIFICACIONES INICIALES
# ========================================
print_step "Verificando entorno..."

if [ ! -f "_config.yml" ]; then
    print_error "No se encuentra _config.yml"
    echo "Este script debe ejecutarse desde la raíz del proyecto Jekyll"
    exit 1
fi

if [ ! -d "$HTML_REPO" ]; then
    print_error "No existe el directorio: $HTML_REPO"
    echo "Crea el repositorio HTML primero"
    exit 1
fi

print_success "Entorno verificado\n"

# ========================================
# VERIFICAR CAMBIOS
# ========================================
print_step "Verificando cambios en el repositorio fuente..."

if [[ -z $(git status -s) ]]; then
    print_warning "No hay cambios en el repositorio fuente"
    echo ""
    echo -e "${YELLOW}¿Deseas regenerar y desplegar de todas formas? (s/n):${NC}"
    read force_deploy
    
    if [ "$force_deploy" != "s" ] && [ "$force_deploy" != "S" ]; then
        print_warning "Despliegue cancelado"
        exit 0
    fi
else
    git status --short
    echo ""
fi

# ========================================
# MENSAJE DE COMMIT
# ========================================
echo -e "${YELLOW}Introduce el mensaje del commit (Enter para usar mensaje por defecto):${NC}"
read commit_message

if [ -z "$commit_message" ]; then
    commit_message="Actualización del sitio - $(date '+%d/%m/%Y %H:%M:%S')"
fi

# ========================================
# GENERAR SITIO
# ========================================
print_header "Generando Sitio"

print_step "Ejecutando Jekyll build..."

bundle exec jekyll build

if [ $? -ne 0 ]; then
    print_error "Error al generar el sitio"
    exit 1
fi

print_success "Sitio generado correctamente\n"

# ========================================
# COPIAR A REPOSITORIO HTML
# ========================================



# Sin borrar todo el repositorio, sincroniza los cambios
print_step "Sincronizando archivos con el repositorio HTML..."

rsync -av --delete --exclude='.git' _site/ "$HTML_REPO/"

if [ $? -eq 0 ]; then
    print_success "Archivos sincronizados correctamente"
else
    print_error "Error al sincronizar archivos"
    exit 1
fi



# ========================================
# COMMIT EN REPOSITORIO FUENTE
# ========================================
print_step "Guardando cambios en repositorio fuente..."

git add .

# Verificar si hay cambios para commitear
if git diff --staged --quiet; then
    print_warning "No hay cambios para hacer commit en repo fuente"
else
    git commit -m "$commit_message"
    
    if [ $? -eq 0 ]; then
        print_success "Commit realizado en repo fuente"
        
        echo -e "${YELLOW}¿Hacer push al repositorio fuente remoto? (s/n):${NC}"
        read push_source
        
        if [ "$push_source" = "s" ] || [ "$push_source" = "S" ]; then
            print_step "Haciendo push en repo fuente..."
            git push origin main
            
            if [ $? -eq 0 ]; then
                print_success "Push completado en repo fuente"
            else
                print_error "Error al hacer push en repo fuente"
            fi
        fi
    else
        print_error "Error al hacer commit en repo fuente"
    fi
fi

echo ""

# ========================================
# DESPLEGAR EN PRODUCCIÓN
# ========================================
print_step "Desplegando en producción..."

cd "$HTML_REPO"

# Verificar si es un repositorio git
if [ ! -d ".git" ]; then
    print_error "El directorio $HTML_REPO no es un repositorio git"
    echo "Inicializa el repositorio con:"
    echo "  cd $HTML_REPO"
    echo "  git init"
    echo "  git remote add origin <URL-repositorio-remoto>"
    cd - > /dev/null
    exit 1
fi

git add .

# Verificar si hay cambios para desplegar
if git diff --staged --quiet; then
    print_warning "No hay cambios para desplegar en producción"
    cd - > /dev/null
    exit 0
fi

git commit -m "$commit_message"

# Push a producción
echo -e "${YELLOW}¿Hacer push al repositorio de producción? (s/n):${NC}"
read push_prod

if [ "$push_prod" = "s" ] || [ "$push_prod" = "S" ]; then
    print_step "Haciendo push a producción..."
    git push origin main
    
    if [ $? -eq 0 ]; then
        print_success "Despliegue completado exitosamente"
    else
        print_error "Error al desplegar"
        cd - > /dev/null
        exit 1
    fi
else
    print_warning "Push a producción omitido"
fi

cd - > /dev/null

# ========================================
# RESUMEN FINAL
# ========================================
echo ""
print_header "✓ Despliegue Completado"

echo -e "${GREEN}Cambios desplegados exitosamente${NC}"
echo -e "  ${CYAN}Mensaje:${NC} $commit_message"
echo ""

# Obtener URL del sitio
if [ -f "_config.yml" ]; then
    site_url=$(grep "^url:" _config.yml | awk '{print $2}' | tr -d '"' | tr -d "'")
    if [ ! -z "$site_url" ]; then
        echo -e "${GREEN}Tu sitio se está actualizando en:${NC} ${BLUE}${site_url}${NC}"
        echo -e "${YELLOW}Nota: Puede tardar unos minutos en verse reflejado en Render${NC}"
    fi
fi

echo ""
