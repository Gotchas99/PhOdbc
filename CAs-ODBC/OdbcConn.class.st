Class {
	#name : #OdbcConn,
	#superclass : #Object,
	#instVars : [
		'statements',
		'handle'
	],
	#pools : [
		'OdbcConstants'
	],
	#category : #'CAs-ODBC'
}

{ #category : #accessing }
OdbcConn >> allocStatement [
	| stmt tmp |
	stmt := ExternalAddress new.
	(self uFFIallocstmt: stmt hdbc: handle) = SQL_SUCCESS
		ifTrue: [ tmp := OdbcStmt new stmt: stmt.
			statements add: tmp.
			^ tmp ] 
		ifFalse: [ OdbcError signalFor: self ]
]

{ #category : #accessing }
OdbcConn >> disconnect [
	statements ifNotNil: [ statements do: [ :s | s freeHandle ] ].
	statements removeAll.handle isNull
		ifTrue: [ ^ self ].

	self uFFIsqlDisconnect: handle
]

{ #category : #accessing }
OdbcConn >> driverConnect: connString [

	^ self uFFIdriverConnect: connString hdbc: handle
]

{ #category : #sample }
OdbcConn >> driverConnectScott [
	^ self driverConnect: 'DSN=mysql-test' 
]

{ #category : #accessing }
OdbcConn >> ffiLibrary [
	^ OdbcLibrary
]

{ #category : #accessing }
OdbcConn >> freeHandle [
	handle isNull
		ifTrue: [ ^ self ].
	self uFFIfreeHandle: handle.
	handle beNull
]

{ #category : #accessing }
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
		      handle: handle
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
OdbcConn >> handle [
 ^	handle
]

{ #category : #'initialize - release' }
OdbcConn >> handleType [
	^ SQL_HANDLE_DBC 
]

{ #category : #accessing }
OdbcConn >> hdbc:aHdbc [
handle:= aHdbc
]

{ #category : #'initialize - release' }
OdbcConn >> initialize [
	super initialize.
	handle := ExternalAddress new.
statements := OrderedCollection new
]

{ #category : #'ffi calls' }
OdbcConn >> uFFIallocstmt: stmt hdbc: handle [
	"Statement SQL_HANDLE_STMT = 3"

	SQL_SUCCESS_WITH_INFO.
	SQL_ERROR.
	SQL_INVALID_HANDLE.
	^ self ffiCall:
		  #( short SQLAllocHandle #( 3 , SQLHDBC handle , SQLHANDLE
		        * stmt ) )
]

{ #category : #'ffi calls' }
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

{ #category : #'ffi calls' }
OdbcConn >> uFFIfreeHandle: handle [
	"SQLRETURN  SQL_API SQLFreeHandle(SQLSMALLINT HandleType, SQLHANDLE Handle);"
"SQL_HANDLE_DBC = 2"
	^ self ffiCall:
		  #( SQLRETURN SQLFreeHandle #(  2 , SQLHANDLE handle ) )
]

{ #category : #'ffi calls' }
OdbcConn >> uFFIsqlDisconnect: handle [
	"SQLRETURN  SQL_API SQLDisconnect(SQLHDBC ConnectionHandle);"

	^ self ffiCall: #( SQLRETURN SQLDisconnect #( SQLHDBC handle ) )
]
