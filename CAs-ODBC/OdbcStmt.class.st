Class {
	#name : #OdbcStmt,
	#superclass : #Object,
	#instVars : [
		'stmt',
		'columnCount',
		'descs'
	],
	#pools : [
		'OdbcConstants'
	],
	#category : #'CAs-ODBC'
}

{ #category : #accessing }
OdbcStmt >> describeCol: colNr [
	| strLenPtr rc columnName dataTypePtr columnSizePtr decimalDigitsPtr nullablePtr desc |
	columnName := ByteArray new: 512.
	strLenPtr := FFIInt16 newBuffer.
	dataTypePtr := FFIInt16 newBuffer.
	columnSizePtr := FFIULong newBuffer.
	decimalDigitsPtr := FFIInt16 newBuffer.
	nullablePtr := FFIInt16 newBuffer.
	rc := self
		      uFFIdescribeCol: colNr
		      buf: columnName
		      bufLen: columnName size
		      strLenPtr: strLenPtr
		      dataTypePtr: dataTypePtr
		      columnSizePtr: columnSizePtr
		      decimalDigitsPtr: decimalDigitsPtr
		      nullablePtr: nullablePtr.
	rc = 0 ifFalse: [ self halt ].
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

{ #category : #accessing }
OdbcStmt >> execDirect: sql [
	| len tmp rc |
	"len := sql size.
	tmp := ByteArray new: len + 1.
	tmp
		replaceFrom: 1
		to: len
		with: sql
		startingAt: 1.
	tmp at: len + 1 put: 0."
	rc:=  self uFFIexecDirect: sql.rc = SQL_SUCCESS ifFalse: [ self halt ].
	descs := self getDescriptions.^rc
]

{ #category : #accessing }
OdbcStmt >> fetch [
	^ self uFFIfetch:stmt
]

{ #category : #resources }
OdbcStmt >> ffiLibrary [
	^ OdbcLibrary
]

{ #category : #accessing }
OdbcStmt >> freeHandle [

	^ self uFFIfreeHandle: stmt
]

{ #category : #accessing }
OdbcStmt >> getData [
	| rec typeCode val colName |
	rec := Dictionary new.
	1 to: self numResultColumns do: [ :ix | 
		typeCode := (descs at: ix) at: 'DataType'.
		colName := (descs at: ix) at: 'ColumnName'.
		val := nil.
		({ 
			 SQL_CHAR.
			 SQL_VARCHAR } includes: typeCode) ifTrue: [ 
			val := self getString: ix ].
		({ 
			 SQL_INTEGER.
			 SQL_SMALLINT } includes: typeCode) ifTrue: [ 
			val := self getInt: ix ].
		({ 
			 SQL_FLOAT.
			 SQL_REAL.
			 SQL_DOUBLE } includes: typeCode) ifTrue: [ 
			val := self getFloat: ix ].
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
	| bufLen buf strLen_or_IndPtr rc y m d |
	bufLen := 512.
	buf := ByteArray new: bufLen.
	strLen_or_IndPtr := ByteArray new: FFIInt16 externalTypeSize.
	rc := self
		uFFIgetDataNr: i
		type: SQL_C_TYPE_DATE
		buf: buf
		bufLen: bufLen
		strLen_or_IndPtr: strLen_or_IndPtr.
	y := buf unsignedShortAt: 1 bigEndian: false.
	m := buf unsignedShortAt: 3 bigEndian: false.
	d := buf unsignedShortAt: 5 bigEndian: false.
	^ Date year: y month: m day: d
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
		      handle: stmt
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
	| bufLen buf strLen_or_IndPtr rc |
	bufLen := 512.
	buf := ByteArray new: bufLen.
	strLen_or_IndPtr := ByteArray new: FFIInt16 externalTypeSize.
	rc := self
		uFFIgetDataNr: i
		type: SQL_C_DOUBLE
		buf: buf
		bufLen: bufLen
		strLen_or_IndPtr: strLen_or_IndPtr.
	^ buf doubleAt: 1 bigEndian: false
]

{ #category : #accessing }
OdbcStmt >> getInt: i [
	| buf strLen_or_IndPtr rc |
	buf := FFIInt64 newBuffer .
	strLen_or_IndPtr := FFIInt16 newBuffer.
	rc := self
		      uFFIgetDataNr: i
		      type: SQL_C_LONG
		      buf: buf
		      bufLen: buf size
		      strLen_or_IndPtr: strLen_or_IndPtr.
	rc = 0 ifFalse: [ self halt ].
	^ buf longAt: 1 bigEndian: false
]

{ #category : #accessing }
OdbcStmt >> getString: i [
	| buf strLen_or_IndPtr rc |
	buf := ByteArray new: 512.
	strLen_or_IndPtr := FFIInt16 newBuffer.
	rc := self
		      uFFIgetDataNr: i
		      type: SQL_C_CHAR
		      buf: buf
		      bufLen: buf size
		      strLen_or_IndPtr: strLen_or_IndPtr.rc = 0 ifFalse: [ self halt ].
	^ buf asNullTerminatedString
]

{ #category : #accessing }
OdbcStmt >> initialize [
	columnCount := ByteArray new: FFIInt16 externalTypeSize.
]

{ #category : #accessing }
OdbcStmt >> numResultColumns [
	self uFFInumResultColumns:stmt.
	^ columnCount shortAt: 1 bigEndian: false
]

{ #category : #accessing }
OdbcStmt >> stmt: aStmt [
	stmt := aStmt
]

{ #category : #accessing }
OdbcStmt >> tables [
	"https://docs.microsoft.com/en-us/sql/odbc/reference/syntax/sqltables-function?view=sql-server-ver15"

	| rc |
	rc := self uFFItables: stmt.
	rc = SQL_SUCCESS ifFalse: [ self halt ].
	descs := self getDescriptions.	^ rc
]

{ #category : #uFFI }
OdbcStmt >> uFFIcloseCursor [
	"SQLRETURN SQLCloseCursor(  SQLHSTMT     StatementHandle);"

	^ self
		ffiCall: #(SQLRETURN SQLCloseCursor #(SQLHSTMT stmt))
]

{ #category : #uFFI }
OdbcStmt >> uFFIdescribeCol: colNr buf: columnName bufLen: bufLen strLenPtr: strLenPtr dataTypePtr: dataTypePtr columnSizePtr: columnSizePtr decimalDigitsPtr: decimalDigitsPtr nullablePtr: nullablePtr [
	"SQLRETURN SQLDescribeCol(        SQLHSTMT       StatementHandle,  
      SQLUSMALLINT   ColumnNumber,        SQLCHAR *      ColumnName,  
      SQLSMALLINT    BufferLength,        SQLSMALLINT *  NameLengthPtr,  
      SQLSMALLINT *  DataTypePtr,        SQLULEN *      ColumnSizePtr,  
      SQLSMALLINT *  DecimalDigitsPtr,        SQLSMALLINT *  NullablePtr);  "

	^ self ffiCall:
		  #( short SQLDescribeCol #( SQLHSTMT stmt , SQLUSMALLINT
		        colNr , SQLCHAR * columnName , SQLSMALLINT bufLen , SQLSMALLINT
		        * strLenPtr , SQLSMALLINT * dataTypePtr , SQLULEN * columnSizePtr
		        , SQLSMALLINT * decimalDigitsPtr , SQLSMALLINT * nullablePtr ) )
]

{ #category : #uFFI }
OdbcStmt >> uFFIexecDirect: sql [
	"SQLRETURN SQLExecDirect(  
     SQLHSTMT     StatementHandle,  
     SQLCHAR *    StatementText,  
     SQLINTEGER   TextLength);  "
"SQL_NTS = -3"

	^ self ffiCall:
		  #( SQLRETURN SQLExecDirect #(SQLHSTMT stmt , SQLCHAR * sql ,  -3 ) )
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
OdbcStmt >> uFFIgetData:aHstmt colNr: i type: aType buf: buf bufLen: bufLen strLen_or_IndPtr: strLen_or_IndPtr [
	"SQLRETURN  SQL_API SQLGetData(SQLHSTMT StatementHandle,
           SQLUSMALLINT ColumnNumber, SQLSMALLINT TargetType,
           _Out_writes_opt_(_Inexpressible_(BufferLength)) SQLPOINTER TargetValue, 
				SQLLEN BufferLength,   _Out_opt_ SQLLEN *StrLen_or_IndPtr);"

	^ self ffiCall:
		  #( SQLRETURN SQLGetData #( SQLHSTMT aHstmt , SQLUSMALLINT
		        i , SQLSMALLINT aType , SQLPOINTER buf , SQLLEN bufLen
		        , SQLLEN * strLen_or_IndPtr ) )
]

{ #category : #uFFI }
OdbcStmt >> uFFIgetDataNr: i type: aType buf: buf bufLen: bufLen strLen_or_IndPtr: strLen_or_IndPtr [
	"SQLRETURN  SQL_API SQLGetData(SQLHSTMT StatementHandle,
           SQLUSMALLINT ColumnNumber, SQLSMALLINT TargetType,
           _Out_writes_opt_(_Inexpressible_(BufferLength)) SQLPOINTER TargetValue, 
				SQLLEN BufferLength,   _Out_opt_ SQLLEN *StrLen_or_IndPtr);"

	^ self
		ffiCall:
			#(SQLRETURN SQLGetData #(SQLHSTMT stmt , SQLUSMALLINT i , SQLSMALLINT aType , SQLPOINTER buf , SQLLEN bufLen , SQLLEN * strLen_or_IndPtr))
]

{ #category : #uFFI }
OdbcStmt >> uFFInumResultColumns: aHstmt [
	"SQLRETURN  SQL_API SQLNumResultCols(SQLHSTMT StatementHandle,
           _Out_ SQLSMALLINT *ColumnCount);"

	^ self ffiCall:
		  #( SQLRETURN SQLNumResultCols #( SQLHSTMT stmt , SQLSMALLINT
		        * columnCount ) )
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
