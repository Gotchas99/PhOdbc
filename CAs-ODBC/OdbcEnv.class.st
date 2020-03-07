Class {
	#name : #OdbcEnv,
	#superclass : #Object,
	#instVars : [
		'connections',
		'handle'
	],
	#classVars : [
		'Default'
	],
	#pools : [
		'OdbcConstants'
	],
	#classInstVars : [
		'connections'
	],
	#category : #'CAs-ODBC'
}

{ #category : #accessing }
OdbcEnv class >> default [
	^ Default ifNil: [ Default := self new ] 
]

{ #category : #'class initialization' }
OdbcEnv class >> initialize [


	Smalltalk addToStartUpList: self
]

{ #category : #accessing }
OdbcEnv class >> reset [
	 Default:=nil
]

{ #category : #'class initialization' }
OdbcEnv class >> shutDown: quitting [
	quitting
		ifFalse: [ ^ self ].
	self default deallocEnvironment. self reset
]

{ #category : #'class initialization' }
OdbcEnv class >> startUp: isImageStarting [
	isImageStarting ifFalse: [ ^ self ].
	self default allocEnvironment 
]

{ #category : #api }
OdbcEnv >> allocConnection [
	| hdbc con |
	hdbc := ExternalAddress new.
	((self
		uFFIallocHandle: hdbc
		handleType: SQL_HANDLE_DBC
		inputHandle: handle) = SQL_SUCCESS)
		ifFalse: [ Error signal ].
	con := OdbcConn new hdbc: hdbc.
	connections add: con.
	^ con
]

{ #category : #'initialize - release' }
OdbcEnv >> allocEnvironment [
	"SQLRETURN SQLAllocHandle(SQL_HANDLE_ENV, SQL_NULL_HANDLE, &env);"

	handle ifNotNil: [ self deallocEnvironment ].
	handle := ExternalAddress new.
	(self
		uFFIallocHandle: handle
		handleType: SQL_HANDLE_ENV
		inputHandle: ExternalAddress null) = SQL_SUCCESS
		ifFalse: [ OdbcError signal ].
	self setEnvAttr.
	
]

{ #category : #'initialize - release' }
OdbcEnv >> deallocEnvironment [
	"SQLRETURN  SQL_API SQLFreeHandle(SQLSMALLINT HandleType, SQLHANDLE Handle);"

	 connections
				do: [ :c | 
					c
						disconnect;
						freeHandle ] .
	connections removeAll.
	handle isNull
		ifFalse: [ self uFFIfreeHandle: handle handleType: SQL_HANDLE_ENV.
			handle := ExternalAddress new ]
]

{ #category : #'library path' }
OdbcEnv >> ffiLibrary [
^OdbcLibrary 
]

{ #category : #api }
OdbcEnv >> getDiagRec [
	"SQLRETURN SQLGetDiagRec(  
     SQLSMALLINT     HandleType,       SQLHANDLE       Handle,  
     SQLSMALLINT     RecNumber,       SQLCHAR *       SQLState,  
     SQLINTEGER *    NativeErrorPtr,       SQLCHAR *       MessageText,  
     SQLSMALLINT     BufferLength,       SQLSMALLINT *   TextLengthPtr);  "

	| recNumber sqlState nativeErrorPtr messageText bufferLength textLengthPtr rc |
	recNumber := 1.
	sqlState := ByteArray new: 10.
	nativeErrorPtr := ByteArray new: FFIInt32 externalTypeSize.
	bufferLength := 2048.
	"	messageText := ExternalAddress allocate: bufferLength."
	messageText := ByteArray new: bufferLength.
	textLengthPtr := ByteArray new: FFIInt32 externalTypeSize.
	rc := OdbcLibrary uniqueInstance
		uFFIgetDiagRecType: SQL_HANDLE_ENV
		handle: handle
		recNumber: recNumber
		sqlState: sqlState
		nativeErrorPtr: nativeErrorPtr
		messageText: messageText
		bufferLength: bufferLength
		textLengthPtr: textLengthPtr.
	^ {(sqlState first: 5) asString.
	(messageText first: (textLengthPtr signedShortAt: 1)) asString}
]

{ #category : #api }
OdbcEnv >> getEnvAttr [
	"SQLRETURN SQLGetEnvAttr(  
     SQLHENV        EnvironmentHandle,       SQLINTEGER     Attribute,  
     SQLPOINTER     ValuePtr,       SQLINTEGER     BufferLength,  
     SQLINTEGER *   StringLengthPtr);  "

	| tmp bufferLength attribute valuePtr stringLengthPointer |
	self flag: 'fix return values'.
	attribute := SQL_ATTR_ODBC_VERSION.
	bufferLength := 2048.  
	valuePtr := ByteArray new: bufferLength + 1.
	stringLengthPointer := ByteArray new: FFIInt32 externalTypeSize.
	tmp := self
		uFFIgetEnvAttr: attribute
		valuePtr: valuePtr
		bufferLength: bufferLength
		stringLengthPtr: stringLengthPointer.
	^ tmp
]

{ #category : #accessing }
OdbcEnv >> handle [
	^handle
]

{ #category : #'initialize - release' }
OdbcEnv >> handleType [
^ SQL_HANDLE_ENV
]

{ #category : #'initialize - release' }
OdbcEnv >> initialize [
	super initialize.handle := ExternalAddress new.

	connections := OrderedCollection new
]

{ #category : #api }
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
		      uFFIlistDriversHenv: handle driver:  driver
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

{ #category : #api }
OdbcEnv >> setEnvAttr [
	"SQLRETURN SQLSetEnvAttr(       SQLHENV      EnvironmentHandle,  
     SQLINTEGER   Attribute,       SQLPOINTER   ValuePtr,  
     SQLINTEGER   StringLength); "

	| attribute valuePtr stringLength |
	attribute := SQL_ATTR_ODBC_VERSION.
	valuePtr := ExternalAddress new.
	valuePtr fromInteger: SQL_OV_ODBC3.
	stringLength := -1.
	(self
		uFFIsetEnv: handle
		attr: attribute
		valuePtr: valuePtr
		stringLength: stringLength) = SQL_SUCCESS
		ifFalse: [ OdbcError signal ]
]

{ #category : #'ffi calls' }
OdbcEnv >> uFFIallocHandle: aHandle handleType: handleType inputHandle: inputHandle [
	"SQLRETURN SQLAllocHandle(SQL_HANDLE_ENV, SQL_NULL_HANDLE, &env);"

	^ self ffiCall:
		  #( SQLRETURN SQLAllocHandle #( SQLSMALLINT handleType , SQLHANDLE
		        inputHandle , SQLHANDLE * aHandle ) )
]

{ #category : #'ffi calls' }
OdbcEnv >> uFFIfreeHandle: handle handleType: aHandleType [
	"SQLRETURN  SQL_API SQLFreeHandle(SQLSMALLINT HandleType, SQLHANDLE Handle);"

	^ self ffiCall:
		  #( SQLRETURN SQLFreeHandle #( SQLSMALLINT aHandleType , SQLHANDLE handle ) )
]

{ #category : #'ffi calls' }
OdbcEnv >> uFFIgetEnvAttr: attribute valuePtr: valuePtr bufferLength: bufferLength stringLengthPtr: stringLengthPtr [
	"SQLRETURN SQLGetEnvAttr(  
     SQLHENV        EnvironmentHandle,       SQLINTEGER     Attribute,  
     SQLPOINTER     ValuePtr,       SQLINTEGER     BufferLength,  
     SQLINTEGER *   StringLengthPtr);  "

	^ self
		ffiCall:
			#(SQLRETURN SQLGetEnvAttr #(SQLHENV henv , SQLINTEGER attribute , SQLPOINTER valuePtr , SQLINTEGER bufferLength , SQLINTEGER * stringLengthPtr))
]

{ #category : #'ffi calls' }
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

{ #category : #'ffi calls' }
OdbcEnv >> uFFIsetEnv: hEnv attr: attribute valuePtr: valuePtr stringLength: stringLength [
	"SQLRETURN SQLSetEnvAttr(       SQLHENV      EnvironmentHandle,  
     SQLINTEGER   Attribute,       SQLPOINTER   ValuePtr,  
     SQLINTEGER   StringLength); "

	"valuePtr is longlong to allow sending integer values, such as odbc version"

	^ self ffiCall:
		  #( SQLRETURN SQLSetEnvAttr #( SQLHENV hEnv , SQLINTEGER attribute
		        , SQLPOINTER valuePtr , SQLINTEGER stringLength ) )
]
