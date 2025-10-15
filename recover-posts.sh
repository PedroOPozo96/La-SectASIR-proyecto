#!/bin/bash

# ========================================
# Script de Recuperación de Posts
# La SectASIR
# ========================================
# Busca posts que están en el HTML
# pero no en el repositorio fuente
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

clear
echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}  Recuperar Posts Perdidos${NC}"
echo -e "${BLUE}========================================${NC}\n"

# ========================================
# VERIFICACIONES
# ========================================
if [ ! -f "_config.yml" ]; then
    echo -e "${RED}✗${NC} Este script debe ejecutarse desde la raíz del proyecto"
    exit 1
fi

if [ ! -d "$HTML_REPO" ]; then
    echo -e "${RED}✗${NC} No se encuentra el repositorio HTML: $HTML_REPO"
    exit 1
fi

# ========================================
# BUSCAR POSTS EN EL SITIO HTML
# ========================================
echo -e "${CYAN}Buscando posts en el sitio web desplegado...${NC}\n"

# Buscar archivos HTML en el directorio posts del sitio generado
found_posts=0
posts_html=()

if [ -d "$HTML_REPO/posts" ]; then
    while IFS= read -r html_file; do
        if [ -f "$html_file" ]; then
            # Extraer el slug del post desde la URL
            post_slug=$(basename "$(dirname "$html_file")")
            
            # Buscar si existe en _posts
            post_exists=false
            
            for source_post in _posts/*.{md,markdown} 2>/dev/null; do
                if [ -f "$source_post" ]; then
                    source_filename=$(basename "$source_post" .md)
                    source_filename=$(basename "$source_filename" .markdown)
                    
                    # Comparar slug (sin la fecha)
                    source_slug=$(echo "$source_filename" | sed 's/^[0-9]\{4\}-[0-9]\{2\}-[0-9]\{2\}-//')
                    
                    if [ "$source_slug" = "$post_slug" ]; then
                        post_exists=true
                        break
                    fi
                fi
            done
            
            if [ "$post_exists" = false ]; then
                posts_html+=("$html_file")
                ((found_posts++))
            fi
        fi
    done < <(find "$HTML_REPO/posts" -name "index.html" 2>/dev/null)
fi

if [ $found_posts -eq 0 ]; then
    echo -e "${GREEN}✓ Todos los posts del sitio web están en el repositorio fuente${NC}"
    echo -e "${CYAN}No hay posts que recuperar${NC}"
    exit 0
fi

echo -e "${YELLOW}⚠ Se encontraron $found_posts post(s) en el sitio web que NO están en el repositorio fuente${NC}\n"

# ========================================
# LISTAR POSTS ENCONTRADOS
# ========================================
counter=1

for html_file in "${posts_html[@]}"; do
    # Extraer información del HTML
    post_slug=$(basename "$(dirname "$html_file")")
    
    # Intentar extraer el título del HTML
    title=$(grep -oP '<h1[^>]*>\K[^<]+' "$html_file" 2>/dev/null | head -1)
    
    if [ -z "$title" ]; then
        title="$post_slug"
    fi
    
    echo -e "${MAGENTA}[$counter]${NC} ${GREEN}$title${NC}"
    echo -e "    ${CYAN}Slug:${NC} $post_slug"
    echo -e "    ${CYAN}HTML:${NC} $(dirname "$html_file")"
    echo ""
    
    ((counter++))
done

# ========================================
# OPCIÓN DE CREAR POST MANUALMENTE
# ========================================
echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}  ¿Qué deseas hacer?${NC}"
echo -e "${BLUE}========================================${NC}\n"

echo -e "${YELLOW}No puedo recuperar el contenido Markdown original automáticamente,${NC}"
echo -e "${YELLOW}pero puedo ayudarte a recrear el post:${NC}\n"

echo -e "${GREEN}[1]${NC} Crear post manualmente con la información del HTML"
echo -e "${YELLOW}[2]${NC} Mostrar el contenido HTML para copiarlo"
echo -e "${CYAN}[3]${NC} Ignorar y salir"
echo ""

read -p "Opción: " option

if [ "$option" = "1" ]; then
    # ========================================
    # CREAR POST MANUALMENTE
    # ========================================
    echo ""
    read -p "Número del post a recrear (0 para cancelar): " post_num
    
    if [ $post_num -eq 0 ] || [ $post_num -lt 1 ] || [ $post_num -gt ${#posts_html[@]} ]; then
        exit 0
    fi
    
    selected_html="${posts_html[$((post_num-1))]}"
    post_slug=$(basename "$(dirname "$selected_html")")
    
    # Extraer título
    title=$(grep -oP '<h1[^>]*>\K[^<]+' "$selected_html" 2>/dev/null | head -1)
    
    if [ -z "$title" ]; then
        echo -e "\n${YELLOW}No se pudo extraer el título. Introduce el título del post:${NC}"
        read title
    else
        echo -e "\n${CYAN}Título detectado:${NC} $title"
        echo -e "${YELLOW}¿Es correcto? (s/n):${NC}"
        read correct
        
        if [ "$correct" != "s" ] && [ "$correct" != "S" ]; then
            echo -e "${YELLOW}Introduce el título correcto:${NC}"
            read title
        fi
    fi
    
    # Fecha
    current_date=$(date +%Y-%m-%d)
    current_datetime=$(date +"%Y-%m-%d %H:%M:%S %z")
    
    # Nombre del archivo
    post_filename="_posts/${current_date}-${post_slug}.md"
    
    # Categorías
    echo -e "\n${YELLOW}Introduce las categorías (separadas por coma):${NC}"
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
    
    # Etiquetas
    echo -e "\n${YELLOW}Introduce las etiquetas (separadas por coma):${NC}"
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
    
    # Crear el post
    cat > "$post_filename" << EOF
---
title: $title
date: $current_datetime
categories: $categories
tags: $tags
---

# $title

[AQUÍ VA EL CONTENIDO DEL POST]

Copia el contenido desde el HTML o escríbelo de nuevo.

EOF
    
    echo -e "\n${GREEN}✓ Post creado:${NC} $post_filename"
    echo -e "${YELLOW}Ahora debes editar el post y añadir el contenido${NC}\n"
    
    echo -e "${CYAN}¿Quieres ver el contenido HTML como referencia? (s/n):${NC}"
    read show_html
    
    if [ "$show_html" = "s" ] || [ "$show_html" = "S" ]; then
        echo -e "\n${BLUE}Contenido del artículo en HTML:${NC}"
        echo -e "${BLUE}========================================${NC}"
        
        # Extraer el contenido del artículo
        sed -n '/<article/,/<\/article>/p' "$selected_html" | lynx -stdin -dump 2>/dev/null || \
        sed -n '/<article/,/<\/article>/p' "$selected_html" | html2text 2>/dev/null || \
        sed -n '/<article/,/<\/article>/p' "$selected_html"
        
        echo -e "${BLUE}========================================${NC}"
    fi
    
    echo -e "\n${YELLOW}¿Abrir el post para editarlo? (s/n):${NC}"
    read edit
    
    if [ "$edit" = "s" ] || [ "$edit" = "S" ]; then
        if command -v code &> /dev/null; then
            code "$post_filename"
        elif command -v nano &> /dev/null; then
            nano "$post_filename"
        elif command -v vim &> /dev/null; then
            vim "$post_filename"
        fi
    fi
    
elif [ "$option" = "2" ]; then
    # ========================================
    # MOSTRAR CONTENIDO HTML
    # ========================================
    echo ""
    read -p "Número del post a mostrar: " post_num
    
    if [ $post_num -lt 1 ] || [ $post_num -gt ${#posts_html[@]} ]; then
        exit 0
    fi
    
    selected_html="${posts_html[$((post_num-1))]}"
    
    echo -e "\n${CYAN}Intentando extraer el contenido legible...${NC}\n"
    echo -e "${BLUE}========================================${NC}"
    
    # Intentar convertir HTML a texto
    if command -v lynx &> /dev/null; then
        lynx -stdin -dump < "$selected_html"
    elif command -v html2text &> /dev/null; then
        html2text "$selected_html"
    else
        echo -e "${YELLOW}No se encontró lynx o html2text${NC}"
        echo -e "${YELLOW}Mostrando HTML crudo:${NC}\n"
        cat "$selected_html"
    fi
    
    echo -e "${BLUE}========================================${NC}"
fi

echo ""
