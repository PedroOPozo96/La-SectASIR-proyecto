#!/bin/bash

# ========================================
# Script de Eliminación de Posts
# La SectASIR
# ========================================
# Automatiza:
# 1. Selección y eliminación de post
# 2. Regeneración del sitio
# 3. Commit en repo fuente
# 4. Commit y push en repo de producción
# ========================================

# Colores
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
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
print_header "Eliminar Post - La SectASIR"

# ========================================
# VERIFICACIONES INICIALES
# ========================================
print_step "Verificando entorno..."

if [ ! -f "_config.yml" ]; then
    print_error "No se encuentra _config.yml"
    echo "Este script debe ejecutarse desde la raíz del proyecto Jekyll"
    exit 1
fi

if [ ! -d "_posts" ]; then
    print_error "No existe la carpeta _posts"
    exit 1
fi

print_success "Entorno verificado\n"

# ========================================
# LISTAR POSTS DISPONIBLES
# ========================================
print_header "Posts Disponibles"

# Contar posts
post_count=$(find _posts -name "*.md" -o -name "*.markdown" | wc -l)

if [ $post_count -eq 0 ]; then
    print_warning "No hay posts para eliminar"
    exit 0
fi

echo -e "${CYAN}Se encontraron $post_count post(s)${NC}\n"

# Crear array con los posts
posts_array=()
counter=1

while IFS= read -r post; do
    # Obtener nombre del archivo sin ruta
    filename=$(basename "$post")
    
    # Extraer título del frontmatter (más flexible)
    title=$(awk '/^title:/ {$1=""; print $0}' "$post" | head -1 | sed 's/^[[:space:]]*//' | tr -d '"' | tr -d "'")
    
    # Extraer fecha
    date=$(awk '/^date:/ {print $2}' "$post" | head -1)
    
    # Extraer categorías
    categories=$(awk '/^categories:/ {$1=""; print $0}' "$post" | head -1 | sed 's/^[[:space:]]*//')
    
    # Si no hay título, usar el nombre del archivo
    if [ -z "$title" ]; then
        title="$filename"
    fi
    
    # Guardar en array
    posts_array+=("$post")
    
    # Mostrar en formato bonito
    echo -e "${MAGENTA}[$counter]${NC} ${GREEN}$title${NC}"
    echo -e "    ${CYAN}Archivo:${NC} $filename"
    if [ ! -z "$date" ]; then
        echo -e "    ${CYAN}Fecha:${NC} $date"
    fi
    if [ ! -z "$categories" ]; then
        echo -e "    ${CYAN}Categorías:${NC} $categories"
    fi
    echo ""
    
    ((counter++))
done < <(find _posts -type f \( -name "*.md" -o -name "*.markdown" \) 2>/dev/null | sort -r)

# ========================================
# SELECCIONAR POST A ELIMINAR
# ========================================
echo -e "${YELLOW}Introduce el número del post que deseas eliminar (0 para cancelar):${NC}"
read post_number

# Validar entrada
if ! [[ "$post_number" =~ ^[0-9]+$ ]]; then
    print_error "Entrada inválida. Debe ser un número."
    exit 1
fi

if [ $post_number -eq 0 ]; then
    print_warning "Operación cancelada"
    exit 0
fi

if [ $post_number -lt 1 ] || [ $post_number -gt ${#posts_array[@]} ]; then
    print_error "Número fuera de rango"
    exit 1
fi

# Obtener el post seleccionado (array empieza en 0)
selected_post="${posts_array[$((post_number-1))]}"
post_filename=$(basename "$selected_post")

# Extraer info del post para mostrar (más flexible)
post_title=$(awk '/^title:/ {$1=""; print $0}' "$selected_post" | head -1 | sed 's/^[[:space:]]*//' | tr -d '"' | tr -d "'")
if [ -z "$post_title" ]; then
    post_title="$post_filename"
fi

# ========================================
# CONFIRMACIÓN
# ========================================
echo ""
print_warning "¡ATENCIÓN! Vas a eliminar el siguiente post:"
echo -e "${CYAN}Título:${NC} $post_title"
echo -e "${CYAN}Archivo:${NC} $post_filename"
echo ""

echo -e "${RED}¿Estás seguro de que deseas eliminarlo? (s/n):${NC}"
read confirm

if [ "$confirm" != "s" ] && [ "$confirm" != "S" ]; then
    print_warning "Operación cancelada"
    exit 0
fi

# Confirmación adicional
echo -e "${RED}Esta acción no se puede deshacer. ¿Continuar? (escribe 'ELIMINAR' para confirmar):${NC}"
read final_confirm

if [ "$final_confirm" != "ELIMINAR" ]; then
    print_warning "Operación cancelada"
    exit 0
fi

# ========================================
# ELIMINAR POST
# ========================================
print_header "Eliminando Post"

print_step "Eliminando archivo: $post_filename"

rm "$selected_post"

if [ $? -eq 0 ]; then
    print_success "Post eliminado del repositorio fuente"
else
    print_error "Error al eliminar el post"
    exit 1
fi

echo ""

# ========================================
# REGENERAR SITIO
# ========================================
print_step "Regenerando sitio estático..."

bundle exec jekyll build

if [ $? -ne 0 ]; then
    print_error "Error al generar el sitio"
    echo "El post fue eliminado pero el sitio no se regeneró correctamente"
    exit 1
fi

print_success "Sitio regenerado\n"

# ========================================
# COPIAR A REPOSITORIO HTML
# ========================================
print_step "Actualizando repositorio HTML..."

if [ ! -d "$HTML_REPO" ]; then
    print_error "No existe el directorio: $HTML_REPO"
    exit 1
fi

# IMPORTANTE: Verificar que _site existe y tiene contenido
if [ ! -d "_site" ] || [ -z "$(ls -A _site 2>/dev/null)" ]; then
    print_error "El directorio _site está vacío o no existe"
    print_error "No se actualizará el repositorio HTML para evitar perder contenido"
    exit 1
fi

# Hacer backup del .git antes de limpiar
if [ -d "$HTML_REPO/.git" ]; then
    print_step "Haciendo backup del repositorio git..."
    cp -r "$HTML_REPO/.git" "/tmp/.git-backup-$(date +%s)"
fi

# Eliminar contenido anterior (excepto .git)
print_step "Limpiando directorio HTML (manteniendo .git)..."
find "$HTML_REPO" -mindepth 1 -maxdepth 1 ! -name '.git' -exec rm -rf {} + 2>/dev/null

# Copiar todo el contenido de _site
print_step "Copiando nuevo contenido..."
cp -r _site/* "$HTML_REPO/" 2>/dev/null

if [ $? -eq 0 ]; then
    print_success "Repositorio HTML actualizado"
    
    # Verificar que se copió algo
    file_count=$(find "$HTML_REPO" -mindepth 1 -maxdepth 1 ! -name '.git' | wc -l)
    echo -e "  ${CYAN}Archivos copiados: $file_count${NC}"
    
    if [ $file_count -eq 0 ]; then
        print_error "¡ERROR! No se copió ningún archivo"
        print_error "Restaurando desde backup..."
        # Aquí podrías restaurar el backup si es necesario
        exit 1
    fi
else
    print_error "Error al actualizar repositorio HTML"
    exit 1
fi

echo ""

# ========================================
# COMMIT EN REPOSITORIO FUENTE
# ========================================
print_step "Guardando cambios en repositorio fuente..."

git add .

commit_message="Eliminar post: ${post_title}"

git commit -m "$commit_message"

if [ $? -eq 0 ]; then
    print_success "Commit realizado en repo fuente"
    
    echo -e "${YELLOW}¿Hacer push al repositorio fuente remoto? (s/n):${NC}"
    read push_source
    
    if [ "$push_source" = "s" ] || [ "$push_source" = "S" ]; then
        git push origin main
        if [ $? -eq 0 ]; then
            print_success "Push completado en repo fuente"
        else
            print_error "Error al hacer push en repo fuente"
        fi
    fi
else
    print_warning "Error en commit del repo fuente"
fi

echo ""

# ========================================
# DESPLEGAR EN PRODUCCIÓN
# ========================================
print_step "Desplegando cambios en producción..."

cd "$HTML_REPO"

if [ ! -d ".git" ]; then
    print_error "El directorio $HTML_REPO no es un repositorio git"
    cd - > /dev/null
    exit 1
fi

git add .

if [[ -z $(git status -s) ]]; then
    print_warning "No hay cambios para desplegar"
    cd - > /dev/null
    exit 0
fi

git commit -m "$commit_message"

git push origin main

if [ $? -eq 0 ]; then
    print_success "Cambios desplegados en producción"
else
    print_error "Error al desplegar"
    cd - > /dev/null
    exit 1
fi

cd - > /dev/null

# ========================================
# RESUMEN FINAL
# ========================================
echo ""
print_header "✓ Post Eliminado"

echo -e "${GREEN}Post eliminado exitosamente:${NC}"
echo -e "  ${CYAN}Título:${NC} $post_title"
echo -e "  ${CYAN}Archivo:${NC} $post_filename"
echo ""

if [ -f "_config.yml" ]; then
    site_url=$(grep "^url:" _config.yml | awk '{print $2}' | tr -d '"' | tr -d "'")
    if [ ! -z "$site_url" ]; then
        echo -e "${GREEN}Los cambios se están actualizando en:${NC} ${BLUE}${site_url}${NC}"
        echo -e "${YELLOW}Nota: Puede tardar unos minutos en verse reflejado${NC}"
    fi
fi

echo ""
