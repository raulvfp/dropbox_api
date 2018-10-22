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
```
git clone https://github.com/raulvfp/dropbox_api.git dropbox_api
```

## Properties 
- authorization: Propiedad en donde se configura el **access token**
```
	loDropBox.authorization='Bearer 2BaNplW-NkAAAAAAAAAACnD2uYsT9R8Kvoy0hg-BWunSrO2M4awBI75Ggf0FEb-d'
```

## Methods Auxiliares:
- isSuccess()  : Devuelve .T. si tuvo exito la última operación, de lo contrario .F.
- isError()    : Devuelve .T. si tuvo error la última operación, de lo contrario .F.
- getMsgError(): Si la última operación dio error, contiene el Mensaje de Error, de lo contrario .null.
- getResponse(): Devuelve la cadena cruda devuelta desde DropBox.
- getElement() : Si fue satisfactoria la última operación, contiene un objeto con los datos del archivo o carpeta
```
		loElement = loDropBox.getElement()
		? 'File id........: '+loElement.get("id")
		? 'File Name......: '+loElement.get("name")
		? 'File Path......: '+loElement.get("path_display")
		? 'client_modified: '+loElement.get("client_modified")
		? 'server_modified: '+loElement.get("server_modified")
		? 'tag............: '+loElement.get("tag")
		? 'File size......: '+TRANSFORM(loElement.get("size"))
```

## Methods Principales:
- **listFolder**(cRootFolder) : Solicita un listado del contenido de un Folder.

    +parameter: El path completo de la carpeta en DropBox.
    
    +return...: Si tuvo exito, devuelve un objeto con los datos de los archivos y carpetas contenidos en el path.
                De lo contrario, devuelve .null.
		

  **Example:**

```
	loDropBox = CREATEOBJECT('dropbox_api')
	loDropBox.authorization='Bearer 2BaNplW-NkAAAAAAAAAACnD2uYsT9R8Kvoy0hg-BWunSrO2M4awBI75Ggf0FEb-d'
    
	oResponse = loDropBox.listFolder('/Apps/myFolder/')

	IF loDropBox.isSuccess() THEN   &&Evaluo si tuvo exito
		FOR lnInd = 1 TO oResponse.nSIZE
			loElement = oResponse.GET(lnInd)
			?'Element n'+TRANSFORM(lnInd)+': ';
				+loElement.GET("path_display")   +'| ';
				+loElement.GET("tag")
		ENDFOR
	ELSE
		? 'Error: ' + loDropBox.getMsgError()
	ENDIF
```

http://rinconfox.com
