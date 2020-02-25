Class {
	#name : #OdbcEnv,
	#superclass : #Object,
	#instVars : [
		'henv'
	],
	#classVars : [
		'Default'
	],
	#pools : [
		'OdbcConstants'
	],
	#category : #'CAs-ODBC'
}

{ #category : #accessing }
OdbcEnv class >> default [
	^ Default ifNil:[Default:= self new].
]

{ #category : #'class initialization' }
OdbcEnv class >> initialize [
	"Required to reset the Initialized flag on image startup.
	Force libgit initialization since we just installed libgit.
	Otherwise this would cause a libgit crash"
	
	Smalltalk addToStartUpList: self.
]

{ #category : #accessing }
OdbcEnv class >> reset [
	 Default:=nil
]

{ #category : #'class initialization' }
OdbcEnv class >> shutDown: quitting [
	quitting
		ifFalse: [ ^ self ].
	self default deallocEnvironment
]

{ #category : #'class initialization' }
OdbcEnv class >> startUp: isImageStarting [
	isImageStarting ifFalse: [ ^ self ].
	self default allocEnvironment 
]

{ #category : #'class initialization' }
OdbcEnv >> allocConnection [
	| hdbc |
	hdbc := ExternalAddress new.
	self
		uFFIallocHandle: hdbc
		handleType: SQL_HANDLE_DBC
		inputHandle: henv.
	"self uFFIallocConnection: hdbc."
	^ OdbcConn new hdbc: hdbc
]

{ #category : #'class initialization' }
OdbcEnv >> allocEnvironment [
	"SQLRETURN SQLAllocHandle(SQL_HANDLE_ENV, SQL_NULL_HANDLE, &env);"

	henv ifNotNil: [ self deallocEnvironment ].
	henv := ExternalAddress new.
	^ self 
		uFFIallocHandle: henv
		handleType: SQL_HANDLE_ENV
		inputHandle: ExternalAddress null
]

{ #category : #'class initialization' }
OdbcEnv >> deallocEnvironment [
	"SQLRETURN  SQL_API SQLFreeHandle(SQLSMALLINT HandleType, SQLHANDLE Handle);"

| ret |
ret:= self uFFIfreeHandle: henv handleType: SQL_HANDLE_ENV.
henv:=nil.^ret
]

{ #category : #'library path' }
OdbcEnv >> ffiLibrary [
^OdbcLibrary 
]

{ #category : #'class initialization' }
OdbcEnv >> getDiagRec [
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
	"	messageText := ExternalAddress allocate: bufferLength."
	messageText := ByteArray new: bufferLength.
	textLengthPtr := ByteArray new: FFIInt32 externalTypeSize.
	rc := OdbcLibrary uniqueInstance 
		      uFFIgetDiagRecType: SQL_HANDLE_ENV
		      handle: henv
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

{ #category : #'class initialization' }
OdbcEnv >> getEnvAttr [
	"SQLRETURN SQLGetEnvAttr(  
     SQLHENV        EnvironmentHandle,       SQLINTEGER     Attribute,  
     SQLPOINTER     ValuePtr,       SQLINTEGER     BufferLength,  
     SQLINTEGER *   StringLengthPtr);  "

	| tmp bufferLength attribute valuePtr stringLengthPointer |
	attribute := SQL_ATTR_ODBC_VERSION                   .
	bufferLength := 2048.
	valuePtr := ByteArray new: bufferLength.
	stringLengthPointer := ByteArray new: FFIInt32 externalTypeSize.
	tmp := self
		uFFIgetEnvAttr: attribute
		valuePtr: valuePtr
		bufferLength: bufferLength
		stringLengthPtr: stringLengthPointer.
	^ tmp
]

{ #category : #'class initialization' }
OdbcEnv >> listDrivers [
	"SQLRETURN SQLDrivers(  
     SQLHENV         EnvironmentHandle,       SQLUSMALLINT    Direction,  
     SQLCHAR *       DriverDescription,       SQLSMALLINT     BufferLength1,  
     SQLSMALLINT *   DescriptionLengthPtr,       SQLCHAR *       DriverAttributes,  
     SQLSMALLINT     BufferLength2,       SQLSMALLINT *   AttributesLengthPtr);  "

	| driver driver_size driver_ret attr attr_size attr_ret dir rc driverList |
	driverList := OrderedCollection new.
	dir := SQL_FETCH_FIRST.
	driver_size := 256.
	driver := ByteArray new: driver_size.
	driver_ret := ByteArray new: FFIInt16 externalTypeSize.
	attr_size := 256.
	attr := ByteArray new: attr_size.
	attr_ret := ByteArray new: FFIInt16 externalTypeSize.
	[ 
	rc := self
		      uFFIlistDriversHenv: henv driver:  driver
		      direction: dir
		      driver_size: driver_size
		      driver_ret: driver_ret
		      attr: attr
		      attr_size: attr_size
		      attr_ret: attr_ret.
	rc = SQL_SUCCESS ifTrue: [ 
		driverList add: driver asNullTerminatedString ].
	dir := SQL_FETCH_NEXT ] doWhileTrue: [ rc = SQL_SUCCESS ].
	^ driverList
]

{ #category : #'class initialization' }
OdbcEnv >> setEnvAttr [
	"SQLRETURN SQLSetEnvAttr(       SQLHENV      EnvironmentHandle,  
     SQLINTEGER   Attribute,       SQLPOINTER   ValuePtr,  
     SQLINTEGER   StringLength); "

	| tmp attribute valuePtr stringLength holder intBuffer |
	attribute := SQL_ATTR_ODBC_VERSION.
	valuePtr := ExternalAddress new.
	valuePtr fromInteger: SQL_OV_ODBC3.
	
	"valuePtr := ByteArray new: FFIInt32 externalTypeSize.
	valuePtr unsignedLongAt: 1 put: SQL_OV_ODBC3.
	holder := (FFIExternalValueHolder ofType: 'int') new.
	holder value: SQL_OV_ODBC3.
	intBuffer := FFIInt32 newBuffer.
	intBuffer unsignedLongAt: 1 put: SQL_OV_ODBC3."
	stringLength := -1.
	"valuePtr := 'asdfasdf'."
	"stringLength := valuePtr size."
	tmp := self
		       uFFIsetEnv: henv
		       attr: attribute
		       valuePtr: valuePtr
		       stringLength: stringLength.
	^ tmp
]

{ #category : #'class initialization' }
OdbcEnv >> uFFIallocConnection: hdbc [
	^ self ffiCall:
		  #( short SQLAllocHandle #( SQL_HANDLE_DBC , SQLHENV henv , SQLHANDLE 
		        * hdbc ) )
]

{ #category : #'class initialization' }
OdbcEnv >> uFFIallocEnvironment: aHenv [
	"SQLRETURN SQLAllocHandle(SQL_HANDLE_ENV, SQL_NULL_HANDLE, &env);"

	^ self ffiCall: 
		  #( short SQLAllocHandle #(  1 ,  0 , SQLHANDLE * aHenv ) )
	" #( short SQLAllocHandle #( SQL_HANDLE_ENV , SQL_NULL_HANDLE 
		        , SQLHANDLE * aHenv ) )"
]

{ #category : #'class initialization' }
OdbcEnv >> uFFIallocHandle: handle handleType: handleType inputHandle: inputHandle [
	"SQLRETURN SQLAllocHandle(SQL_HANDLE_ENV, SQL_NULL_HANDLE, &env);"

	^ self ffiCall:
		  #( SQLRETURN SQLAllocHandle #( SQLSMALLINT handleType , SQLHANDLE
		        inputHandle , SQLHANDLE * handle ) )
]

{ #category : #'class initialization' }
OdbcEnv >> uFFIfreeHandle: handle handleType: aHandleType [
	"SQLRETURN  SQL_API SQLFreeHandle(SQLSMALLINT HandleType, SQLHANDLE Handle);"

	^ self ffiCall:
		  #( SQLRETURN SQLFreeHandle #( SQLSMALLINT aHandleType , SQLHANDLE handle ) )
]

{ #category : #'class initialization' }
OdbcEnv >> uFFIgetEnvAttr: attribute valuePtr: valuePtr bufferLength: bufferLength stringLengthPtr: stringLengthPtr [
	"SQLRETURN SQLGetEnvAttr(  
     SQLHENV        EnvironmentHandle,       SQLINTEGER     Attribute,  
     SQLPOINTER     ValuePtr,       SQLINTEGER     BufferLength,  
     SQLINTEGER *   StringLengthPtr);  "

	^ self
		ffiCall:
			#(SQLRETURN SQLGetEnvAttr #(SQLHENV henv , SQLINTEGER attribute , SQLPOINTER valuePtr , SQLINTEGER bufferLength , SQLINTEGER * stringLengthPtr))
]

{ #category : #'class initialization' }
OdbcEnv >> uFFIlistDriversHenv: hEnv driver: driver direction: dir driver_size: driver_size driver_ret: driver_ret attr: attr attr_size: attr_size attr_ret: attr_ret [
	"SQLRETURN SQLDrivers(  
     SQLHENV         EnvironmentHandle,       SQLUSMALLINT    Direction,  
     SQLCHAR *       DriverDescription,       SQLSMALLINT     BufferLength1,  
     SQLSMALLINT *   DescriptionLengthPtr,       SQLCHAR *       DriverAttributes,  
     SQLSMALLINT     BufferLength2,       SQLSMALLINT *   AttributesLengthPtr);  "

	^ self ffiCall:
		  #( short SQLDrivers #( SQLHENV hEnv , SQLUSMALLINT dir , SQLCHAR
		        * driver , SQLSMALLINT driver_size , SQLSMALLINT * driver_ret
		        , SQLCHAR * attr , SQLSMALLINT attr_size , SQLSMALLINT
		        * attr_ret ) )
]

{ #category : #'class initialization' }
OdbcEnv >> uFFIsetEnv: hEnv attr: attribute valuePtr: valuePtr stringLength: stringLength [
	"SQLRETURN SQLSetEnvAttr(       SQLHENV      EnvironmentHandle,  
     SQLINTEGER   Attribute,       SQLPOINTER   ValuePtr,  
     SQLINTEGER   StringLength); "

	"valuePtr is longlong to allow sending integer values, such as odbc version"

	^ self ffiCall:
		  #( SQLRETURN SQLSetEnvAttr #( SQLHENV hEnv , SQLINTEGER attribute
		        , SQLPOINTER valuePtr , SQLINTEGER stringLength ) )
]
