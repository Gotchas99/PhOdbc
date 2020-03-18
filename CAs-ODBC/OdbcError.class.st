Class {
	#name : #OdbcError,
	#superclass : #Error,
	#pools : [
		'OdbcConstants'
	],
	#category : #'CAs-ODBC'
}

{ #category : #signalling }
OdbcError class >> signalFor: anErrorSite [
	self new setDiagDataFrom:anErrorSite ;signal 
]

{ #category : #signaling }
OdbcError >> getDiagRec: handle type: type [
	"SQLRETURN SQLGetDiagRec(  
     SQLSMALLINT     HandleType,       SQLHANDLE       Handle,  
     SQLSMALLINT     RecNumber,       SQLCHAR *       SQLState,  
     SQLINTEGER *    NativeErrorPtr,       SQLCHAR *       MessageText,  
     SQLSMALLINT     BufferLength,       SQLSMALLINT *   TextLengthPtr);  "

	| recNumber sqlState nativeErrorPtr msgText bufferLength textLengthPtr |
	recNumber := 1.
	sqlState := ByteArray new: 10.
	nativeErrorPtr := ByteArray new: FFIInt32 externalTypeSize.
	bufferLength := 2048.
	msgText := ByteArray new: bufferLength.
	textLengthPtr := ByteArray new: FFIInt32 externalTypeSize.
	OdbcLibrary uniqueInstance
		uFFIgetDiagRecType: type
		handle: handle
		recNumber: recNumber
		sqlState: sqlState
		nativeErrorPtr: nativeErrorPtr
		messageText: msgText
		bufferLength: bufferLength 
		textLengthPtr: textLengthPtr.
	^ {(sqlState first: 5) asString.
	(msgText first: (textLengthPtr signedShortAt: 1)) asString}
]

{ #category : #signaling }
OdbcError >> setDiagDataFrom: anErrorSite [
	| diag |
	diag := self
		getDiagRec: anErrorSite handle
		type: anErrorSite handleType.
	self
		tag: diag first;
		messageText: diag second.
	
]

{ #category : #signaling }
OdbcError >> signal [
	"Ask ContextHandlers in the sender chain to handle this signal.  The default is to execute and return my defaultAction."

	| src |
	src := signaler ifNil: [ self receiver ].
	self setDiagDataFrom: src.
	^ super signal
]
