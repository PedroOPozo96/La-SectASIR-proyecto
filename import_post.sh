#!/bin/bash

# ========================================
# Script de Importación desde Notion
# La SectASIR
# ========================================
# Importa posts exportados desde Notion
# con sus imágenes y archivos adjuntos
# ========================================

# Colores
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
NC='\033[0m'

# Directorios
IMAGES_DIR="assets/img/posts"
TEMP_DIR="/tmp/notion-import"

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
print_header "Importar desde Notion"

# ========================================
# VERIFICACIONES INICIALES
# ========================================
print_step "Verificando entorno..."

if [ ! -f "_config.yml" ]; then
    print_error "No se encuentra _config.yml"
    echo "Este script debe ejecutarse desde la raíz del proyecto Jekyll"
    exit 1
fi

# Crear directorios necesarios
mkdir -p "$IMAGES_DIR"
mkdir -p "$TEMP_DIR"
mkdir -p "_posts"

print_success "Entorno verificado\n"

# ========================================
# SELECCIONAR ARCHIVO/CARPETA DE NOTION
# ========================================
print_header "Origen de la Importación"

echo -e "${CYAN}Opciones:${NC}"
echo -e "${GREEN}[1]${NC} Importar un archivo Markdown único"
echo -e "${YELLOW}[2]${NC} Importar una carpeta exportada de Notion (con imágenes)"
echo ""

read -p "Selecciona una opción: " import_option

if [ "$import_option" = "1" ]; then
    # ========================================
    # IMPORTAR ARCHIVO ÚNICO
    # ========================================
    echo -e "\n${YELLOW}Arrastra el archivo .md aquí y presiona Enter:${NC}"
    read -e source_file
    
    # Limpiar path (quitar comillas si las tiene)
    source_file=$(echo "$source_file" | sed "s/^'//" | sed "s/'$//" | sed 's/^"//' | sed 's/"$//')
    
    if [ ! -f "$source_file" ]; then
        print_error "El archivo no existe: $source_file"
        exit 1
    fi
    
    has_images=false
    
elif [ "$import_option" = "2" ]; then
    # ========================================
    # IMPORTAR CARPETA COMPLETA
    # ========================================
    echo -e "\n${YELLOW}Arrastra la carpeta exportada de Notion aquí y presiona Enter:${NC}"
    read -e source_folder
    
    # Limpiar path
    source_folder=$(echo "$source_folder" | sed "s/^'//" | sed "s/'$//" | sed 's/^"//' | sed 's/"$//')
    
    if [ ! -d "$source_folder" ]; then
        print_error "La carpeta no existe: $source_folder"
        exit 1
    fi
    
    # Buscar archivo .md en la carpeta
    md_files=("$source_folder"/*.md)
    
    if [ ! -f "${md_files[0]}" ]; then
        print_error "No se encontró ningún archivo .md en la carpeta"
        exit 1
    fi
    
    source_file="${md_files[0]}"
    has_images=true
    
    print_success "Archivo encontrado: $(basename "$source_file")"
    
else
    print_error "Opción inválida"
    exit 1
fi

# ========================================
# EXTRAER INFORMACIÓN DEL ARCHIVO
# ========================================
print_step "Analizando archivo..."

# Obtener título del archivo o del contenido
file_title=$(head -1 "$source_file" | sed 's/^# //')

if [ -z "$file_title" ]; then
    file_title=$(basename "$source_file" .md)
fi

echo -e "\n${CYAN}Título detectado:${NC} $file_title"
echo -e "${YELLOW}¿Usar este título? (s/n):${NC}"
read use_title

if [ "$use_title" != "s" ] && [ "$use_title" != "S" ]; then
    echo -e "${YELLOW}Introduce el nuevo título:${NC}"
    read file_title
fi

# Crear slug
post_slug=$(echo "$file_title" | iconv -t ascii//TRANSLIT | sed -r 's/[^a-zA-Z0-9]+/-/g' | sed -r 's/^-+\|-+$//g' | tr A-Z a-z)

# Fecha
current_date=$(date +%Y-%m-%d)
current_datetime=$(date +"%Y-%m-%d %H:%M:%S %z")

# Nombre del post
post_filename="_posts/${current_date}-${post_slug}.md"

# ========================================
# CATEGORÍAS Y ETIQUETAS
# ========================================
echo -e "\n${YELLOW}Introduce las categorías (separadas por coma):${NC}"
echo -e "${CYAN}Ejemplos: Sistemas Linux, Redes, Seguridad${NC}"
read categories_input

if [ -z "$categories_input" ]; then
    categories="[General]"
else
    IFS=',' read -ra CATS <<< "$categories_input"
    categories="["
    for i in "${!CATS[@]}"; do
        cat=$(echo "${CATS[$i]}" | xargs)
        if [ $i -eq 0 ]; then
            categories="${categories}${cat}"
        else
            categories="${categories}, ${cat}"
        fi
    done
    categories="${categories}]"
fi

echo -e "\n${YELLOW}Introduce las etiquetas (separadas por coma):${NC}"
echo -e "${CYAN}Ejemplos: linux, debian, tutorial, redes${NC}"
read tags_input

if [ -z "$tags_input" ]; then
    tags="[]"
else
    IFS=',' read -ra TAGS <<< "$tags_input"
    tags="["
    for i in "${!TAGS[@]}"; do
        tag=$(echo "${TAGS[$i]}" | xargs | tr '[:upper:]' '[:lower:]')
        if [ $i -eq 0 ]; then
            tags="${tags}${tag}"
        else
            tags="${tags}, ${tag}"
        fi
    done
    tags="${tags}]"
fi

# ========================================
# PROCESAR IMÁGENES
# ========================================
if [ "$has_images" = true ]; then
    print_step "Procesando imágenes..."
    
    # Crear subdirectorio para las imágenes de este post
    post_images_dir="$IMAGES_DIR/$post_slug"
    mkdir -p "$post_images_dir"
    
    # Copiar todas las imágenes
    image_count=0
    
    for img in "$source_folder"/*.{png,jpg,jpeg,gif,webp,PNG,JPG,JPEG,GIF,WEBP} 2>/dev/null; do
        if [ -f "$img" ]; then
            img_name=$(basename "$img")
            cp "$img" "$post_images_dir/"
            ((image_count++))
            echo -e "  ${GREEN}✓${NC} $img_name"
        fi
    done
    
    if [ $image_count -gt 0 ]; then
        print_success "Se copiaron $image_count imagen(es)\n"
    else
        print_warning "No se encontraron imágenes\n"
    fi
fi

# ========================================
# CREAR POST CON FRONTMATTER
# ========================================
print_step "Creando post..."

# Crear archivo temporal
temp_post="$TEMP_DIR/temp_post.md"

# Escribir frontmatter
cat > "$temp_post" << EOF
---
title: $file_title
date: $current_datetime
categories: $categories
tags: $tags
---

EOF

# Obtener contenido del archivo original (sin el título si es la primera línea)
if head -1 "$source_file" | grep -q "^# "; then
    tail -n +2 "$source_file" >> "$temp_post"
else
    cat "$source_file" >> "$temp_post"
fi

# ========================================
# AJUSTAR RUTAS DE IMÁGENES
# ========================================
if [ "$has_images" = true ]; then
    print_step "Ajustando rutas de imágenes..."
    
    # Reemplazar rutas de imágenes de Notion por rutas Jekyll
    # Notion usa: ![nombre](archivo.png)
    # Jekyll usa: ![nombre](/assets/img/posts/slug/archivo.png)
    
    sed -i "s|!\[\(.*\)\](\([^)]*\)\.\(png\|jpg\|jpeg\|gif\|webp\))|![\1](/assets/img/posts/$post_slug/\2.\3)|gi" "$temp_post"
    
    print_success "Rutas de imágenes actualizadas"
fi

# Mover al directorio de posts
mv "$temp_post" "$post_filename"

print_success "Post creado: $post_filename\n"

# ========================================
# VISTA PREVIA
# ========================================
echo -e "${YELLOW}¿Quieres ver una vista previa del post? (s/n):${NC}"
read preview

if [ "$preview" = "s" ] || [ "$preview" = "S" ]; then
    echo -e "\n${CYAN}Vista previa de las primeras líneas:${NC}"
    echo -e "${BLUE}========================================${NC}"
    head -30 "$post_filename"
    echo -e "${BLUE}========================================${NC}\n"
fi

# ========================================
# EDITAR POST
# ========================================
echo -e "${YELLOW}¿Quieres editar el post antes de publicar? (s/n):${NC}"
read edit_post

if [ "$edit_post" = "s" ] || [ "$edit_post" = "S" ]; then
    if command -v code &> /dev/null; then
        code "$post_filename"
    elif command -v nano &> /dev/null; then
        nano "$post_filename"
    elif command -v vim &> /dev/null; then
        vim "$post_filename"
    fi
    
    echo -e "\n${YELLOW}Presiona Enter cuando termines de editar...${NC}"
    read
fi

# ========================================
# PUBLICAR
# ========================================
echo -e "\n${YELLOW}¿Deseas publicar este post ahora? (s/n):${NC}"
read publish

if [ "$publish" != "s" ] && [ "$publish" != "S" ]; then
    print_warning "Post guardado pero no publicado"
    echo "Archivo: $post_filename"
    if [ "$has_images" = true ]; then
        echo "Imágenes: $post_images_dir"
    fi
    exit 0
fi

# Generar sitio
print_step "Generando sitio..."
bundle exec jekyll build

if [ $? -ne 0 ]; then
    print_error "Error al generar el sitio"
    exit 1
fi

print_success "Sitio generado\n"

# Desplegar si existe el script
if [ -f "./deploy.sh" ]; then
    echo -e "${YELLOW}¿Ejecutar despliegue automático? (s/n):${NC}"
    read auto_deploy
    
    if [ "$auto_deploy" = "s" ] || [ "$auto_deploy" = "S" ]; then
        ./deploy.sh
    fi
else
    print_warning "No se encontró deploy.sh"
    echo "Despliega manualmente con: ./deploy.sh"
fi

# ========================================
# RESUMEN FINAL
# ========================================
echo ""
print_header "✓ Importación Completada"

echo -e "${GREEN}Post importado exitosamente:${NC}"
echo -e "  ${CYAN}Título:${NC} $file_title"
echo -e "  ${CYAN}Archivo:${NC} $post_filename"
echo -e "  ${CYAN}Categorías:${NC} $categories"
echo -e "  ${CYAN}Etiquetas:${NC} $tags"

if [ "$has_images" = true ]; then
    echo -e "  ${CYAN}Imágenes:${NC} $image_count copiadas a $post_images_dir"
fi

echo ""
