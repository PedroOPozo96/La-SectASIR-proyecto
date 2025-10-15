#!/bin/bash

# ========================================
# Script de Diagnóstico
# La SectASIR
# ========================================
# Diagnostica problemas de sincronización
# entre repositorio fuente y HTML
# ========================================

# Colores
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

HTML_REPO="../La-SectASIR-html"

clear
echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}  Diagnóstico del Sitio${NC}"
echo -e "${BLUE}========================================${NC}\n"

# ========================================
# 1. VERIFICAR REPOSITORIO FUENTE
# ========================================
echo -e "${CYAN}1. Repositorio Fuente (_posts/):${NC}\n"

if [ ! -d "_posts" ]; then
    echo -e "${RED}✗ No existe la carpeta _posts${NC}"
else
    post_count=$(find _posts -type f \( -name "*.md" -o -name "*.markdown" \) 2>/dev/null | wc -l)
    echo -e "${GREEN}✓ Carpeta _posts existe${NC}"
    echo -e "  ${CYAN}Posts encontrados: $post_count${NC}\n"
    
    if [ $post_count -gt 0 ]; then
        echo -e "  ${YELLOW}Lista de posts en _posts/:${NC}"
        find _posts -type f \( -name "*.md" -o -name "*.markdown" \) 2>/dev/null | while read post; do
            filename=$(basename "$post")
            title=$(awk '/^title:/ {$1=""; print $0}' "$post" | head -1 | sed 's/^[[:space:]]*//' | tr -d '"' | tr -d "'")
            echo -e "    ${GREEN}•${NC} $filename"
            if [ ! -z "$title" ]; then
                echo -e "      ${CYAN}Título: $title${NC}"
            fi
        done
    fi
fi

echo ""

# ========================================
# 2. VERIFICAR _site
# ========================================
echo -e "${CYAN}2. Sitio Generado (_site/):${NC}\n"

if [ ! -d "_site" ]; then
    echo -e "${RED}✗ No existe _site${NC}"
    echo -e "${YELLOW}  Ejecuta: bundle exec jekyll build${NC}"
else
    html_count=$(find _site -type f -name "*.html" 2>/dev/null | wc -l)
    total_files=$(find _site -type f 2>/dev/null | wc -l)
    
    echo -e "${GREEN}✓ Carpeta _site existe${NC}"
    echo -e "  ${CYAN}Archivos HTML: $html_count${NC}"
    echo -e "  ${CYAN}Total de archivos: $total_files${NC}\n"
    
    # Verificar logo/avatar
    if [ -f "_site/assets/img/avatar.jpg" ]; then
        avatar_size=$(du -h "_site/assets/img/avatar.jpg" | cut -f1)
        echo -e "  ${GREEN}✓ Avatar/Logo presente ($avatar_size)${NC}"
    else
        echo -e "  ${RED}✗ Avatar/Logo NO encontrado${NC}"
        echo -e "    ${YELLOW}Esperado en: _site/assets/img/avatar.jpg${NC}"
    fi
    
    # Verificar posts en _site
    if [ -d "_site/posts" ]; then
        site_posts=$(find _site/posts -type d -mindepth 1 -maxdepth 1 2>/dev/null | wc -l)
        echo -e "  ${CYAN}Posts en _site: $site_posts${NC}"
    fi
fi

echo ""

# ========================================
# 3. VERIFICAR REPOSITORIO HTML
# ========================================
echo -e "${CYAN}3. Repositorio HTML (La-SectASIR-html/):${NC}\n"

if [ ! -d "$HTML_REPO" ]; then
    echo -e "${RED}✗ No existe el repositorio HTML${NC}"
    echo -e "  ${YELLOW}Ruta esperada: $HTML_REPO${NC}"
else
    html_count=$(find "$HTML_REPO" -type f -name "*.html" ! -path "*/.git/*" 2>/dev/null | wc -l)
    total_files=$(find "$HTML_REPO" -type f ! -path "*/.git/*" 2>/dev/null | wc -l)
    
    echo -e "${GREEN}✓ Repositorio HTML existe${NC}"
    echo -e "  ${CYAN}Archivos HTML: $html_count${NC}"
    echo -e "  ${CYAN}Total de archivos: $total_files${NC}\n"
    
    # Verificar logo/avatar
    if [ -f "$HTML_REPO/assets/img/avatar.jpg" ]; then
        avatar_size=$(du -h "$HTML_REPO/assets/img/avatar.jpg" | cut -f1)
        echo -e "  ${GREEN}✓ Avatar/Logo presente ($avatar_size)${NC}"
    else
        echo -e "  ${RED}✗ Avatar/Logo NO encontrado${NC}"
        echo -e "    ${YELLOW}Esperado en: $HTML_REPO/assets/img/avatar.jpg${NC}"
    fi
    
    # Verificar posts en HTML
    if [ -d "$HTML_REPO/posts" ]; then
        html_posts=$(find "$HTML_REPO/posts" -type d -mindepth 1 -maxdepth 1 2>/dev/null | wc -l)
        echo -e "  ${CYAN}Posts en HTML: $html_posts${NC}\n"
        
        echo -e "  ${YELLOW}Posts desplegados:${NC}"
        find "$HTML_REPO/posts" -type d -mindepth 1 -maxdepth 1 2>/dev/null | while read post_dir; do
            post_slug=$(basename "$post_dir")
            echo -e "    ${GREEN}•${NC} $post_slug"
        done
    fi
    
    # Verificar git
    echo ""
    if [ -d "$HTML_REPO/.git" ]; then
        echo -e "  ${GREEN}✓ Repositorio git configurado${NC}"
        
        cd "$HTML_REPO"
        
        # Estado de git
        if git rev-parse --git-dir > /dev/null 2>&1; then
            # Último commit
            last_commit=$(git log -1 --pretty=format:"%h - %s (%ar)" 2>/dev/null)
            if [ ! -z "$last_commit" ]; then
                echo -e "  ${CYAN}Último commit: $last_commit${NC}"
            fi
            
            # Cambios pendientes
            changes=$(git status --short | wc -l)
            if [ $changes -gt 0 ]; then
                echo -e "  ${YELLOW}⚠ Hay $changes cambio(s) sin commitear${NC}"
            else
                echo -e "  ${GREEN}✓ No hay cambios pendientes${NC}"
            fi
        fi
        
        cd - > /dev/null
    else
        echo -e "  ${RED}✗ NO es un repositorio git${NC}"
    fi
fi

echo ""

# ========================================
# 4. COMPARAR POSTS
# ========================================
echo -e "${CYAN}4. Comparación de Posts:${NC}\n"

source_posts=$(find _posts -type f \( -name "*.md" -o -name "*.markdown" \) 2>/dev/null | wc -l)
site_posts_count=0
html_posts_count=0

if [ -d "_site/posts" ]; then
    site_posts_count=$(find _site/posts -type d -mindepth 1 -maxdepth 1 2>/dev/null | wc -l)
fi

if [ -d "$HTML_REPO/posts" ]; then
    html_posts_count=$(find "$HTML_REPO/posts" -type d -mindepth 1 -maxdepth 1 2>/dev/null | wc -l)
fi

echo -e "  ${CYAN}Posts en _posts/     : $source_posts${NC}"
echo -e "  ${CYAN}Posts en _site/      : $site_posts_count${NC}"
echo -e "  ${CYAN}Posts en HTML repo   : $html_posts_count${NC}\n"

if [ $source_posts -ne $html_posts_count ]; then
    echo -e "  ${YELLOW}⚠ DESINCRONIZACIÓN DETECTADA${NC}"
    echo -e "  ${YELLOW}El número de posts no coincide${NC}\n"
    
    echo -e "  ${CYAN}Recomendaciones:${NC}"
    echo -e "    1. Regenera el sitio: ${GREEN}bundle exec jekyll build${NC}"
    echo -e "    2. Despliega: ${GREEN}./deploy.sh${NC}"
    echo -e "    3. O usa: ${GREEN}./manage-posts.sh${NC} → [8] Recuperar posts"
else
    echo -e "  ${GREEN}✓ Posts sincronizados correctamente${NC}"
fi

echo ""

# ========================================
# 5. VERIFICAR HERRAMIENTAS
# ========================================
echo -e "${CYAN}5. Herramientas disponibles:${NC}\n"

if command -v rsync &> /dev/null; then
    echo -e "  ${GREEN}✓ rsync instalado${NC} (recomendado para sincronización)"
else
    echo -e "  ${YELLOW}⚠ rsync NO instalado${NC}"
    echo -e "    Instalar con: ${GREEN}sudo apt install rsync${NC}"
fi

if command -v bundle &> /dev/null; then
    echo -e "  ${GREEN}✓ bundler instalado${NC}"
else
    echo -e "  ${RED}✗ bundler NO instalado${NC}"
fi

if command -v jekyll &> /dev/null; then
    jekyll_version=$(jekyll -v 2>/dev/null)
    echo -e "  ${GREEN}✓ jekyll instalado${NC} ($jekyll_version)"
else
    echo -e "  ${RED}✗ jekyll NO instalado${NC}"
fi

echo ""

# ========================================
# RESUMEN
# ========================================
echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}  Resumen${NC}"
echo -e "${BLUE}========================================${NC}\n"

# Detectar problemas
problems=0

if [ $source_posts -ne $html_posts_count ]; then
    ((problems++))
    echo -e "${YELLOW}⚠ Posts desincronizados${NC}"
fi

if [ ! -f "$HTML_REPO/assets/img/avatar.jpg" ]; then
    ((problems++))
    echo -e "${YELLOW}⚠ Logo/Avatar faltante en repositorio HTML${NC}"
fi

if ! command -v rsync &> /dev/null; then
    ((problems++))
    echo -e "${YELLOW}⚠ rsync no instalado (recomendado)${NC}"
fi

if [ $problems -eq 0 ]; then
    echo -e "${GREEN}✓ No se detectaron problemas${NC}"
else
    echo -e "${YELLOW}Se detectaron $problems problema(s)${NC}"
fi

echo ""
