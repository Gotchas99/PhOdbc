"
Odbc library

Sql server driver 17:
https://docs.microsoft.com/en-us/sql/connect/odbc/linux-mac/installing-the-microsoft-odbc-driver-for-sql-server?view=sql-server-ver15

ODBC for Linux:
https://compscinotes.wordpress.com/2010/04/18/unixodbc-mysql-sample-program/
"
Class {
	#name : #OdbcLibrary,
	#superclass : #FFILibrary,
	#pools : [
		'OdbcConstants'
	],
	#category : #'CAs-ODBC'
}

{ #category : #'as yet unclassified' }
OdbcLibrary class >> docLinks [
	"ODBC 64-bits
	https://docs.microsoft.com/en-us/sql/odbc/reference/odbc-64-bit-information?view=sql-server-ver15"
]

{ #category : #examples }
OdbcLibrary class >> sample [
	<script>
	| conn stmt sql |
	OdbcEnv default allocEnvironment.
	conn := OdbcEnv default allocConnection.
	conn
		driverConnect:
			'DRIVER={ODBC Driver 17 for SQL Server};Server=131.97.145.26;Database=LATExtractions;Integrated Security=False;PWD=Wmz!EeA!*k3pkSzw;Persist Security Info=True;UID=latextractions_write;Connect Timeout=5;ApplicationIntent=ReadWrite'.
	stmt := conn allocStatement.
	sql := 'SELECT TOP (2) [NativeReadingId]
      ,[ChassisSeries]
      ,[ChassisNumber]
       ,[LoggedPatternID] 
		,[ReadoutDate]
      ,CONVERT(varchar(max), [XmlMessage]) as myXML 
  FROM [LATExtractions].[dbo].[EXT_Prototype3]'.
	stmt sql: sql.
	stmt onDone: [ :rs | rs inspect ].
	stmt onError: [ :ex | self halt ].
	stmt execute.
	stmt close.
	conn
		disconnect
]

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
OdbcLibrary >> unix64LibraryName [
	"On different flavors of linux the path to library may differ
depending on OS distro or whether system is 32 or 64 bit.
Packages such as snapcraft can also change the path.
Look in a number of known locations, or LD_LIBRARY_PATH."

	#('/lib/x86_64-linux-gnu' '/usr/lib'   '/usr/lib/x86_64-linux-gnu')
		,
			(((OSEnvironment current getEnv: 'LD_LIBRARY_PATH') ifNil: [ '' ])
				substrings: ':')
		do: [ :path | 
			| libraryPath |
			libraryPath := path asFileReference / 'libodbc.so.1'.
			libraryPath exists
				ifTrue: [ ^ libraryPath fullName ] ].
	self
		error:
			'Cannot locate ODBC library. Please check if it installed
on your system'
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
