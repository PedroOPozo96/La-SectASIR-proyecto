#!/bin/bash

# ========================================
# Script de Verificación de Posts
# La SectASIR
# ========================================
# Verifica qué posts tienes y permite limpiar
# posts no deseados o de prueba
# ========================================

# Colores
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
NC='\033[0m'

clear
echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}  Verificación de Posts${NC}"
echo -e "${BLUE}========================================${NC}\n"

# ========================================
# LISTAR TODOS LOS POSTS
# ========================================
echo -e "${CYAN}Posts encontrados en _posts/:${NC}\n"

counter=1
posts_array=()
dates_array=()

while IFS= read -r post; do
    filename=$(basename "$post")
    
    # Extraer título
    title=$(awk '/^title:/ {$1=""; print $0}' "$post" | head -1 | sed 's/^[[:space:]]*//' | tr -d '"' | tr -d "'")
    
    # Extraer fecha del nombre del archivo
    file_date=$(echo "$filename" | grep -oE '^[0-9]{4}-[0-9]{2}-[0-9]{2}')
    
    # Extraer fecha del frontmatter
    front_date=$(awk '/^date:/ {print $2}' "$post" | head -1)
    
    # Fecha de modificación del archivo
    mod_date=$(stat -c %y "$post" 2>/dev/null | cut -d' ' -f1)
    
    if [ -z "$title" ]; then
        title="$filename"
    fi
    
    posts_array+=("$post")
    dates_array+=("$file_date")
    
    echo -e "${MAGENTA}[$counter]${NC} ${GREEN}$title${NC}"
    echo -e "    ${CYAN}Archivo:${NC} $filename"
    echo -e "    ${CYAN}Fecha en nombre:${NC} $file_date"
    
    if [ ! -z "$front_date" ]; then
        echo -e "    ${CYAN}Fecha frontmatter:${NC} $front_date"
    fi
    
    echo -e "    ${CYAN}Última modificación:${NC} $mod_date"
    echo -e "    ${CYAN}Ruta completa:${NC} $post"
    echo ""
    
    ((counter++))
done < <(find _posts -type f \( -name "*.md" -o -name "*.markdown" \) 2>/dev/null | sort)

if [ $counter -eq 1 ]; then
    echo -e "${YELLOW}No se encontraron posts${NC}"
    exit 0
fi

total_posts=$((counter-1))
echo -e "${GREEN}Total de posts: $total_posts${NC}\n"

# ========================================
# OPCIONES
# ========================================
echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}  ¿Qué deseas hacer?${NC}"
echo -e "${BLUE}========================================${NC}\n"

echo -e "${GREEN}[1]${NC} Eliminar posts de prueba/ejemplo (2025-10-08-welcome-to-jekyll)"
echo -e "${YELLOW}[2]${NC} Eliminar un post específico"
echo -e "${RED}[3]${NC} Eliminar TODOS los posts y empezar de cero"
echo -e "${CYAN}[4]${NC} Mostrar contenido de un post"
echo -e "${BLUE}[5]${NC} Salir sin hacer cambios"
echo ""

read -p "Opción: " option

case $option in
    1)
        echo -e "\n${YELLOW}Buscando posts de ejemplo...${NC}\n"
        
        found_examples=0
        
        for post in "${posts_array[@]}"; do
            filename=$(basename "$post")
            
            # Detectar posts de ejemplo comunes
            if [[ "$filename" == *"welcome-to-jekyll"* ]] || \
               [[ "$filename" == *"example"* ]] || \
               [[ "$filename" == *"sample"* ]] || \
               [[ "$filename" == *"test"* ]]; then
                
                echo -e "${YELLOW}Encontrado:${NC} $filename"
                echo -e "${RED}¿Eliminar este post? (s/n):${NC}"
                read confirm
                
                if [ "$confirm" = "s" ] || [ "$confirm" = "S" ]; then
                    rm "$post"
                    echo -e "${GREEN}✓ Eliminado${NC}\n"
                    ((found_examples++))
                else
                    echo -e "${CYAN}Conservado${NC}\n"
                fi
            fi
        done
        
        if [ $found_examples -eq 0 ]; then
            echo -e "${GREEN}No se encontraron posts de ejemplo${NC}"
        else
            echo -e "\n${GREEN}Se eliminaron $found_examples post(s)${NC}"
            echo -e "${YELLOW}Regenerando sitio...${NC}"
            bundle exec jekyll build
        fi
        ;;
        
    2)
        echo ""
        read -p "Número del post a eliminar (0 para cancelar): " post_num
        
        if [ $post_num -eq 0 ]; then
            exit 0
        fi
        
        if [ $post_num -lt 1 ] || [ $post_num -gt $total_posts ]; then
            echo -e "${RED}Número inválido${NC}"
            exit 1
        fi
        
        selected_post="${posts_array[$((post_num-1))]}"
        filename=$(basename "$selected_post")
        
        echo -e "\n${RED}¿Estás seguro de eliminar: $filename? (s/n):${NC}"
        read confirm
        
        if [ "$confirm" = "s" ] || [ "$confirm" = "S" ]; then
            rm "$selected_post"
            echo -e "${GREEN}✓ Post eliminado${NC}"
            echo -e "${YELLOW}Regenerando sitio...${NC}"
            bundle exec jekyll build
        else
            echo -e "${CYAN}Operación cancelada${NC}"
        fi
        ;;
        
    3)
        echo -e "\n${RED}⚠️  ¡ATENCIÓN!${NC}"
        echo -e "${RED}Esto eliminará TODOS los posts de _posts/${NC}"
        echo -e "${YELLOW}Escribe 'ELIMINAR TODO' para confirmar:${NC}"
        read confirm
        
        if [ "$confirm" = "ELIMINAR TODO" ]; then
            rm -f _posts/*.md _posts/*.markdown 2>/dev/null
            echo -e "${GREEN}✓ Todos los posts eliminados${NC}"
            echo -e "${YELLOW}Regenerando sitio...${NC}"
            bundle exec jekyll build
        else
            echo -e "${CYAN}Operación cancelada${NC}"
        fi
        ;;
        
    4)
        echo ""
        read -p "Número del post a mostrar: " post_num
        
        if [ $post_num -lt 1 ] || [ $post_num -gt $total_posts ]; then
            echo -e "${RED}Número inválido${NC}"
            exit 1
        fi
        
        selected_post="${posts_array[$((post_num-1))]}"
        
        echo -e "\n${CYAN}Contenido del post:${NC}"
        echo -e "${BLUE}========================================${NC}"
        cat "$selected_post"
        echo -e "${BLUE}========================================${NC}"
        ;;
        
    5)
        echo -e "${CYAN}Saliendo sin cambios...${NC}"
        exit 0
        ;;
        
    *)
        echo -e "${RED}Opción inválida${NC}"
        exit 1
        ;;
esac

echo ""
