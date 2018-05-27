*
*|--------------------------------------------------------------------------
*| dropbox_api
*|--------------------------------------------------------------------------
*|
*| Archivo principal del sistema
*| Author......: Raúl Jrz (raul.jrz@gmail.com) 
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
	authorization  = ''

	*----------------------------------------------------------------------------*
	FUNCTION listFolder (leValue)
	* Starts returning the contents of a folder.
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
	* recursive: Boolean If true, the list folder operation will be applied recursively to all subfolders and the response will contain contents of all subfolders. The default for this field is False.
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
				.urlRequest = 'https://api.dropboxapi.com/2/files/list_folder'
				.method     = 'POST'
				.addHeader  ("Content-Type", 'application/json')
				.addHeader  ("authorization", THIS.authorization)
				TEXT TO .Body PRETEXT 15 TEXTMERGE NOSHOW
	{
		"path":"<<leValue>>"
	}
				ENDTEXT		
				lcResponseValue = .SEND()
			ENDWITH
		CATCH TO loEx
			oTmp = CREATEOBJECT('catchException',THIS.bRelanzarThrow)
		ENDTRY
		RETURN lcResponseValue
	ENDFUNC
	
	*----------------------------------------------------------------------------*
	FUNCTION destroy
	*
	*----------------------------------------------------------------------------*

	ENDFUNC
	
ENDDEFINE