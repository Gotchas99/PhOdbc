Class {
	#name : #OdbcStmt,
	#superclass : #Object,
	#instVars : [
		'sql',
		'columnCount',
		'descs',
		'errorBlock',
		'rowBlock',
		'doneBlock',
		'handle',
		'maxStringGetLen'
	],
	#pools : [
		'OdbcConstants'
	],
	#category : #'CAs-ODBC'
}

{ #category : #execution }
OdbcStmt >> close [ 
	self uFFIfreeStmt:handle. self uFFIfreeHandle: handle
]

{ #category : #private }
OdbcStmt >> describeCol: colNr [
	| strLenPtr columnName dataTypePtr columnSizePtr decimalDigitsPtr nullablePtr desc |
	columnName := ByteArray new: 512.
	strLenPtr := FFIInt16 newBuffer.
	dataTypePtr := FFIInt16 newBuffer.
	columnSizePtr := FFIULong newBuffer.
	decimalDigitsPtr := FFIInt16 newBuffer.
	nullablePtr := FFIInt16 newBuffer.
	(self
		uFFIdescribeCol: colNr
		buf: columnName
		bufLen: columnName size
		strLenPtr: strLenPtr
		dataTypePtr: dataTypePtr
		columnSizePtr: columnSizePtr
		decimalDigitsPtr: decimalDigitsPtr
		nullablePtr: nullablePtr) = SQL_SUCCESS
		ifFalse: [ OdbcError signal ].
	desc := Dictionary new.
	desc
		at: 'ColumnName' put: columnName asNullTerminatedString;
		at: 'DataType' put: (dataTypePtr shortAt: 1 bigEndian: false);
		at: 'Nullable' put: (nullablePtr shortAt: 1 bigEndian: false) = 1;
		at: 'ColumnSize' put: (columnSizePtr longAt: 1 bigEndian: false);
		at: 'DecimalDigits'
			put: (decimalDigitsPtr shortAt: 1 bigEndian: false).
	^ desc
]

{ #category : #execution }
OdbcStmt >> execDirect: anSql [
	"len := sql size.
	tmp := ByteArray new: len + 1.
	tmp	replaceFrom: 1
		to: len
		with: sql
		startingAt: 1.
	tmp at: len + 1 put: 0."

	(self uFFIexecDirect: anSql len:anSql size) = SQL_SUCCESS
		ifFalse: [ OdbcError signalFor: self ].
	descs := self getDescriptions
]

{ #category : #execution }
OdbcStmt >> execute [
	| tabs |
	[ [ self execDirect: sql.
	tabs := OrderedCollection new.
	[ self fetch = SQL_SUCCESS ]
		whileTrue: [ | rec |
			rec := self getData.
			rowBlock ifNotNil: [ :b | b value: rec ].
			doneBlock ifNotNil: [ tabs add: rec ] ].
	doneBlock ifNotNil: [ :b | b value: tabs ] ]
		on: Error
		do: [ :ex | errorBlock ifNotNil: [ :b | b value: ex ] ] ]
		ensure: [ self close ]
]

{ #category : #private }
OdbcStmt >> fetch [
	^ self uFFIfetch:handle
]

{ #category : #resources }
OdbcStmt >> ffiLibrary [
	^ OdbcLibrary
]

{ #category : #private }
OdbcStmt >> freeHandle [

	^ self uFFIfreeHandle: handle
]

{ #category : #accessing }
OdbcStmt >> getData [
	| rec typeCode val colName colSize |
	rec := Dictionary new.
	1 to: self numResultColumns do: [ :ix | 
		typeCode := (descs at: ix) at: 'DataType'.
		colName := (descs at: ix) at: 'ColumnName'.
		colSize := (descs at: ix) at: 'ColumnSize'.
		val := nil.
		({SQL_CHAR.
		SQL_VARCHAR.
		SQL_SS_XML} includes: typeCode)
			ifTrue: [ val := self getString: ix size: colSize ].
		({SQL_INTEGER.
		SQL_SMALLINT} includes: typeCode)
			ifTrue: [ val := self getInt: ix ].
		({SQL_FLOAT.
		SQL_REAL.
		SQL_DOUBLE} includes: typeCode)
			ifTrue: [ val := self getFloat: ix ].
		({SQL_TYPE_DATE} includes: typeCode)
			ifTrue: [ val := self getDate: ix ].
		({SQL_DATETIME.
		SQL_TYPE_TIMESTAMP} includes: typeCode)
			ifTrue: [ val := self getDateTime: ix ].	({SQL_TYPE_TIME.
		} includes: typeCode)
			ifTrue: [ val := self getTime: ix ].
		val ifNil: [ self halt ].
		rec at: colName put: val ].
	^ rec
]

{ #category : #accessing }
OdbcStmt >> getDataNr: i type: aType [
	| buf strLen_or_IndPtr rc |

	buf := ByteArray new: 512.
	strLen_or_IndPtr := FFIInt16 newBuffer.
	rc := self
		      uFFIgetDataNr: i
		      type: aType
		      buf: buf
		      bufLen: buf size
		      strLen_or_IndPtr: strLen_or_IndPtr.
	rc = 0 ifFalse: [ self halt ].
	^ buf asNullTerminatedString
]

{ #category : #accessing }
OdbcStmt >> getDate: i [
	| bufLen buf strLen_or_IndPtr y m d |
	bufLen := 512.
	buf := ByteArray new: bufLen.
	strLen_or_IndPtr := ByteArray new: FFIInt16 externalTypeSize.
	(self
		uFFIgetDataNr: i
		type: SQL_C_TYPE_DATE
		buf: buf
		bufLen: bufLen
		strLen_or_IndPtr: strLen_or_IndPtr) = SQL_SUCCESS
		ifFalse: [ OdbcError signal ].
	y := buf unsignedShortAt: 1 bigEndian: false.
	m := buf unsignedShortAt: 3 bigEndian: false.
	d := buf unsignedShortAt: 5 bigEndian: false.
	^ Date year: y month: m day: d
]

{ #category : #accessing }
OdbcStmt >> getDateTime: i [
	| bufLen buf strLen_or_IndPtr y m d h min s |
	bufLen := 512.
	buf := ByteArray new: bufLen.
	strLen_or_IndPtr := ByteArray new: FFIInt16 externalTypeSize.
	(self
		uFFIgetDataNr: i
		type: SQL_C_TYPE_TIMESTAMP
		buf: buf
		bufLen: bufLen
		strLen_or_IndPtr: strLen_or_IndPtr) = SQL_SUCCESS
		ifFalse: [ OdbcError signal ].
	y := buf unsignedShortAt: 1 bigEndian: false.
	m := buf unsignedShortAt: 3 bigEndian: false.
	d := buf unsignedShortAt: 5 bigEndian: false.
	h := buf unsignedShortAt: 7 bigEndian: false.
	min := buf unsignedShortAt: 9 bigEndian: false.
	s := buf unsignedShortAt: 11 bigEndian: false.
	^ DateAndTime
		year: y
		month: m
		day: d
		hour: h
		minute: min
		second: s
]

{ #category : #accessing }
OdbcStmt >> getDescriptions [
	| noOfCols descriptions |
	noOfCols := self numResultColumns.
	descriptions := OrderedCollection new.
	1 to: noOfCols do: [ :ix | descriptions add: (self describeCol: ix) ].
	^ descriptions
]

{ #category : #accessing }
OdbcStmt >> getDiagRec [
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
		      uFFIgetDiagRecType: SQL_HANDLE_STMT
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
OdbcStmt >> getFloat: i [
	| bufLen buf strLen_or_IndPtr |
	bufLen := 512.
	buf := ByteArray new: bufLen.
	strLen_or_IndPtr := ByteArray new: FFIInt16 externalTypeSize.
	(self
		uFFIgetDataNr: i
		type: SQL_C_DOUBLE
		buf: buf
		bufLen: bufLen
		strLen_or_IndPtr: strLen_or_IndPtr) = SQL_SUCCESS
		ifFalse: [ OdbcError signal ].
	^ buf doubleAt: 1 bigEndian: false
]

{ #category : #accessing }
OdbcStmt >> getInt: i [
	| buf strLen_or_IndPtr |
	buf := FFIInt64 newBuffer.
	strLen_or_IndPtr := FFIInt16 newBuffer.
	(self
		uFFIgetDataNr: i
		type: SQL_C_LONG
		buf: buf
		bufLen: buf size
		strLen_or_IndPtr: strLen_or_IndPtr) = SQL_SUCCESS
		ifFalse: [ OdbcError signal ].
	^ buf longAt: 1 bigEndian: false
]

{ #category : #accessing }
OdbcStmt >> getLongString: i size: anInt [
	| buf strLen_or_IndPtr rc dataLen res lenInd |
	buf := ByteArray new: maxStringGetLen + 1.
	strLen_or_IndPtr := FFIInt64 newBuffer.
	res := ByteArray
		streamContents: [ :s | 
			[ rc := self
				uFFIgetDataNr: i
				type: SQL_C_CHAR
				buf: buf
				bufLen: buf size
				strLen_or_IndPtr: strLen_or_IndPtr.
			rc = SQL_ERROR
				ifTrue: [ OdbcError signal ].
			lenInd := strLen_or_IndPtr unsignedLongAt: 1 bigEndian: false.
			dataLen := (lenInd > maxStringGetLen or: [ lenInd = SQL_NO_TOTAL ])
				ifTrue: [ maxStringGetLen ]
				ifFalse: [ lenInd ].
			s next: dataLen putAll: buf ]
				doWhileFalse: [ rc = SQL_NO_DATA or: [ rc = SQL_SUCCESS ] ] ].
	^ res asString
]

{ #category : #accessing }
OdbcStmt >> getString: i [
	| buf strLen_or_IndPtr |
	self deprecated: 'include size:'.
	buf := ByteArray new: 512.
	strLen_or_IndPtr := FFIInt16 newBuffer.
	(self
		uFFIgetDataNr: i
		type: SQL_C_CHAR
		buf: buf
		bufLen: buf size
		strLen_or_IndPtr: strLen_or_IndPtr) = SQL_SUCCESS
		ifFalse: [ Error signal ]. 
	^ buf asNullTerminatedString
]

{ #category : #accessing }
OdbcStmt >> getString: i size: anInt [
	| buf strLen_or_IndPtr rc dataLen |
	(anInt = 0 or: [ anInt > maxStringGetLen ])
		ifTrue: [ ^ self getLongString: i size: anInt ].
	buf := ByteArray new: anInt + 1.
	strLen_or_IndPtr := FFIInt16 newBuffer.
	rc := self
		uFFIgetDataNr: i
		type: SQL_C_CHAR
		buf: buf
		bufLen: buf size
		strLen_or_IndPtr: strLen_or_IndPtr.
	rc = SQL_ERROR
		ifTrue: [ OdbcError signal ].
	dataLen := strLen_or_IndPtr unsignedShortAt: 1 bigEndian: false.
	^ (buf first: dataLen) asString
]

{ #category : #accessing }
OdbcStmt >> getTime: i [
	| bufLen buf strLen_or_IndPtr y m d |
	self halt.
	bufLen := 512.
	buf := ByteArray new: bufLen.
	strLen_or_IndPtr := ByteArray new: FFIInt16 externalTypeSize.
	(self
		uFFIgetDataNr: i
		type: SQL_C_TYPE_DATE
		buf: buf
		bufLen: bufLen
		strLen_or_IndPtr: strLen_or_IndPtr) = SQL_SUCCESS
		ifFalse: [ OdbcError signal ].
	y := buf unsignedShortAt: 1 bigEndian: false.
	m := buf unsignedShortAt: 3 bigEndian: false.
	d := buf unsignedShortAt: 5 bigEndian: false.
	^ Date year: y month: m day: d
]

{ #category : #accessing }
OdbcStmt >> handle [
	^handle
]

{ #category : #'initialize - release' }
OdbcStmt >> handleType [
	^ SQL_HANDLE_STMT 
]

{ #category : #'initialize - release' }
OdbcStmt >> initialize [
	columnCount := ByteArray new: FFIInt16 externalTypeSize.
	maxStringGetLen
	:= 5000
]

{ #category : #accessing }
OdbcStmt >> numResultColumns [
	| tmp |
	^ columnCount
		ifNotNil: [ tmp := FFIInt16 newBuffer.
			(self uFFInumResultColumns: tmp) = SQL_SUCCESS
				ifFalse: [ OdbcError signal ].
			columnCount := tmp shortAt: 1 bigEndian: false ]
]

{ #category : #execution }
OdbcStmt >> onDone: aBlock [
	doneBlock := aBlock
]

{ #category : #execution }
OdbcStmt >> onError: aBlock [
	errorBlock := aBlock
]

{ #category : #execution }
OdbcStmt >> onRow:aBlock [ 
rowBlock :=aBlock 
]

{ #category : #accessing }
OdbcStmt >> sql:aSqlString [
sql:=aSqlString 
]

{ #category : #accessing }
OdbcStmt >> stmt: aStmt [
	handle := aStmt
]

{ #category : #accessing }
OdbcStmt >> tables [
	"https://docs.microsoft.com/en-us/sql/odbc/reference/syntax/sqltables-function?view=sql-server-ver15"

	(self uFFItables: handle) = SQL_SUCCESS
		ifFalse: [ OdbcError signal ].
	descs := self getDescriptions
]

{ #category : #uFFI }
OdbcStmt >> uFFIcloseCursor [
	"SQLRETURN SQLCloseCursor(  SQLHSTMT     StatementHandle);"

	^ self ffiCall: #(SQLRETURN SQLCloseCursor #(SQLHSTMT handle))
]

{ #category : #uFFI }
OdbcStmt >> uFFIdescribeCol: colNr buf: columnName bufLen: bufLen strLenPtr: strLenPtr dataTypePtr: dataTypePtr columnSizePtr: columnSizePtr decimalDigitsPtr: decimalDigitsPtr nullablePtr: nullablePtr [
	"SQLRETURN SQLDescribeCol(        SQLHSTMT       StatementHandle,  
      SQLUSMALLINT   ColumnNumber,        SQLCHAR *      ColumnName,  
      SQLSMALLINT    BufferLength,        SQLSMALLINT *  NameLengthPtr,  
      SQLSMALLINT *  DataTypePtr,        SQLULEN *      ColumnSizePtr,  
      SQLSMALLINT *  DecimalDigitsPtr,        SQLSMALLINT *  NullablePtr);  "

	^ self
		ffiCall:
			#(short SQLDescribeCol #(SQLHSTMT handle , SQLUSMALLINT colNr , SQLCHAR * columnName , SQLSMALLINT bufLen , SQLSMALLINT * strLenPtr , SQLSMALLINT * dataTypePtr , SQLULEN * columnSizePtr , SQLSMALLINT * decimalDigitsPtr , SQLSMALLINT * nullablePtr))
]

{ #category : #uFFI }
OdbcStmt >> uFFIexecDirect: anSql [
	"SQLRETURN SQLExecDirect(  
     SQLHSTMT     StatementHandle,  
     SQLCHAR *    StatementText,  
     SQLINTEGER   TextLength);  "

	"SQL_NTS = -3"

	^ self
		ffiCall: #(SQLRETURN SQLExecDirect #(SQLHSTMT handle , SQLCHAR * anSql , -3))
]

{ #category : #uFFI }
OdbcStmt >> uFFIexecDirect: anSql len: anInt [
	"SQLRETURN SQLExecDirect(  
     SQLHSTMT     StatementHandle,  
     SQLCHAR *    StatementText,  
     SQLINTEGER   TextLength);  "

	"SQL_NTS = -3"

	^ self
		ffiCall:
			#(SQLRETURN SQLExecDirect #(SQLHSTMT handle , SQLCHAR * anSql ,SQLINTEGER anInt))
]

{ #category : #uFFI }
OdbcStmt >> uFFIfetch:aHstmt [
	"SQLRETURN  SQL_API SQLFetch(SQLHSTMT StatementHandle);"

	^ self ffiCall: #( SQLRETURN SQLFetch #( SQLHSTMT aHstmt ) )
]

{ #category : #uFFI }
OdbcStmt >> uFFIfreeHandle:aHstmt [
	"SQLRETURN  SQL_API SQLFreeHandle(SQLSMALLINT HandleType, SQLHANDLE Handle);"
	"SQL_HANDLE_STMT = 3"

	^ self ffiCall:
		  #( SQLRETURN SQLFreeHandle #( SQLSMALLINT 3 , SQLHANDLE
		        aHstmt ) )
]

{ #category : #uFFI }
OdbcStmt >> uFFIfreeStmt: aHstmt [
	"SQLRETURN SQLFreeStmt(  
     SQLHSTMT       StatementHandle,  
     SQLUSMALLINT   Option); "

	"SQL_CLOSE = 0"

	^ self
		ffiCall: #(SQLRETURN SQLFreeHandle #( SQLHANDLE aHstmt,SQLSMALLINT 0))
]

{ #category : #uFFI }
OdbcStmt >> uFFIgetData: aHstmt colNr: i type: aType buf: buf bufLen: bufLen strLen_or_IndPtr: strLen_or_IndPtr [
	"SQLRETURN  SQL_API SQLGetData(SQLHSTMT StatementHandle,
           SQLUSMALLINT ColumnNumber, SQLSMALLINT TargetType,
           _Out_writes_opt_(_Inexpressible_(BufferLength)) SQLPOINTER TargetValue, 
				SQLLEN BufferLength,   _Out_opt_ SQLLEN *StrLen_or_IndPtr);"
self halt.
	^ self
		ffiCall:
			#(SQLRETURN SQLGetData #(SQLHSTMT aHstmt , SQLUSMALLINT i , SQLSMALLINT aType , SQLPOINTER buf , SQLLEN bufLen , SQLLEN * strLen_or_IndPtr))
]

{ #category : #uFFI }
OdbcStmt >> uFFIgetDataNr: i type: aType buf: buf bufLen: bufLen strLen_or_IndPtr: strLen_or_IndPtr [
	"SQLRETURN  SQL_API SQLGetData(SQLHSTMT StatementHandle,
           SQLUSMALLINT ColumnNumber, SQLSMALLINT TargetType,
           _Out_writes_opt_(_Inexpressible_(BufferLength)) SQLPOINTER TargetValue, 
				SQLLEN BufferLength,   _Out_opt_ SQLLEN *StrLen_or_IndPtr);"

	^ self
		ffiCall:
			#(SQLRETURN SQLGetData #(SQLHSTMT handle , SQLUSMALLINT i , SQLSMALLINT aType , SQLPOINTER buf , SQLLEN bufLen , SQLLEN * strLen_or_IndPtr))
]

{ #category : #uFFI }
OdbcStmt >> uFFInumResultColumns: colCnt [
	"SQLRETURN  SQL_API SQLNumResultCols(SQLHSTMT StatementHandle,
           _Out_ SQLSMALLINT *ColumnCount);"

	^ self
		ffiCall: #(SQLRETURN SQLNumResultCols #(SQLHSTMT handle , SQLSMALLINT * colCnt))
]

{ #category : #uFFI }
OdbcStmt >> uFFItables:aHstmt [
	"SQLTables(stmt_handle,
            NULL, 0, /* no specific catalog */
            NULL, 0, /* no specific schema */
            NULL, 0, /* no specific table */
            NULL, 0) /* no specific type - table or view */"

	^ self ffiCall:
		  #( SQLRETURN SQLTables #( SQLHSTMT aHstmt , 0 , 0 , 0 , 0 , 0 , 0 ,
		        0 , 0 ) )
]
