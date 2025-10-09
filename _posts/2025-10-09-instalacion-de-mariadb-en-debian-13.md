---
title: Instalación de MariaDB en Debian 13
date: 2025-10-09 20:18:28 +0200
categories: [Base de Datos]
tags: [debian, linux, sql]
pin: true
---

# 1. Instalación de MariaDB

### Paso 1: Vamos a abrir el terminal y vamos a ejecutar los siguientes comandos:

<aside>

**sudo apt update —> Vemos los paquetes que hay por actualizar en el sistema**

**sudo apt upgrade —> En caso de que hubiera algún paquete lo actualizamos**
**sudo apt install mariadb-server —> Con este vamos instalar mariadb-server**

</aside>

Cuando hemos instalado **mariadb-server,** vamos a iniciar y habilitar el servicio

<aside>

**sudo systemctl start mariadb** —> **Inicia el servicio de MariaDB**

**sudo systemctl enable mariadb —> Habilita el servicio de MariaDB**

</aside>

Y utilizando **sudo systemctl status mariadb,** podemos comprobar si el servicio está funcionando correctamente.

![image.png](attachment:64882c1d-145b-40a7-9acf-5da2da0c7cdc:image.png)

---

### Paso 2: Una vez que hemos instalado e iniciado MariaDB vamos a realizar una configuración inicial ejecutando:

<aside>

**sudo mariadb-secure-installation —> Sirve para aplicar configuraciones básicas de seguridad en MariaDB tras la instalación.** 

</aside>

**Explicación paso a paso de la configuración:**

1. **Configurar contraseña de root**
    - Permite asignar o cambiar la contraseña del usuario administrador (`root`) de MariaDB.
    - En Debian, normalmente root usa autenticación `unix_socket` (sin contraseña, solo accesible con `sudo`), pero aquí puedes forzar el uso de contraseña.
    - En la contraseña ponemos lo que queramos pero yo siempre pongo **root** que es fácil de recordar

![image.png](attachment:ce3ea9d0-43ff-417e-b771-f8aa1caf3e0c:image.png)

1. **Eliminar usuarios anónimos**
    - Borra las cuentas de MariaDB sin nombre de usuario, que permiten entrar sin credenciales.
    - Mejora la seguridad, ya que nadie podrá conectarse “de invitado”.

![image.png](attachment:bdaf819e-df35-44a1-a1d0-c4d3afbc7218:image.png)

1. **Restringir acceso remoto al root**
    - Evita que el usuario `root` se conecte desde otras máquinas por la red.
    - Solo podrá conectarse desde `localhost`, es decir, desde el propio servidor.
    - Reduce el riesgo de ataques externos.

![image.png](attachment:1fb6b59d-7143-4fb2-9ced-b4559f87aaa4:image.png)

1. **Eliminar la base de datos de prueba**
    - MariaDB trae por defecto una base de datos de pruebas accesible para cualquiera.
    - El script la elimina y también borra sus permisos.
    - Esto evita que se use con fines indebidos.
    

![image.png](attachment:85863b3e-f690-4fb2-bd98-5cb1f70bb087:da15904a-47ea-4960-9787-b69ce45e911b.png)

1. **Recargar privilegios**
    - Refresca las tablas de permisos para aplicar de inmediato todos los cambios anteriores.

![image.png](attachment:56ed0d6b-646a-4d2a-af50-f1a15e3b9bce:image.png)

# 2. Creación de usuarios, base de datos y permisos.

En primer lugar vamos a entrar a MariaDB en el modo root para entrar como administradores, podemos hacerlo de dos formas

<aside>

**sudo mysql -u root -p   —> con -u le indicamos el usuario con el que entramos que es root y con -p nos pedirá la contraseña que hayamos puesto antes que también es root**

</aside>

![Captura desde 2025-09-23 20-23-22.png](attachment:179971b8-aebf-44ae-89b1-04bbfc9d1390:Captura_desde_2025-09-23_20-23-22.png)

Podemos también entrar sin usar la opción **-p** y nos permitirá entrar igual sin poner la contraseña

![image.png](attachment:0f58e5ee-47f9-4f26-a7c7-9dd70840c246:image.png)

## 2.1. Crear usuario

Ahora una vez dentro del usuario root vamos a crear un usuario nuevo que no sea administrador al cual llamaremos SCOTT que es con el que trabajamos en clase y de contraseña le ponemos TIGGER. 

<aside>

**CREATE USER ‘SCOTT’@’localhost’ IDENTIFIED BY ‘TIGGER’;**

</aside>

![image.png](attachment:40a37976-bf4e-498a-a307-a476782aa37a:image.png)

## 2.2. Creación de la base de datos

A continuación vamos a crear una base de datos que asignaremos al usuario SCOTT la cual vamos a llamarle empresa.

<aside>

**CREATE DATABASE empresa;**

</aside>

![image.png](attachment:192831df-683b-4112-a961-490fd69f51cc:image.png)

## 2.3. Dar permisos al usuario y la base de datos.

<aside>

**GRANT ALL PRIVILEGES ON empresa.* TO ‘SCOTT’@’localhost’;**

</aside>

![image.png](attachment:3a7bcbd9-1f7d-4cb3-8c1d-0d9d9a8cf753:image.png)

---

## 2.4. Acceso al usuario nuevo y la Base de datos.

Una vez hemos hecho todo lo anterior ya podemos salir del usuario root y vamos a entrar con SCOTT aquí si es importante poner -p porque no es un usuario administrador y nos pedirá la contraseña.

<aside>

**mysql -u SCOTT -p** 

</aside>

![image.png](attachment:65917d9e-0376-4755-96f9-56afb6851234:image.png)
