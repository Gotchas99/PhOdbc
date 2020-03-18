Class {
	#name : #OdbcConn,
	#superclass : #Object,
	#instVars : [
		'env',
		'handle',
		'statements',
		'connected'
	],
	#pools : [
		'OdbcConstants'
	],
	#category : #'CAs-ODBC'
}

{ #category : #accessing }
OdbcConn >> allocStatement [
	| hStmt newStmt |
	hStmt := ExternalAddress new.
	(self uFFIallocstmt: hStmt hdbc: handle) = SQL_SUCCESS
		ifTrue: [ newStmt := OdbcStmt new stmt: hStmt.
			statements add: newStmt.
			newStmt conn: self.
			^ newStmt ]
		ifFalse: [ OdbcError signal ]
]

{ #category : #accessing }
OdbcConn >> disconnect [
	statements ifNotNil: [ statements do: [ :s | s close ] ].
	statements removeAll.
	handle isNull
		ifTrue: [ ^ self ].
	self
		uFFIsqlDisconnect: handle;
		uFFIfreeHandle: handle.
	handle beNull.connected := false.
	env disconnected: self
]

{ #category : #accessing }
OdbcConn >> driverConnect: connString [
({SQL_SUCCESS. SQL_SUCCESS_WITH_INFO} includes:	(self uFFIdriverConnect: connString hdbc: handle) )
		ifFalse: [ OdbcError signalFor: self ].connected:=true.
]

{ #category : #sample }
OdbcConn >> driverConnectScott [
	^ self driverConnect: 'DSN=mysql-test' 
]

{ #category : #accessing }
OdbcConn >> env:anEnv [
	env:=anEnv 
]

{ #category : #accessing }
OdbcConn >> ffiLibrary [
	^ OdbcLibrary
]

{ #category : #accessing }
OdbcConn >> freeHandle [
self deprecated:'just disconnect'.
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
		textLengthPtr: textLengthPtr.	rc = SQL_INVALID_HANDLE
		ifTrue: [ ^ #('***' 'Invalid handle') ].
	^ {(sqlState first: 5) asString.
	(messageText first: (textLengthPtr signedShortAt: 1)) asString}
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
	connected := false.
	handle := ExternalAddress new.
	statements := OrderedCollection new
]

{ #category : #testing }
OdbcConn >> isConnected [
	^ connected
]

{ #category : #printing }
OdbcConn >> printOn: aStream [
	aStream << self class name << ' ('.
	handle isNull
		ifTrue: [ aStream << 'null' ].
	connected
		ifTrue: [ aStream << statements size asString << ' statements' ]
		ifFalse: [ aStream << 'disconnected' ].
	aStream << ')'
]

{ #category : #accessing }
OdbcConn >> stmtClosed: aStmt [

	statements remove: aStmt
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
