#!/bin/bash

# ========================================
# Script para Añadir Imágenes a Posts
# La SectASIR
# ========================================
# Facilita añadir imágenes a posts existentes
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

# Funciones
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
print_header "Añadir Imágenes a Posts"

# ========================================
# VERIFICACIONES
# ========================================
if [ ! -f "_config.yml" ]; then
    print_error "Este script debe ejecutarse desde la raíz del proyecto"
    exit 1
fi

mkdir -p "$IMAGES_DIR"

# ========================================
# SELECCIONAR POST
# ========================================
print_step "Selecciona el post al que añadir imágenes\n"

counter=1
posts_array=()

while IFS= read -r post; do
    filename=$(basename "$post")
    title=$(awk '/^title:/ {$1=""; print $0}' "$post" | head -1 | sed 's/^[[:space:]]*//' | tr -d '"' | tr -d "'")
    
    if [ -z "$title" ]; then
        title="$filename"
    fi
    
    posts_array+=("$post")
    echo -e "${MAGENTA}[$counter]${NC} ${GREEN}$title${NC} ${CYAN}($filename)${NC}"
    ((counter++))
done < <(find _posts -type f \( -name "*.md" -o -name "*.markdown" \) 2>/dev/null | sort -r)

if [ $counter -eq 1 ]; then
    print_error "No hay posts disponibles"
    exit 1
fi

echo ""
read -p "Número del post (0 para cancelar): " post_num

if [ $post_num -eq 0 ]; then
    exit 0
fi

if [ $post_num -lt 1 ] || [ $post_num -gt ${#posts_array[@]} ]; then
    print_error "Número inválido"
    exit 1
fi

selected_post="${posts_array[$((post_num-1))]}"
post_filename=$(basename "$selected_post" .md)

# Extraer slug del nombre del archivo (quitar fecha)
post_slug=$(echo "$post_filename" | sed 's/^[0-9]\{4\}-[0-9]\{2\}-[0-9]\{2\}-//')

# Crear directorio para imágenes del post
post_images_dir="$IMAGES_DIR/$post_slug"
mkdir -p "$post_images_dir"

print_success "Post seleccionado: $post_slug\n"

# ========================================
# MODO DE AÑADIR IMÁGENES
# ========================================
print_header "¿Cómo quieres añadir las imágenes?"

echo -e "${CYAN}Opciones:${NC}"
echo -e "${GREEN}[1]${NC} Copiar imagen(es) desde una ruta"
echo -e "${YELLOW}[2]${NC} Copiar todas las imágenes de una carpeta"
echo -e "${BLUE}[3]${NC} Ver imágenes actuales del post"
echo ""

read -p "Selecciona una opción: " add_option

if [ "$add_option" = "1" ]; then
    # ========================================
    # COPIAR IMAGEN INDIVIDUAL
    # ========================================
    while true; do
        echo -e "\n${YELLOW}Arrastra la imagen aquí (o escribe 'fin' para terminar):${NC}"
        read -e image_path
        
        if [ "$image_path" = "fin" ]; then
            break
        fi
        
        # Limpiar path
        image_path=$(echo "$image_path" | sed "s/^'//" | sed "s/'$//" | sed 's/^"//' | sed 's/"$//')
        
        if [ ! -f "$image_path" ]; then
            print_error "El archivo no existe"
            continue
        fi
        
        # Obtener nombre del archivo
        image_name=$(basename "$image_path")
        
        # Copiar imagen
        cp "$image_path" "$post_images_dir/"
        
        if [ $? -eq 0 ]; then
            print_success "Imagen copiada: $image_name"
            
            # Mostrar ruta para usar en Markdown
            echo -e "${CYAN}Usa en tu post:${NC}"
            echo -e "${GREEN}![Descripción](/assets/img/posts/$post_slug/$image_name)${NC}"
            echo ""
        else
            print_error "Error al copiar la imagen"
        fi
    done
    
elif [ "$add_option" = "2" ]; then
    # ========================================
    # COPIAR CARPETA COMPLETA
    # ========================================
    echo -e "\n${YELLOW}Arrastra la carpeta con imágenes aquí:${NC}"
    read -e images_folder
    
    # Limpiar path
    images_folder=$(echo "$images_folder" | sed "s/^'//" | sed "s/'$//" | sed 's/^"//' | sed 's/"$//')
    
    if [ ! -d "$images_folder" ]; then
        print_error "La carpeta no existe"
        exit 1
    fi
    
    print_step "Copiando imágenes..."
    
    image_count=0
    
    for img in "$images_folder"/*.{png,jpg,jpeg,gif,webp,PNG,JPG,JPEG,GIF,WEBP} 2>/dev/null; do
        if [ -f "$img" ]; then
            img_name=$(basename "$img")
            cp "$img" "$post_images_dir/"
            
            if [ $? -eq 0 ]; then
                echo -e "  ${GREEN}✓${NC} $img_name"
                ((image_count++))
            fi
        fi
    done
    
    if [ $image_count -gt 0 ]; then
        print_success "\nSe copiaron $image_count imagen(es)"
        echo -e "\n${CYAN}Rutas para usar en tu post:${NC}"
        
        for img in "$post_images_dir"/*; do
            if [ -f "$img" ]; then
                img_name=$(basename "$img")
                echo -e "${GREEN}![Descripción](/assets/img/posts/$post_slug/$img_name)${NC}"
            fi
        done
    else
        print_warning "No se encontraron imágenes en la carpeta"
    fi
    
elif [ "$add_option" = "3" ]; then
    # ========================================
    # VER IMÁGENES ACTUALES
    # ========================================
    print_step "Imágenes actuales del post:\n"
    
    if [ ! -d "$post_images_dir" ] || [ -z "$(ls -A "$post_images_dir" 2>/dev/null)" ]; then
        print_warning "No hay imágenes para este post"
    else
        counter=1
        for img in "$post_images_dir"/*; do
            if [ -f "$img" ]; then
                img_name=$(basename "$img")
                img_size=$(du -h "$img" | cut -f1)
                echo -e "${MAGENTA}[$counter]${NC} ${GREEN}$img_name${NC} ${CYAN}($img_size)${NC}"
                echo -e "     ${YELLOW}Markdown:${NC} ![Descripción](/assets/img/posts/$post_slug/$img_name)"
                echo ""
                ((counter++))
            fi
        done
        
        echo -e "\n${YELLOW}¿Quieres eliminar alguna imagen? (s/n):${NC}"
        read delete_img
        
        if [ "$delete_img" = "s" ] || [ "$delete_img" = "S" ]; then
            read -p "Número de la imagen a eliminar: " img_num
            
            counter=1
            for img in "$post_images_dir"/*; do
                if [ -f "$img" ] && [ $counter -eq $img_num ]; then
                    rm "$img"
                    print_success "Imagen eliminada: $(basename "$img")"
                    break
                fi
                ((counter++))
            done
        fi
    fi
    
else
    print_error "Opción inválida"
    exit 1
fi

# ========================================
# ABRIR POST PARA EDITAR
# ========================================
echo -e "\n${YELLOW}¿Quieres abrir el post para añadir las imágenes al contenido? (s/n):${NC}"
read open_post

if [ "$open_post" = "s" ] || [ "$open_post" = "S" ]; then
    if command -v code &> /dev/null; then
        code "$selected_post"
    elif command -v nano &> /dev/null; then
        nano "$selected_post"
    elif command -v vim &> /dev/null; then
        vim "$selected_post"
    fi
fi

# ========================================
# RESUMEN
# ========================================
echo ""
print_header "✓ Proceso Completado"

echo -e "${GREEN}Directorio de imágenes:${NC}"
echo -e "  $post_images_dir"
echo ""

echo -e "${CYAN}Para usar las imágenes en tu post:${NC}"
echo -e "${YELLOW}![Descripción de la imagen](/assets/img/posts/$post_slug/nombre-imagen.ext)${NC}"
echo ""
