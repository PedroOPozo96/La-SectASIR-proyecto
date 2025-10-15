#!/bin/bash

# ========================================
# Script de Gestión de Posts
# La SectASIR
# ========================================
# Menú principal para gestionar posts
# ========================================

# Colores
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
NC='\033[0m'

# Función para mostrar el menú
show_menu() {
    clear
    echo -e "${BLUE}========================================${NC}"
    echo -e "${BLUE}     Gestión de Posts - La SectASIR${NC}"
    echo -e "${BLUE}========================================${NC}\n"
    
    echo -e "${CYAN}Selecciona una opción:${NC}\n"
    echo -e "${GREEN}[1]${NC} Crear nuevo post"
    echo -e "${YELLOW}[2]${NC} Eliminar un post"
    echo -e "${BLUE}[3]${NC} Listar todos los posts"
    echo -e "${MAGENTA}[4]${NC} Editar un post existente"
    echo -e "${CYAN}[5]${NC} Importar desde Notion"
    echo -e "${GREEN}[6]${NC} Añadir imágenes a un post"
    echo -e "${YELLOW}[7]${NC} Verificar y limpiar posts"
    echo -e "${MAGENTA}[8]${NC} Recuperar posts perdidos"
    echo -e "${RED}[9]${NC} Diagnosticar problemas"
    echo -e "${BLUE}[10]${NC} Solo desplegar (sin crear post)"
    echo -e "${RED}[0]${NC} Salir"
    echo ""
}

# Función para listar posts
list_posts() {
    clear
    echo -e "${BLUE}========================================${NC}"
    echo -e "${BLUE}     Lista de Posts${NC}"
    echo -e "${BLUE}========================================${NC}\n"
    
    counter=1
    while IFS= read -r post; do
        filename=$(basename "$post")
        title=$(grep "^title:" "$post" | head -1 | sed 's/title: //' | tr -d '"' | tr -d "'")
        date=$(grep "^date:" "$post" | head -1 | sed 's/date: //' | cut -d' ' -f1)
        categories=$(grep "^categories:" "$post" | head -1 | sed 's/categories: //')
        
        if [ -z "$title" ]; then
            title="$filename"
        fi
        
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
    done < <(find _posts -name "*.md" -o -name "*.markdown" 2>/dev/null | sort -r)
    
    if [ $counter -eq 1 ]; then
        echo -e "${YELLOW}No hay posts disponibles${NC}"
    else
        echo -e "${GREEN}Total de posts: $((counter-1))${NC}"
    fi
    
    echo ""
    echo -e "${YELLOW}Presiona Enter para volver al menú...${NC}"
    read
}

# Función para editar posts
edit_post() {
    clear
    echo -e "${BLUE}========================================${NC}"
    echo -e "${BLUE}     Editar Post${NC}"
    echo -e "${BLUE}========================================${NC}\n"
    
    counter=1
    posts_array=()
    
    while IFS= read -r post; do
        filename=$(basename "$post")
        title=$(grep "^title:" "$post" | head -1 | sed 's/title: //' | tr -d '"' | tr -d "'")
        
        if [ -z "$title" ]; then
            title="$filename"
        fi
        
        posts_array+=("$post")
        echo -e "${MAGENTA}[$counter]${NC} ${GREEN}$title${NC} ${CYAN}($filename)${NC}"
        ((counter++))
    done < <(find _posts -name "*.md" -o -name "*.markdown" 2>/dev/null | sort -r)
    
    if [ $counter -eq 1 ]; then
        echo -e "${YELLOW}No hay posts disponibles${NC}"
        echo ""
        read -p "Presiona Enter para volver al menú..."
        return
    fi
    
    echo ""
    read -p "Número del post a editar (0 para volver): " post_num
    
    if [ $post_num -eq 0 ]; then
        return
    fi
    
    if ! [[ "$post_num" =~ ^[0-9]+$ ]] || [ $post_num -lt 1 ] || [ $post_num -gt ${#posts_array[@]} ]; then
        echo -e "${RED}✗${NC} Número inválido"
        read -p "Presiona Enter para continuar..."
        return
    fi
    
    selected_post="${posts_array[$((post_num-1))]}"
    
    if command -v code &> /dev/null; then
        code "$selected_post"
    elif command -v nano &> /dev/null; then
        nano "$selected_post"
    elif command -v vim &> /dev/null; then
        vim "$selected_post"
    else
        echo -e "${YELLOW}!${NC} No se encontró un editor"
        echo "Abre manualmente: $selected_post"
        read -p "Presiona Enter para continuar..."
        return
    fi
    
    echo ""
    echo -e "${YELLOW}¿Deseas desplegar los cambios? (s/n):${NC}"
    read deploy
    
    if [ "$deploy" = "s" ] || [ "$deploy" = "S" ]; then
        if [ -f "./deploy.sh" ]; then
            ./deploy.sh
        else
            echo -e "${YELLOW}No se encuentra deploy.sh, regenerando y desplegando...${NC}"
            # Lógica de despliegue integrada
            bundle exec jekyll build
            echo -e "${GREEN}✓${NC} Sitio regenerado"
            echo ""
            read -p "Presiona Enter para volver al menú..."
        fi
    fi
}

# Verificar que estamos en el proyecto correcto
if [ ! -f "_config.yml" ]; then
    echo -e "${RED}✗${NC} No se encuentra _config.yml"
    echo "Este script debe ejecutarse desde la raíz del proyecto Jekyll"
    exit 1
fi

# Bucle principal del menú
while true; do
    show_menu
    read -p "Opción: " option
    
    case $option in
        1)
            clear
            if [ -f "./new-post.sh" ]; then
                ./new-post.sh
            else
                echo -e "${RED}✗${NC} No se encuentra el script new-post.sh"
                read -p "Presiona Enter para continuar..."
            fi
            ;;
        2)
            clear
            if [ -f "./delete-post.sh" ]; then
                ./delete-post.sh
            else
                echo -e "${RED}✗${NC} No se encuentra el script delete-post.sh"
                read -p "Presiona Enter para continuar..."
            fi
            ;;
        3)
            list_posts
            ;;
        4)
            edit_post
            ;;
        5)
            clear
            if [ -f "./import-notion.sh" ]; then
                ./import-notion.sh
            else
                echo -e "${RED}✗${NC} No se encuentra el script import-notion.sh"
                read -p "Presiona Enter para continuar..."
            fi
            ;;
        6)
            clear
            if [ -f "./add-images.sh" ]; then
                ./add-images.sh
            else
                echo -e "${RED}✗${NC} No se encuentra el script add-images.sh"
                read -p "Presiona Enter para continuar..."
            fi
            ;;
        7)
            clear
            if [ -f "./verify-posts.sh" ]; then
                ./verify-posts.sh
            else
                echo -e "${RED}✗${NC} No se encuentra el script verify-posts.sh"
                read -p "Presiona Enter para continuar..."
            fi
            ;;
        8)
            clear
            if [ -f "./recover-posts.sh" ]; then
                ./recover-posts.sh
            else
                echo -e "${RED}✗${NC} No se encuentra el script recover-posts.sh"
                read -p "Presiona Enter para continuar..."
            fi
            ;;
        9)
            clear
            if [ -f "./deploy.sh" ]; then
                ./deploy.sh
                read -p "Presiona Enter para volver al menú..."
            else
                echo -e "${RED}✗${NC} No se encuentra el script deploy.sh"
                echo -e "${YELLOW}Puedes crearlo o los cambios se desplegarán al crear/eliminar posts${NC}"
                read -p "Presiona Enter para continuar..."
            fi
            ;;
        0)
            clear
            echo -e "\n${CYAN}¡Hasta pronto!${NC}\n"
            exit 0
            ;;
        *)
            echo -e "${RED}✗${NC} Opción inválida"
            sleep 1
            ;;
    esac
done
