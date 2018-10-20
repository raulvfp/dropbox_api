*
*|--------------------------------------------------------------------------
*| dropbox_api
*|--------------------------------------------------------------------------
*|
*| Archivo principal del sistema
*| Author......: RaÃºl Jrz (raul.jrz@gmail.com) 
*| Created.....: 08.05.2018 - 19:46
*| Purpose.....: Servir de ejemplo del uso de las API de DROPBOX
*|
*| Revisions...: v1.00
*|
*/
*-----------------------------------------------------------------------------------*
DEFINE CLASS dropbox_api AS ajaxRest
*
*-----------------------------------------------------------------------------------*
	PROTECTED bRelanzarThrow
	bRelanzarThrow = .T. &&Relanza la excepcion al nivel superior
	authorization  = ''  &&Es el Token de API de DropBox
	
	PROTECTED msgError   &&Por defecto, esta empty. Cuando existe un error tiene el
						 &&Mensaje de la ultima operación
	msgError = ''

	PROTECTED response   &&Contiene la cadena cruda de la respuesta de la última acción
	response = ''
	
	oResponse= null      &&Es el objeto conteniendo la respuesta, cuando esta es un objeto
	
	PROTECTED path
	path     = null      &&Es el path sobre el cual se va a trabajar.
	
	PROTECTED oElement   &&Contiene los datos del ultimo archivo con el cual se estuvo trabajando.
						&&por ejemplo en una busqueda. FOUND() guarda en el los datos si hubo exito.
	oElement = null
	
	
	*----------------------------------------------------------------------------*
	FUNCTION isError
	* Indica si existio un error en la ultima operación realizada
	*----------------------------------------------------------------------------*
		RETURN !THIS.isSuccess()
	ENDFUNC
	
	*----------------------------------------------------------------------------*
	FUNCTION isSuccess
	* Indica fue exitosa la ultima acción
	*----------------------------------------------------------------------------*
		RETURN EMPTY(THIS.msgError)
	ENDFUNC
	
	*----------------------------------------------------------------------------*
	FUNCTION getMsgError
	* Devuelve la leyenda del Error de la ultima acción.
	*----------------------------------------------------------------------------*
		RETURN THIS.msgError
	ENDFUNC
	
	*----------------------------------------------------------------------------*
	FUNCTION getResponse
	* Devuelve la leyenda del Error de la ultima acción.
	*----------------------------------------------------------------------------*
		RETURN THIS.Response
	ENDFUNC

	*----------------------------------------------------------------------------*
	FUNCTION setPath(tcPath)
	* Asigna valor al path
	*----------------------------------------------------------------------------*
		THIS.path = ''
		IF VARTYPE(tcPath)='C' THEN
			THIS.path = ALLTRIM(tcPath)
		ENDIF
	ENDFUNC

	*----------------------------------------------------------------------------*
	FUNCTION getPath()
	* Devuelve el valor del path
	*----------------------------------------------------------------------------*
		RETURN THIS.path
	ENDFUNC
			
	*----------------------------------------------------------------------------*
	PROTECTED FUNCTION initAction
	* Prepara todo, blanqueando para inicializar las acciones
	*----------------------------------------------------------------------------*
		THIS.msgError = ''
		THIS.response = ''
		THIS.oElement = null

		IF EMPTY(THIS.authorization) THEN
			THIS.msgError = 'Falta el Token para procesar'
		ENDIF
		RETURN EMPTY(THIS.msgError)
	ENDFUNC
	
	*----------------------------------------------------------------------------*
	PROTECTED FUNCTION checkError
	* Verifica si existio un error en la ultima acción.
	*----------------------------------------------------------------------------*
		WITH THIS	
			IF '"error_summary":' $ .response AND;
			   '"error":'         $ .response THEN

				.msgError  = IIF(VARTYPE(.oResponse._error_summary)='C',;
										.oResponse._error_summary,;
										'';
									)	
				.msgError = ALLTRIM(PROPER(STRTRAN(STRTRAN(.msgError ,'_',' '),'/',' ')))
			ENDIF
		ENDWITH
	ENDFUNC
	
	*----------------------------------------------------------------------------*
	PROTECTED FUNCTION response_ASSIGN(teValue)
	* Metodo que se ejecuta cuando se le asigna un valor a response
	*----------------------------------------------------------------------------*
		LOCAL loJson
		
		WITH THIS
			.response = teValue
			.oResponse= null
			IF !EMPTY(teValue) THEN
				loJson = NEWOBJECT('json')
				.oResponse = loJson.decode(.response)
				loJson = null

				.checkError()
			ENDIF
		ENDWITH
	ENDFUNC

	*----------------------------------------------------------------------------*
	FUNCTION listFolder (tcPath)
	* Starts returning the contents of a folder.
	* Parameters:
	* {
    *	"path": "/Homework/math",
    *	"recursive": false,
    *	"include_media_info": false,
    *	"include_deleted": false,
    *	"include_has_explicit_shared_members": false,
    *	"include_mounted_folders": true
	* }
	*	ListFolderArg
	* path: String(pattern="(/(.|[\r\n])*)?|id:.*|(ns:[0-9]+(/.*)?)") A unique identifier for the file.
	* recursive: Boolean If true, the list folder operation will be applied recursively to all subfolders and the response will contain contents of 
	* all subfolders. The default for this field is False.
	* include_media_info: Boolean If true, FileMetadata.media_info is set for photo and video. The default for this field is False.
	* include_deleted: Boolean If true, the results will include entries for files and folders that used to exist but were deleted. The default for this field is False.
	* include_has_explicit_shared_members: Boolean If true, the results will include a flag for each file indicating whether or not that file has any explicit members. The default for this field is False.
	* include_mounted_folders: Boolean If true, the results will include entries under mounted folders which includes app folder, shared folder and team folder. The default for this field is True.
	* limit: UInt32? The maximum number of results to return per request. Note: This is an approximate number and there can be slightly more entries returned in some cases. This field is optional.
	* shared_link SharedLink? A shared link to list the contents of. If the link is password-protected, the password must be provided. If this field is present, ListFolderArg.path will be relative to root of the shared link. Only non-recursive mode is supported for shared link. This field is optional.
	* include_property_groups TemplateFilterBase? If set to a valid list of template IDs, FileMetadata.property_groups is set if there exists property data associated with the file and each of the listed templates. This field is optional.
	*----------------------------------------------------------------------------*
		LOCAL lcResponseValue
		lcResponseValue=''
		TRY
			WITH THIS
				IF PCOUNT()>0 THEN
					.setPath(tcPath)
				ENDIF
				
				IF .initAction() THEN 
					.urlRequest = 'https://api.dropboxapi.com/2/files/list_folder'
					.method     = 'POST'
					.addHeader  ("Content-Type", 'application/json')
					.addHeader  ("authorization", THIS.authorization)
					TEXT TO .Body PRETEXT 15 TEXTMERGE NOSHOW
		{
			"path":"<<THIS.path>>"
		}
					ENDTEXT
					.response  = .SEND()
				ENDIF
			ENDWITH
		CATCH TO loEx
			oTmp = CREATEOBJECT('catchException',THIS.bRelanzarThrow)
		ENDTRY
		RETURN IIF(THIS.isSuccess(), THIS.oResponse.GET('entries'), null)
	ENDFUNC
	*
	*----------------------------------------------------------------------------*
	FUNCTION FOUND (tcPath, tcFile)
	* Check is Exist in path a Folder or File 
	* Implementado por fuera del API de dropbox
	* Parameter:
	*
	* Return: .T. or .F.
	*----------------------------------------------------------------------------*
		LOCAL lcFile, lcPath, loEntries, lnInd, loElement, lbReturn
		STORE ''   TO lcFile, lcPath
		STORE .F.  TO lbReturn
		STORE null TO loEntries, loElement
		
		TRY
			WITH THIS
				IF PCOUNT()<1 THEN
					THROW 'Debe ingresar el nombre del archivo a buscar'
				ENDIF
				IF PCOUNT()=1 THEN
					*- Solo ingreso el nombre del archivo
					lcFile = ALLTRIM(LOWER(tcPath))
				ELSE
					lcFile = ALLTRIM(LOWER(tcFile))
					lcPath = tcPath
				ENDIF
				
				loEntries = .listFolder(lcPath)
				IF !ISNULL(loEntries) THEN
					FOR lnInd = 1 TO loEntries.nSIZE
						loElement = loEntries.GET(lnInd)
						 
						IF LOWER(loElement.GET('name'))==lcFile THEN
							lbReturn = .T.
							.oElement= loElement
							EXIT
						ENDIF
					ENDFOR
					
					*-- Esto para que funcione correctamente el metodo .isSuccess
					.msgError = IIF(!lbReturn,'Not Found '+PROPER(lcFile),'')
				ENDIF
				
			ENDWITH
		CATCH TO loEx
			oTmp = CREATEOBJECT('catchException',THIS.bRelanzarThrow)
		ENDTRY
		RETURN lbReturn
	ENDFUNC
	*
	*----------------------------------------------------------------------------*
	FUNCTION getElement()
	* Retorna el ultimo elemento que sobre el cual se estuvo trabajando.
	* Por ejemplo un FOUND()
	*----------------------------------------------------------------------------*
		RETURN THIS.oElement
	ENDFUNC
	*
	*----------------------------------------------------------------------------*
	FUNCTION createFolder (tcPath)
	* Create a folder at a given path.
	* Parameter:
	*	{
    *	"path": "/Homework/math",
    *	"autorename": false
	*	}
	*----------------------------------------------------------------------------*
		TRY
			WITH THIS
				IF PCOUNT()>0 THEN
					.setPath(tcPath)
				ENDIF
				
				IF .initAction() THEN
					.urlRequest = 'https://api.dropboxapi.com/2/files/create_folder_v2'
					.method     = 'POST'
					.addHeader  ("Content-Type", 'application/json')
					.addHeader  ("authorization", .authorization)
					TEXT TO .Body PRETEXT 15 TEXTMERGE NOSHOW
		{
			"path":"<<THIS.path>>"
		}
					ENDTEXT
					.response  = .SEND()
				ENDIF
			ENDWITH
    
		CATCH TO loEx
			oTmp = CREATEOBJECT('catchException',THIS.bRelanzarThrow)
		ENDTRY
		RETURN THIS.isSuccess()
	ENDFUNC
	*
	*----------------------------------------------------------------------------*
	FUNCTION copy (tcFrom, tcTo)
	* Copy a file or folder to a different location in the user's Dropbox.
	* If the source path is a folder all its contents will be copied.
	* Parameter:
	*	{
	*	    "from_path": "/Homework/math",
	*	    "to_path": "/Homework/algebra",
	*	    "allow_shared_folder": false,
	*	    "autorename": false,
	*	    "allow_ownership_transfer": false
	*	}
	*----------------------------------------------------------------------------*
		TRY
			WITH THIS
				IF PCOUNT()=2 THEN
					.setPath(tcFrom)
				ELSE
					THROW 'Debes ingresar el Origen y el Destino'
				ENDIF
				
				IF .initAction() THEN
					.urlRequest = 'https://api.dropboxapi.com/2/files/copy_v2'
					.method     = 'POST'
					.addHeader  ("Content-Type", 'application/json')
					.addHeader  ("authorization", THIS.authorization)
					TEXT TO .Body PRETEXT 15 TEXTMERGE NOSHOW
		{
			"from_path": "<<tcFrom>>",
			"to_path": "<<tcTo>>"
		}
					ENDTEXT
					.response  = .SEND()
					
					IF .isSuccess() THEN
						.oElement= .oResponse.GET('metadata')				
					ENDIF
				ENDIF
			ENDWITH
    
		CATCH TO loEx
			oTmp = CREATEOBJECT('catchException',THIS.bRelanzarThrow)
		ENDTRY
		RETURN THIS.isSuccess()
	ENDFUNC
	*
	*----------------------------------------------------------------------------*
	FUNCTION delete (tcPath)
	* Delete the file or folder at a given path.
	* If the path is a folder, all its contents will be deleted too.
	* A successful response indicates that the file or folder was deleted. 
	* The returned metadata will be the corresponding FUNCTIONileMetadata or FolderMetadata 
	* for the item at time of deletion, and not a DeletedMetadata object.
	* Parameter:
	*	{
	*	"path": "/Homework/math/Prime_Numbers.txt"
	*	}
	*----------------------------------------------------------------------------*
		TRY
			WITH THIS
				IF PCOUNT()>0 THEN
					.setPath(tcPath)
				ELSE
					THROW 'Debes ingresar el nombre del archivo a borrar'
				ENDIF
				
				IF .initAction() THEN
					.urlRequest = 'https://api.dropboxapi.com/2/files/delete_v2'
					.method     = 'POST'
					.addHeader  ("Content-Type", 'application/json')
					.addHeader  ("authorization", THIS.authorization)
					TEXT TO .Body PRETEXT 15 TEXTMERGE NOSHOW
		{
			"path":"<<THIS.path>>"
		}
					ENDTEXT
					.response  = .SEND()
					
				ENDIF
			ENDWITH
    
		CATCH TO loEx
			oTmp = CREATEOBJECT('catchException',THIS.bRelanzarThrow)
		ENDTRY
		RETURN THIS.isSuccess()
	ENDFUNC
	*
	*----------------------------------------------------------------------------*
	FUNCTION move (tcFrom, tcTo)
	* Move a file or folder to a different location in the user's Dropbox.
	* If the source path is a folder all its contents will be moved.
	* Parameter:
	*	{
	*    "from_path": "/Homework/math",
	*    "to_path": "/Homework/algebra",
	*    "allow_shared_folder": false,
	*    "autorename": false,
	*    "allow_ownership_transfer": false
	*	}
	*----------------------------------------------------------------------------*
		TRY
			WITH THIS
				IF PCOUNT()=2 THEN
					.setPath(tcFrom)
				ELSE
					THROW 'Debes ingresar el Origen y el Destino'
				ENDIF
				
				IF .initAction() THEN
					.urlRequest = 'https://api.dropboxapi.com/2/files/move_v2'
					.method     = 'POST'
					.addHeader  ("Content-Type", 'application/json')
					.addHeader  ("authorization", THIS.authorization)
					TEXT TO .Body PRETEXT 15 TEXTMERGE NOSHOW
		{
			"from_path": "<<tcFrom>>",
			"to_path": "<<tcTo>>"
		}
					ENDTEXT
					.response  = .SEND()
					IF .isSuccess() THEN
						.oElement= .oResponse.GET('metadata')				
					ENDIF
				ENDIF
			ENDWITH
    
		CATCH TO loEx
			oTmp = CREATEOBJECT('catchException',THIS.bRelanzarThrow)
		ENDTRY
		RETURN THIS.isSuccess()
	ENDFUNC
	*
	*----------------------------------------------------------------------------*
	FUNCTION search (tcPath, tcQuery)
	* Searches for files and folders.
	* Note: Recent changes may not immediately be reflected in search results due to a short delay in indexing.
	* Parameter:
	*	{
	*	    "path": "",
	*	    "query": "prime numbers",
	*	    "start": 0,
	*	    "max_results": 100,
	*	    "mode": "filename"
	*	}
	*----------------------------------------------------------------------------*
		TRY
			WITH THIS
				IF PCOUNT()=2 THEN
					.setPath(tcPath)
				ELSE
					THROW 'Debes ingresar el path y el archivo a buscar'
				ENDIF
				
				IF .initAction() THEN
					.urlRequest = 'https://api.dropboxapi.com/2/files/search'
					.method     = 'POST'
					.addHeader  ("Content-Type", 'application/json')
					.addHeader  ("authorization", THIS.authorization)
					TEXT TO .Body PRETEXT 15 TEXTMERGE NOSHOW
		{
			"path": "<<tcPath>>",
			"query": "<<tcQuery>>"
		}
					ENDTEXT
					.response  = .SEND()
					IF .isSuccess() THEN
						loElement= .oResponse.GET('matches')
						IF loElement.nSize = 0 THEN
							.oElement = null
							.msgError = 'File not found'
						ELSE
							loElement= loElement.GET(1)
							.oElement= loElement.GET('metadata')
						ENDIF
					ENDIF
				ENDIF
			ENDWITH
    
		CATCH TO loEx
			oTmp = CREATEOBJECT('catchException',THIS.bRelanzarThrow)
		ENDTRY
		RETURN THIS.isSuccess()
	ENDFUNC
	*
	*----------------------------------------------------------------------------*
	FUNCTION upload (tcToPath, tcFileUpLoad)
	* Create a new file with the contents provided in the request.
	* Do not use this to upload a file larger than 150 MB. Instead, create an upload session 
	* with upload_session/start.
	* Calls to this endpoint will count as data transport calls for any Dropbox Business teams
	* with a limit on the number of data transport calls allowed per month. For more information, 
	* see the Data transport limit page.
	* Parameter:
	*	{
	*	    "path": "/Homework/math/Matrices.txt",
	*	    "mode": "add",
	*	    "autorename": true,
	*	    "mute": false,
	*	    "strict_conflict": false
	*	}
	*----------------------------------------------------------------------------*
		LOCAL lcFileContent, lnFileSize, lcToPathFile
		TRY
			WITH THIS
				IF PCOUNT()=2 THEN
					.setPath(tcToPath)
				ELSE
					THROW 'Debes ingresar el path y el archivo a buscar'
				ENDIF
				
				*-- Verifico que exista el archivo a ser enviado
				ADIR(laFile,tcFileUpLoad)

				lcFileContent= FILETOSTR(tcFileUpLoad) &&Contenido del Archivo a subir
				lnFileSize   = laFile[2]               &&Tamaño del Archivo
				lcToPathFile = ALLTRIM(LOWER(tcToPath))+JUSTFNAME(tcFileUpLoad)

				IF .initAction() THEN
					.urlRequest = 'https://content.dropboxapi.com/2/files/upload'
					.method     = 'POST'
					
					.addHeader  ("User-Agent", 'api-explorer-client')
					.addHeader  ("authorization", THIS.authorization)
					.addHeader  ("Content-Type", 'application/octet-stream')
					.addHeader  ("Dropbox-API-Arg", '{"path":"'+lcToPathFile+'","property_groups":[]}')
					.addHeader  ("Content-Length", lnFileSize)

					TEXT TO .Body PRETEXT 15 TEXTMERGE NOSHOW
<<lcFileContent>>
					ENDTEXT
					.response  = .SEND()

					IF .isSuccess() THEN
						.oElement = .oResponse
					ENDIF
				ENDIF
			ENDWITH
    
		CATCH TO loEx
			oTmp = CREATEOBJECT('catchException',THIS.bRelanzarThrow)
		ENDTRY
		RETURN THIS.isSuccess()
	ENDFUNC
	*
	*----------------------------------------------------------------------------*
	FUNCTION download (tcFilePathDownload)
	* Parameter:
	*  tcFilePathDownload: Es el Archivo con le path incluido a descargar.
	*                      ó, el id del mismo.
	*
	* Download a file from a user's Dropbox.
	* Parameter:
	*Example: name file
	*	{
	*	    "path": "/Homework/math/Prime_Numbers.txt"
	*	}
	*Example: id
	*	{
	*	    "path": "id:a4ayc_80_OEAAAAAAAAAYa"
	*	}
	*----------------------------------------------------------------------------*
		LOCAL lcFileContent, lnFileSize, lcToPathFile
		TRY
			WITH THIS
				IF PCOUNT()=1 THEN
					.setPath(tcFilePathDownload)
				ELSE
					THROW 'Debes ingresar el path y el archivo a buscar'
				ENDIF

				IF .initAction() THEN
					.urlRequest = 'https://content.dropboxapi.com/2/files/download'
					.method     = 'POST'
					
					.addHeader  ("User-Agent", 'api-explorer-client')
					.addHeader  ("authorization", THIS.authorization)
					.addHeader  ("Content-Type", 'application/octet-stream')
					.addHeader  ("Dropbox-API-Arg", '{"path":"'+tcFilePathDownload+'"}')

					.response  = .SEND()
				ENDIF
			ENDWITH
    
		CATCH TO loEx
			oTmp = CREATEOBJECT('catchException',THIS.bRelanzarThrow)
		ENDTRY
		RETURN THIS.isSuccess()
	ENDFUNC
	*
	*----------------------------------------------------------------------------*
	FUNCTION download_zip (tcFolderPathDownload)
	* Parameter:
	*  tcFolderPathDownload: La carpeta con le path incluido a descargar.
	*                        ó, el id del mismo.
	*
	* Download a folder from the user's Dropbox, as a zip file. The folder must be less than
	* 20 GB in size and have fewer than 10,000 total files. The input cannot be a single file.
	* Any single file must be less than 4GB in size.
	* Parameter:
	*Example: name file
	*	{
	*	    "path": "/Homework/math"
	*	}
	*Example: id
	*	{
	*	    "path": "id:a4ayc_80_OEAAAAAAAAAYa"
	*	}
	*----------------------------------------------------------------------------*
		LOCAL tcFolderPathDownload
		TRY
			WITH THIS
				IF PCOUNT()=1 THEN
					.setPath(tcFolderPathDownload)
				ELSE
					THROW 'Debes ingresar el path y el archivo a buscar'
				ENDIF

				IF .initAction() THEN
					.urlRequest = 'https://content.dropboxapi.com/2/files/download_zip'
					.method     = 'POST'
					
					.addHeader  ("User-Agent", 'api-explorer-client')
					.addHeader  ("authorization", THIS.authorization)
					.addHeader  ("Content-Type", 'application/octet-stream')
					.addHeader  ("Dropbox-API-Arg", '{"path":"'+tcFolderPathDownload+'"}')

					.response  = .SEND()
				ENDIF
			ENDWITH
    
		CATCH TO loEx
			oTmp = CREATEOBJECT('catchException',THIS.bRelanzarThrow)
		ENDTRY
		RETURN THIS.isSuccess()
	ENDFUNC
	*	
	*----------------------------------------------------------------------------*
	FUNCTION destroy
	*
	*----------------------------------------------------------------------------*

	ENDFUNC
	
ENDDEFINE