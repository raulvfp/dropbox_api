*/
* @since:  1.0
*
* @author: Raúl Juárez <raul.jrz@gmail.com>
* @date: 26.05.2018 - 00:58
*/
DEFINE CLASS test_dropbox_api AS FxuTestCase OF FxuTestCase.prg
*----------------------------------------------------------------------

	#IF .F.
		LOCAL THIS AS test_dropbox_api OF test_dropbox_api.prg
	#ENDIF
	oObject      = ''  &&Este es el objecto que va a ser evaluado
	oldPath      = ''
	oldProcedure = ''
	oldDefault   = ''

	* Token del API de la cuenta de pruebas
	*authorization='Bearer 2BaNplW-NkAAAAAAAAAACnD2uYsT9R8Kvoy0hg-BWunSrO2M4awBI75Ggf0FEb-d'

	* Token del API de Mi Nueva Estancia
	authorization='Bearer r6IU-ywA36AAAAAAAAAAvWfGEXJV-gcX61CiJ3ZHn4aJ67X0pjVwyU-7k9OY7lQx'

	*--------------------------------------------------------------------
	FUNCTION SETUP
	* Configuración base de todos los Test de esta clase
	*--------------------------------------------------------------------
		*SET PATH TO pathraizdelprojecto
		THIS.oldPath     =SET('PATH')
		THIS.oldProcedure=SET('PROCEDURE')
		THIS.oldDefault  =SET('DEFAULT')
		*THIS.MessageOut('Procedures: '+SET("PROCEDURE"))
		*THIS.MessageOut('Path......: '+SET("PATH"))
		*THIS.MessageOut('Default...: '+SET("DEFAULT"))
		*THIS.MessageOut('============================================================')

		SET PROCEDURE TO src\dropbox_api.prg ADDITIVE
		SET PROCEDURE TO ..\ajaxRest\src\ajaxRest ADDITIVE
		SET PROCEDURE TO ..\catchException\src\catchException ADDITIVE
		SET PROCEDURE TO ..\json\src\json ADDITIVE
		SET PATH TO (THIS.oldPath +";"+ADDBS(SYS(5)+CURDIR())+'src')
		THIS.MessageOut('Procedures:  '+STRTRAN(SET("PROCEDURE"),",",CHR(13)+SPACE(12)))
		THIS.MessageOut('Path......: '+STRTRAN(SET("PATH")     ,";",CHR(13)+SPACE(12)))
		THIS.MessageOut('Default...: '+SET("DEFAULT"))
		THIS.MessageOut('============================================================')
		THIS.MessageOut('')
		THIS.oObject = CREATEOBJECT('dropbox_api')

		* Cargo en el setup, ya que lo voy a necesitar para todos los test de los metodos
		THIS.oObject.authorization=THIS.authorization
	ENDFUNC

	*---------------------------------------------------------------------
	FUNCTION testExisteObjecto()
	* Verifica la existencia del objecto...
	*---------------------------------------------------------------------
		THIS.AssertNotNull('No existe el objecto',THIS.oObject)
	ENDFUNC

	*--------------------------------------------------------------------
	FUNCTION TearDown
	* Restaura el estado anterior del ambiente de desarrollo
	*--------------------------------------------------------------------
		SET PATH TO      (THIS.oldPath)
		SET PROCEDURE TO (THIS.oldProcedure)
		SET DEFAULT TO   (THIS.oldDefault)
	ENDFUNC

	*--------------------------------------------------------------------
	FUNCTION MessageOutResponse()
	*--------------------------------------------------------------------
		.MessageOut('--------------')
		.MessageOut('Response Value: ';
					+CHR(13)+SPACE(12)+.oObject.getResponse())
		.MessageOut('Error Messages: ';
					+CHR(13)+SPACE(12)+.oObject.getMsgError())
		.MessageOut('--------------')
	ENDFUNC
	
	*--------------------------------------------------------------------
	FUNCTION ShowElement()
	*--------------------------------------------------------------------
		*/ Solo le envio un Archivo que SI existe/*
		loElement = .oObject.getElement()
		.MessageOut('File id........: '+loElement.get("id"))
		.MessageOut('File Name......: '+loElement.get("name"))
		.MessageOut('File Path......: '+loElement.get("path_display"))
		.MessageOut('client_modified: '+loElement.get("client_modified"))
		.MessageOut('server_modified: '+loElement.get("server_modified"))
		.MessageOut('tag............: '+loElement.get("tag"))
		.MessageOut('File size......: '+TRANSFORM(loElement.get("size")))
	ENDFUNC
	
	*--------------------------------------------------------------------
	FUNCTION testlistFolder_xError
	* Note: Pruebo el metodo ListFolder por el error
	*--------------------------------------------------------------------
		LOCAL lcExpectedValue, lcResponseValue, lcFolderList
		lcExpectedValue = ''
		lcResponseValue = ''
		
		lcFolderList    = "/Apps/updog/delivery/NoExist"
		
		WITH THIS
			loEntries = .oObject.listFolder(lcFolderList)
			.AssertFalse(.oObject.isSuccess(),'OJO, le pedi un directorio q no existe')
			.MessageOutResponse()
		ENDWITH
	ENDFUNC
	
	*--------------------------------------------------------------------
	FUNCTION testlistFolder_xOK
	* Note:
	*--------------------------------------------------------------------
		LOCAL lcExpectedValue, lcResponseValue, lcFolderList
		lcExpectedValue = ''
		lcResponseValue = ''
		
		lcFolderList    = "/Apps/updog/delivery/datajson"
		
*!*			TEXT TO lcSentence TEXTMERGE NOSHOW
*!*	{
*!*		"path": "/Apps/updog/delivery/datajson",
*!*		"recursive": false,
*!*		"include_media_info": false,
*!*		"include_deleted": false,
*!*		"include_has_explicit_shared_members": false,
*!*		"include_mounted_folders": true
*!*	}
*!*			ENDTEXT
		WITH THIS
			loEntries = .oObject.listFolder(lcFolderList)
			.AssertTrue(.oObject.isSuccess(),'Atención no existe el directorio')
			
			.MessageOutResponse()
			
			FOR lnInd = 1 TO loEntries.nSIZE
				loElement = loEntries.GET(lnInd)
				.MessageOut('Element n'+TRANSFORM(lnInd)+': ';
						+loElement.GET("path_display")+;
							SPACE(50-LEN(loElement.GET("path_display")))+'| ';
						+TRANSFORM(loElement.GET("tag"));
						 )
			ENDFOR
			.MessageOut(REPLICATE('-',10))
		ENDWITH
	ENDFUNC
	
	*--------------------------------------------------------------------
	FUNCTION testFOUND_xError
	* Note: Chequeo el metodo de busqueda por el error, buscando algo q no existe
	*--------------------------------------------------------------------
		LOCAL lcFolder, lcFiler
		lcFolder = "/Apps/updog/delivery/datajson"
		lcFiler  = "Falso_archivo.txt"
		
		LOCAL lcExpectedValue, lcResponseValue
		lcExpectedValue = 'Not Found '+lcFiler
		lcResponseValue = ''
		
		WITH THIS
			*/ Existe Carpeta, No existe Archivo /*
			.AssertFalse(.oObject.FOUND(lcFolder, lcFiler),'Se esperaba un error')
			.MessageOutResponse()

			.AssertEquals(LEFT(lcExpectedValue,50),;
						  LEFT(.oObject.getMsgError(),50), 'Se esperaba otra respuesta del Servidor')
			
			*/ NO existe Carpeta, No existe Archivo /*
			lcFolder = '/noexiste'
			.AssertFalse(.oObject.FOUND(lcFolder, lcFiler),'Se esperaba un error')
			.MessageOutResponse()
		
			*/ Solo le envio un Archivo que No existe/*
			lcFolder = '/noexiste'
			.AssertFalse(.oObject.FOUND(lcFiler),'Se esperaba un error')
			.MessageOutResponse()

		ENDWITH
	ENDFUNC

	*--------------------------------------------------------------------
	FUNCTION testFOUND_xOK
	* Note: Chequeo el metodo de busqueda, en carpeta q existe un archivo q existe
	*--------------------------------------------------------------------
		LOCAL lcFolder, lcFiler
		lcFolder = "/Apps/updog/delivery/datajson"
		lcFiler  = "ci_deliv.jso"
		
		LOCAL lcExpectedValue, lcResponseValue
		lcExpectedValue = 'Not Found '+lcFiler
		lcResponseValue = ''
		
		WITH THIS
			*/ Existe Carpeta, No existe Archivo /*
			.AssertTrue(.oObject.FOUND(lcFolder, lcFiler),'Se esperaba un error')
			.MessageOutResponse()

			IF .oObject.isSuccess() THEN
				.ShowElement()
			ENDIF
		ENDWITH
	ENDFUNC
	
	*--------------------------------------------------------------------
	FUNCTION testCreateFolder_xOK
	* Note: Para crear una carpeta. Evaluo el error
	*--------------------------------------------------------------------		
		LOCAL lcFolder, lcFiler
		lcFolder= "/Apps/updog/delivery/datajson/"
		lcFiler = "newCarpetita"
		
		WITH THIS
			IF .oObject.FOUND(lcFolder, lcFiler) THEN
				.MessageOut('Existe la carpeta, la voy a borrar')
				.oObject.DELETE(lcFolder+lcFiler)
			ENDIF
			.AssertTrue(.oObject.CREATEFOLDER(lcFolder+lcFiler),'Se esperaba un true para lo CreateFolder')
			.MessageOutResponse()
						
			.AssertTrue(.oObject.FOUND(lcFolder, lcFiler),'Atención no se creeo la carpeta')
			.ShowElement()
		ENDWITH
	ENDFUNC
	
	*--------------------------------------------------------------------
	FUNCTION testCreateFolder_xError
	* Note: Para crear una carpeta. Evaluo el error
	*--------------------------------------------------------------------
		LOCAL lcExpectedValue, lcResponseValue
		lcExpectedValue = 'Path Conflict Folder'
		lcResponseValue = ''
		
		WITH THIS
			.AssertFalse(.oObject.CREATEFOLDER("/Apps/updog/delivery/datajson/newcarpetita"),'Se esperaba un error')
			.MessageOutResponse()
			.AssertEquals(LEFT(lcExpectedValue,20),;
						  LEFT(.oObject.getMsgError(),20), 'Se esperaba otra respuesta del Servidor')
		ENDWITH
	ENDFUNC
	
	*--------------------------------------------------------------------
	FUNCTION testDelete_xError
	* Note: Intento borrar un archivo que no existe
	*--------------------------------------------------------------------
		LOCAL lcExpectedValue, lcResponseValue
		lcExpectedValue = 'Path Lookup Not Found'
		lcResponseValue = ''
		
		LOCAL lcPath
		lcPath = "/Apps/updog/delivery/datajson/NoExiste.TXT"
		
		WITH THIS
			.AssertFalse(.oObject.DELETE(lcPath),'Se esperaba un error')
			.MessageOutResponse()
			.AssertEquals(lcExpectedValue,LEFT(.oObject.getMsgError(),21), 'Failure')
		ENDWITH
	ENDFUNC

	*--------------------------------------------------------------------
	FUNCTION testDelete_xOK
	* Note: Intento borrar un archivo que no existe
	*--------------------------------------------------------------------
		LOCAL lcPath
		lcPath = "/Apps/updog/delivery/datajson/newCarpetita"

		WITH THIS
			.AssertTrue(.oObject.DELETE(lcPath),'Ojo, no se borro')
			.MessageOutResponse()
		ENDWITH
	ENDFUNC
	
	*--------------------------------------------------------------------
	FUNCTION testCopy_xOK
	* Note: Prueba si se puede borrar por el Error
	*--------------------------------------------------------------------
		LOCAL lcFrom, lcTo, loElement 
		lcFiler= "ci_deliv.jso"
		lcFrom = "/Apps/updog/delivery/datajson/"
		lcTo   = "/Apps/updog/delivery/datajson/new/"

		loElement=null
		WITH THIS
			IF .oObject.FOUND(lcTo, lcFiler) THEN
				.MessageOut('Existe el Archivo, lo voy a borrar')
				.oObject.DELETE(lcTo+lcFiler)
			ENDIF
			.AssertTrue(.oObject.COPY(lcFrom+lcFiler, lcTo+lcFiler),'Ojo, no se borro')
			.AssertTrue(.oObject.isSuccess(),'Ojo, no se borro')
			.MessageOutResponse()
			.ShowElement()
		ENDWITH
	ENDFUNC
	
	*--------------------------------------------------------------------
	FUNCTION testMove_xOK
	* Note: Prueba si se puede borrar por el Error
	*--------------------------------------------------------------------
		LOCAL lcFrom, lcTo, loElement 
		lcFiler= "ci_deliv.jso"
		lcFrom = "/Apps/updog/delivery/datajson/"
		lcTo   = "/Apps/updog/delivery/datajson/new/"

		loElement=null

		WITH THIS
			IF .oObject.FOUND(lcTo, lcFiler) THEN
				.MessageOut('Existe el Archivo, lo voy a borrar')
				.oObject.DELETE(lcTo+lcFiler)
			ENDIF
			.AssertTrue(.oObject.MOVE(lcFrom+lcFiler, lcTo+lcFiler),'Ojo, no se borro')
			.MessageOutResponse()
			.ShowElement()
		ENDWITH
	ENDFUNC
	
	*--------------------------------------------------------------------
	FUNCTION testSearch_xOK
	* Note: Prueba si se puede borrar por el Error
	*--------------------------------------------------------------------
		LOCAL lcFrom, lcTo, loElement 
		lcFiler= "ci_deliv.jso"
		lcFrom = "/Apps/updog/"

		loElement=null

		WITH THIS
			.AssertTrue(.oObject.Search(lcFrom, lcFiler),'Ojo, no se borro')
			.MessageOutResponse()
			.ShowElement()
		ENDWITH
	ENDFUNC	
	
	*--------------------------------------------------------------------
	FUNCTION testUpLoad_xOK
	* Note: Subir un archivo a dropbox
	*--------------------------------------------------------------------
		LOCAL lcToPath, lcFile, loElement 
		lcFile   = "Z:\home\rauljrz\win7\Downloads\relojsistema.prg"
		lcToPath = "/Apps/updog/delivery/datajson/"

		loElement=null

		WITH THIS
			.oObject.isLogger   = .f. &&Para llegar un log del proceso

			.AssertTrue(.oObject.UpLoad(lcToPath, lcFile),'Ojo, no se borro')
			.MessageOutResponse()
			.ShowElement()
		ENDWITH
	ENDFUNC

	*--------------------------------------------------------------------
	FUNCTION testDownLoad_xOK
	* Note: Descargar un archivo
	*--------------------------------------------------------------------
		LOCAL lcFromPath, lcFile, loElement 
		lcFromPath = "/Apps/updog/delivery/datajson/relojsistema.prg"

		loElement=null

		WITH THIS
			.oObject.isLogger   = .f. &&Para llegar un log del proceso

			.AssertTrue(.oObject.DownLoad(lcFromPath),'Ojo, no se borro')
			.MessageOutResponse()
		ENDWITH
	ENDFUNC

	*--------------------------------------------------------------------
	FUNCTION testDownLoadZip_xOK
	* Note: Descagar una carpeta en formato zip
	*--------------------------------------------------------------------
		LOCAL lcFromPath, lcFile, loElement 
		lcFromPath = "/Apps/updog/delivery/datajson/prov"

		loElement=null

		WITH THIS
			.oObject.isLogger   = .f. &&Para llegar un log del proceso

			.AssertTrue(.oObject.Download_Zip(lcFromPath),'Ojo, no se borro')
			.MessageOutResponse()
		ENDWITH
	ENDFUNC	
ENDDEFINE
*----------------------------------------------------------------------
* The three base class methods to call from your test methods are:
*
* THIS.AssertTrue	    (<Expression>, "Failure message")
* THIS.AssertEquals	    (<ExpectedValue>, <Expression>, "Failure message")
* THIS.AssertNotNull	(<Expression>, "Failure message")
* THIS.MessageOut       (<Expression>)
*
* Test methods (through their assertions) either pass or fail.
*----------------------------------------------------------------------

* AssertNotNullOrEmpty() example.
*------------------------------
*FUNCTION TestObjectWasCreated
*   THIS.AssertNotNullOrEmpty(THIS.oObjectToBeTested, "Test Object was not created")
*ENDFUNC
