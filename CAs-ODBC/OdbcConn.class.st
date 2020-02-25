Class {
	#name : #OdbcConn,
	#superclass : #Object,
	#instVars : [
		'hdbc'
	],
	#pools : [
		'OdbcConstants'
	],
	#category : #'CAs-ODBC'
}

{ #category : #accessing }
OdbcConn >> allocStatement [
	| stmt ret |
	stmt := ExternalAddress new.
	(ret:= self uFFIallocstmt: stmt hdbc: hdbc) = SQL_SUCCESS ifTrue:[
	^ OdbcStmt new stmt: stmt]ifFalse:[^ ret]
]

{ #category : #accessing }
OdbcConn >> disconnect [

	^ self uFFIsqlDisconnect: hdbc
]

{ #category : #accessing }
OdbcConn >> driverConnect: connString [
	^self uFFIdriverConnect: connString hdbc: hdbc
]

{ #category : #accessing }
OdbcConn >> driverConnectScott [
	^self driverConnect: 'DSN=mysql-test'
]

{ #category : #accessing }
OdbcConn >> ffiLibrary [
	^ OdbcLibrary
]

{ #category : #accessing }
OdbcConn >> freeHandle [

	^ self uFFIfreeHandle: hdbc 
]

{ #category : #'class initialization' }
OdbcConn >> getDiagRec [
	"SQLRETURN SQLGetDiagRec(  
     SQLSMALLINT     HandleType,       SQLHANDLE       Handle,  
     SQLSMALLINT     RecNumber,       SQLCHAR *       SQLState,  
     SQLINTEGER *    NativeErrorPtr,       SQLCHAR *       MessageText,  
     SQLSMALLINT     BufferLength,       SQLSMALLINT *   TextLengthPtr);  "

	| rc recNumber sqlState nativeErrorPtr messageText bufferLength textLengthPtr |
	recNumber := 1.
	sqlState := ByteArray new: 10.
	nativeErrorPtr := ByteArray new: FFIInt32 externalTypeSize.
	bufferLength := 2048.

	messageText := ByteArray new: bufferLength.
	textLengthPtr := ByteArray new: FFIInt32 externalTypeSize.
	rc := OdbcLibrary uniqueInstance
		      uFFIgetDiagRecType: SQL_HANDLE_DBC
		      handle: hdbc
		      recNumber: recNumber
		      sqlState: sqlState
		      nativeErrorPtr: nativeErrorPtr
		      messageText: messageText
		      bufferLength: bufferLength
		      textLengthPtr: textLengthPtr.
	^ { 
		  (sqlState first: 5) asString.
		  (messageText first: (textLengthPtr signedShortAt: 1)) asString }
]

{ #category : #accessing }
OdbcConn >> hdbc:aHdbc [
hdbc:= aHdbc
]

{ #category : #accessing }
OdbcConn >> uFFIallocstmt: stmt hdbc: handle [
	"Statement SQL_HANDLE_STMT = 3"

	SQL_SUCCESS_WITH_INFO.
	SQL_ERROR.
	SQL_INVALID_HANDLE.
	^ self ffiCall:
		  #( short SQLAllocHandle #( 3 , SQLHDBC handle , SQLHANDLE
		        * stmt ) )
]

{ #category : #accessing }
OdbcConn >> uFFIdriverConnect: connString hdbc: handle [
	"SQLRETURN SQLDriverConnect(  SQLHDBC ConnectionHandle,
  SQLHWND WindowHandle,  SQLCHAR *InConnectionString,
  SQLSMALLINT StringLength1,  SQLCHAR *OutConnectionString,
  SQLSMALLINT BufferLength,  SQLSMALLINT *StringLength2Ptr,
  SQLUSMALLINT DriverCompletion) "

	^ self ffiCall:
		  #( short SQLDriverConnect #( SQLHDBC handle , 0 , SQLCHAR * connString
		        , -3 , 0 , 0 , 0 , 0 ) )
	"SQL_NTS = -3, SQL_DRIVER_NOPROMPT=0"
]

{ #category : #accessing }
OdbcConn >> uFFIfreeHandle: handle [
	"SQLRETURN  SQL_API SQLFreeHandle(SQLSMALLINT HandleType, SQLHANDLE Handle);"
"SQL_HANDLE_DBC = 2"
	^ self ffiCall:
		  #( SQLRETURN SQLFreeHandle #(  2 , SQLHANDLE handle ) )
]

{ #category : #accessing }
OdbcConn >> uFFIsqlDisconnect: handle [
	"SQLRETURN  SQL_API SQLDisconnect(SQLHDBC ConnectionHandle);"

	^ self ffiCall: #( SQLRETURN SQLDisconnect #( SQLHDBC handle ) )
]
