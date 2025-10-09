#!/bin/bash

# ========================================
# Script de Creación y Publicación de Posts
# La SectASIR
# ========================================
# Automatiza:
# 1. Creación de nuevo post
# 2. Generación del sitio
# 3. Commit en repo fuente
# 4. Commit y push en repo de producción
# ========================================

# Colores
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m' # Sin color

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
print_header "Nuevo Post - La SectASIR"

# ========================================
# VERIFICACIONES INICIALES
# ========================================
print_step "Verificando entorno..."

# Verificar que estamos en un proyecto Jekyll
if [ ! -f "_config.yml" ]; then
    print_error "No se encuentra _config.yml"
    echo "Este script debe ejecutarse desde la raíz del proyecto Jekyll"
    exit 1
fi

# Verificar que existe la carpeta _posts
if [ ! -d "_posts" ]; then
    print_error "No existe la carpeta _posts"
    exit 1
fi

print_success "Entorno verificado\n"

# ========================================
# RECOPILAR INFORMACIÓN DEL POST
# ========================================
print_header "Información del Nuevo Post"

# Título del post
echo -e "${YELLOW}Introduce el título del post:${NC}"
read post_title

if [ -z "$post_title" ]; then
    print_error "El título no puede estar vacío"
    exit 1
fi

# Crear slug (nombre del archivo)
post_slug=$(echo "$post_title" | iconv -t ascii//TRANSLIT | sed -r 's/[^a-zA-Z0-9]+/-/g' | sed -r 's/^-+\|-+$//g' | tr A-Z a-z)

# Fecha actual
current_date=$(date +%Y-%m-%d)
current_datetime=$(date +"%Y-%m-%d %H:%M:%S %z")

# Nombre del archivo
filename="_posts/${current_date}-${post_slug}.md"

# Verificar si ya existe
if [ -f "$filename" ]; then
    print_warning "Ya existe un post con ese nombre hoy"
    echo -e "${YELLOW}¿Quieres sobrescribirlo? (s/n):${NC}"
    read overwrite
    if [ "$overwrite" != "s" ] && [ "$overwrite" != "S" ]; then
        print_error "Operación cancelada"
        exit 1
    fi
fi

# Categorías
echo -e "\n${YELLOW}Introduce las categorías (separadas por coma):${NC}"
echo -e "${CYAN}Ejemplos: Sistemas Linux, Redes, Seguridad${NC}"
read categories_input

# Convertir categorías a formato YAML
if [ -z "$categories_input" ]; then
    categories="[General]"
else
    # Separar por comas y formatear
    IFS=',' read -ra CATS <<< "$categories_input"
    categories="["
    for i in "${!CATS[@]}"; do
        cat=$(echo "${CATS[$i]}" | xargs) # Trim espacios
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
echo -e "${CYAN}Ejemplos: linux, debian, tutorial, redes${NC}"
read tags_input

# Convertir etiquetas a formato YAML
if [ -z "$tags_input" ]; then
    tags="[]"
else
    IFS=',' read -ra TAGS <<< "$tags_input"
    tags="["
    for i in "${!TAGS[@]}"; do
        tag=$(echo "${TAGS[$i]}" | xargs | tr '[:upper:]' '[:lower:]') # Trim y minúsculas
        if [ $i -eq 0 ]; then
            tags="${tags}${tag}"
        else
            tags="${tags}, ${tag}"
        fi
    done
    tags="${tags}]"
fi

# Pin (fijar post)
echo -e "\n${YELLOW}¿Quieres fijar este post en la página principal? (s/n):${NC}"
read pin_post
pin_line=""
if [ "$pin_post" = "s" ] || [ "$pin_post" = "S" ]; then
    pin_line="pin: true"
fi

# ========================================
# CREAR EL ARCHIVO DEL POST
# ========================================
print_step "Creando archivo del post: ${filename}"

cat > "$filename" << EOF
---
title: ${post_title}
date: ${current_datetime}
categories: ${categories}
tags: ${tags}
${pin_line}
---

# ${post_title}

Escribe aquí la introducción de tu post...

## Sección 1

Contenido de la primera sección.

### Subsección 1.1

Detalles...

\`\`\`bash
# Ejemplo de código
echo "Hola Mundo"
\`\`\`

## Sección 2

Más contenido...

### Lista de elementos

- Elemento 1
- Elemento 2
- Elemento 3

### Comandos importantes

\`\`\`bash
# Comando de ejemplo
sudo apt update
sudo apt upgrade -y
\`\`\`

## Conclusión

Resumen y conclusiones del post.

## Referencias

- [Enlace 1](https://ejemplo.com)
- [Enlace 2](https://ejemplo.com)

![Imagen de ejemplo](https://via.placeholder.com/800x400)
EOF

print_success "Post creado: ${filename}\n"

# ========================================
# ABRIR EDITOR
# ========================================
echo -e "${YELLOW}¿Quieres abrir el post en un editor ahora? (s/n):${NC}"
read open_editor

if [ "$open_editor" = "s" ] || [ "$open_editor" = "S" ]; then
    # Detectar editor disponible
    if command -v code &> /dev/null; then
        code "$filename"
    elif command -v nano &> /dev/null; then
        nano "$filename"
    elif command -v vim &> /dev/null; then
        vim "$filename"
    else
        print_warning "No se encontró un editor. Edita manualmente: $filename"
    fi
    
    echo -e "\n${YELLOW}Presiona Enter cuando hayas terminado de editar...${NC}"
    read
fi

# ========================================
# PREVISUALIZACIÓN LOCAL
# ========================================
echo -e "\n${YELLOW}¿Quieres previsualizar el sitio localmente antes de publicar? (s/n):${NC}"
read preview

if [ "$preview" = "s" ] || [ "$preview" = "S" ]; then
    print_step "Iniciando servidor local..."
    echo -e "${CYAN}Abre http://localhost:4000 en tu navegador${NC}"
    echo -e "${CYAN}Presiona Ctrl+C para detener el servidor y continuar${NC}\n"
    bundle exec jekyll serve --future
fi

# ========================================
# CONFIRMAR PUBLICACIÓN
# ========================================
echo -e "\n${YELLOW}¿Deseas publicar este post ahora? (s/n):${NC}"
read confirm_publish

if [ "$confirm_publish" != "s" ] && [ "$confirm_publish" != "S" ]; then
    print_warning "Publicación cancelada"
    echo "El post se ha guardado en: $filename"
    echo "Puedes publicarlo más tarde ejecutando: ./deploy.sh"
    exit 0
fi

# ========================================
# GENERAR SITIO
# ========================================
print_header "Publicando Post"

print_step "Generando sitio estático..."
bundle exec jekyll build

if [ $? -ne 0 ]; then
    print_error "Error al generar el sitio"
    exit 1
fi
print_success "Sitio generado\n"

# ========================================
# COMMIT EN REPOSITORIO FUENTE
# ========================================
print_step "Guardando en repositorio fuente..."

git add .

commit_message="Nuevo post: ${post_title}"

git commit -m "$commit_message"

if [ $? -eq 0 ]; then
    print_success "Commit realizado en repo fuente"
    
    # Preguntar si hacer push
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
    print_warning "No hay cambios para hacer commit en repo fuente"
fi

echo ""

# ========================================
# DESPLEGAR EN PRODUCCIÓN
# ========================================
print_step "Desplegando en producción..."

# Directorio del repositorio HTML
HTML_REPO="../La-SectASIR-html"

# Verificar que existe el directorio
if [ ! -d "$HTML_REPO" ]; then
    print_error "No existe el directorio: $HTML_REPO"
    echo "Crea el directorio e inicializa el repositorio git primero"
    exit 1
fi

cd "$HTML_REPO"

# Verificar si es un repositorio git
if [ ! -d ".git" ]; then
    print_error "El directorio $HTML_REPO no es un repositorio git"
    echo "Inicializa el repositorio manualmente primero con:"
    echo "  cd $HTML_REPO"
    echo "  git init"
    echo "  git remote add origin <URL-del-repositorio-remoto>"
    cd - > /dev/null
    exit 1
fi

git add .

# Verificar si hay cambios
if [[ -z $(git status -s) ]]; then
    print_warning "No hay cambios para desplegar"
    cd ..
    exit 0
fi

git commit -m "$commit_message"

# Push a producción
git push origin main --force

if [ $? -eq 0 ]; then
    print_success "Despliegue completado"
else
    print_error "Error al desplegar"
    cd ..
    exit 1
fi

cd ..

# ========================================
# RESUMEN FINAL
# ========================================
echo ""
print_header "✓ Publicación Completada"

echo -e "${GREEN}Post publicado exitosamente:${NC}"
echo -e "  ${CYAN}Título:${NC} $post_title"
echo -e "  ${CYAN}Archivo:${NC} $filename"
echo -e "  ${CYAN}Categorías:${NC} $categories"
echo -e "  ${CYAN}Etiquetas:${NC} $tags"
echo ""

# Obtener URL del sitio
if [ -f "_config.yml" ]; then
    site_url=$(grep "^url:" _config.yml | awk '{print $2}' | tr -d '"' | tr -d "'")
    if [ ! -z "$site_url" ]; then
        echo -e "${GREEN}Tu sitio se está actualizando en:${NC} ${BLUE}${site_url}${NC}"
        echo -e "${YELLOW}Nota: Puede tardar unos minutos en verse reflejado${NC}"
    fi
fi

echo ""
echo -e "${CYAN}¡Gracias por publicar en La SectASIR!${NC}"
echo ""
