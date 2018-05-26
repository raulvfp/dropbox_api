# DropBox API

Clase para manejar las API de DropBox y poder enviar y recibir archivos.
Documentación en:
https://goo.gl/6jDAaK (Como obtener Access Token)
https://goo.gl/Uwyck3 (Cuales son los EndPoint)
https://goo.gl/TAoT7T (Ejemplo de Codigo en VFP)

* support: raul.jrz@gmail.com
* url: [http://rauljrz.github.io/](http://rauljrz.github.io)
* Comentarios en http://rinconfox.com


## Dependencies
https://github.com/raulvfp/ajaxRest
    Extiendo esta clase usando todo su potencial.
https://github.com/raulvfp/catchException
    Para el control de las excepciones.

## Installation
´´´
git clone https://github.com/raulvfp/dropbox_api.git dropbox_api
'''

## Usage
**Properties:**
- authorization: Propiedad en donde se configura el **access token**

**Methods:**
- listFolder(cRootFolder) : Solicita un listado de Folder, tomando el parametro como raiz del listado
    +return: string en formato json

## Example:

```
    loDropBox = CREATEOBJECT('dropbox_api')
    loDropBox.authorization='Bearer 2BaNplW-NkAAAAAAAAAACnD2uYsT9R8Kvoy0hg-BWunSrO2M4awBI75Ggf0FEb-d'
    lcResponseValue = loDropBox.listFolder('')

    ? lcResponseValue

```

http://rinconfox.com