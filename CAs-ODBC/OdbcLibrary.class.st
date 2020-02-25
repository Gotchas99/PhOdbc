Class {
	#name : #OdbcLibrary,
	#superclass : #FFILibrary,
	#pools : [
		'OdbcConstants'
	],
	#category : #'CAs-ODBC'
}

{ #category : #'accessing platform' }
OdbcLibrary >> macModuleName [
"don't know. just to keep template"
	^ 'xxxxxxxxxxxxx.dylib'
]

{ #category : #'class initialization' }
OdbcLibrary >> uFFIgetDiagRecType: handleType handle: handle recNumber: recNumber sqlState: sqlState nativeErrorPtr: nativeErrorPtr messageText: messageText bufferLength: bufferLength textLengthPtr: textLengthPtr [
	"SQLRETURN SQLGetDiagRec(  
     SQLSMALLINT     HandleType,       SQLHANDLE       Handle,  
     SQLSMALLINT     RecNumber,       SQLCHAR *       SQLState,  
     SQLINTEGER *    NativeErrorPtr,       SQLCHAR *       MessageText,  
     SQLSMALLINT     BufferLength,       SQLSMALLINT *   TextLengthPtr);  "

	^ self
		ffiCall:
			#(SQLRETURN SQLGetDiagRec #(SQLSMALLINT handleType , SQLHANDLE handle , SQLSMALLINT recNumber , SQLCHAR * sqlState , SQLINTEGER * nativeErrorPtr , SQLCHAR * messageText , SQLSMALLINT bufferLength , SQLSMALLINT * textLengthPtr))
]

{ #category : #'accessing platform' }
OdbcLibrary >> unixModuleName [
	"to be found out"

	
	^ 'libfreetype.so.6'
]

{ #category : #'accessing platform' }
OdbcLibrary >> win32ModuleName [
	^ 'odbc32.dll'

	"^ 'c:\windows\system32\odbc32.dll' "
	"^ 'c:\windows\sysWOW64\odbc32.Xdll' "
]

{ #category : #'accessing platform' }
OdbcLibrary >> win64ModuleName [
	^ #('odbc32.dll')
]
