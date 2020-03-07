Class {
	#name : #OdbcConstants,
	#superclass : #SharedPool,
	#classVars : [
		'SQLCHAR',
		'SQLHANDLE',
		'SQLHDBC',
		'SQLHDESC',
		'SQLHENV',
		'SQLHSTMT',
		'SQLHWND',
		'SQLINTEGER',
		'SQLLEN',
		'SQLPOINTER',
		'SQLRETURN',
		'SQLSMALLINT',
		'SQLUINTEGER',
		'SQLULEN',
		'SQLUSMALLINT',
		'SQL_ATTR_ODBC_VERSION',
		'SQL_CHAR',
		'SQL_CLOSE',
		'SQL_C_CHAR',
		'SQL_C_DOUBLE',
		'SQL_C_FLOAT',
		'SQL_C_LONG',
		'SQL_C_NUMERIC',
		'SQL_C_SHORT',
		'SQL_C_TYPE_DATE',
		'SQL_C_TYPE_TIME',
		'SQL_C_TYPE_TIMESTAMP',
		'SQL_DATETIME',
		'SQL_DECIMAL',
		'SQL_DOUBLE',
		'SQL_DRIVER_NOPROMPT',
		'SQL_DROP',
		'SQL_ERROR',
		'SQL_FETCH_ABSOLUTE',
		'SQL_FETCH_FIRST',
		'SQL_FETCH_LAST',
		'SQL_FETCH_NEXT',
		'SQL_FETCH_PRIOR',
		'SQL_FETCH_RELATIVE',
		'SQL_FLOAT',
		'SQL_HANDLE_DBC',
		'SQL_HANDLE_DESC',
		'SQL_HANDLE_ENV',
		'SQL_HANDLE_STMT',
		'SQL_INTEGER',
		'SQL_INVALID_HANDLE',
		'SQL_NEED_DATA',
		'SQL_NO_DATA',
		'SQL_NO_TOTAL',
		'SQL_NTS',
		'SQL_NULL_HANDLE',
		'SQL_NUMERIC',
		'SQL_OV_ODBC3',
		'SQL_PARAM_DATA_AVAILABLE',
		'SQL_REAL',
		'SQL_RESET_PARAMS',
		'SQL_SMALLINT',
		'SQL_SS_XML',
		'SQL_STILL_EXECUTING',
		'SQL_SUCCESS',
		'SQL_SUCCESS_WITH_INFO',
		'SQL_TYPE_DATE',
		'SQL_TYPE_TIME',
		'SQL_TYPE_TIMESTAMP',
		'SQL_UNBIND',
		'SQL_UNKNOWN_TYPE',
		'SQL_VARCHAR'
	],
	#category : #'CAs-ODBC'
}

{ #category : #'class initialization' }
OdbcConstants class >> initialize [
	Smalltalk addToStartUpList: self.
	self startUp:true
]

{ #category : #'class initialization' }
OdbcConstants class >> initializeConstants [
	"handle type identifiers"

	"https://github.com/microsoft/ODBC-Specification/blob/master/Windows/inc/sql.h"

	SQL_NULL_HANDLE := 0.
	SQL_HANDLE_ENV := 1.
	SQL_HANDLE_DBC := 2.
	SQL_HANDLE_STMT := 3.
	SQL_HANDLE_DESC := 4.
	"types"
	SQLCHAR := #uchar.
	SQLSMALLINT := #short.
	SQLUSMALLINT := #ushort.
	SQLINTEGER := #long.
	SQLUINTEGER := #ulong.
	Smalltalk vm is64bit
		ifTrue: [ SQLLEN := #long.
			SQLULEN := #ulong ]
		ifFalse: [ SQLLEN := #short.
			SQLULEN := #ushort ].
	SQLRETURN := SQLSMALLINT.
	SQLPOINTER := 'void*'.
	SQLHWND := SQLPOINTER.
	SQLHANDLE := 'void*'.
	SQLHENV := SQLHANDLE.
	SQLHDBC := SQLHANDLE.
	SQLHSTMT := SQLHANDLE.
	SQLHDESC := SQLHANDLE.
	SQL_NTS := -3.


	SQL_DRIVER_NOPROMPT := 0.

	"env attr"
	SQL_ATTR_ODBC_VERSION := 200.
	SQL_OV_ODBC3 := 3.

]

{ #category : #'class initialization' }
OdbcConstants class >> initializeStatement [
	"handle type identifiers"

	"https://github.com/microsoft/ODBC-Specification/blob/master/Windows/inc/sql.h"

	"FetchOrientation"
	SQL_FETCH_NEXT := 1.
	SQL_FETCH_FIRST := 2.
	SQL_FETCH_LAST := 3.
	SQL_FETCH_PRIOR := 4.
	SQL_FETCH_ABSOLUTE := 5.
	SQL_FETCH_RELATIVE := 6.
	"Free statement"
	SQL_CLOSE := 0.
	SQL_DROP := 1.
	SQL_UNBIND := 2.
	SQL_RESET_PARAMS := 3
]

{ #category : #'class initialization' }
OdbcConstants class >> initializeTypes [

	"SQL data type codes"
	"https://docs.microsoft.com/en-us/sql/odbc/reference/appendixes/appendix-d-data-types?view=sql-server-ver15"
	SQL_UNKNOWN_TYPE := 0.
	SQL_CHAR := 1.
	SQL_NUMERIC := 2.
	SQL_DECIMAL := 3.
	SQL_INTEGER := 4.
	SQL_SMALLINT := 5.
	SQL_FLOAT := 6.
	SQL_REAL := 7.
	SQL_DOUBLE := 8.
	SQL_DATETIME := 9.
	SQL_VARCHAR := 12.
	SQL_TYPE_DATE := 91.
	SQL_TYPE_TIME := 92.
	SQL_TYPE_TIMESTAMP := 93.
	SQL_SS_XML := -152.
	" C datatype to SQL datatype mapping"
	SQL_C_CHAR := SQL_CHAR.
	SQL_C_LONG := SQL_INTEGER.
	SQL_C_SHORT := SQL_SMALLINT.
	SQL_C_FLOAT := SQL_REAL.
	SQL_C_DOUBLE := SQL_DOUBLE.
	SQL_C_NUMERIC := SQL_NUMERIC.
	SQL_C_TYPE_DATE := SQL_TYPE_DATE.
	SQL_C_TYPE_TIME := SQL_TYPE_TIME.
	SQL_C_TYPE_TIMESTAMP := SQL_TYPE_TIMESTAMP.

]

{ #category : #'system startup' }
OdbcConstants class >> startUp: isImageStarting [
	isImageStarting
		ifFalse: [ ^ self ].
	self initializeConstants.
	self initializeTypes
.self	initializeStatement 
]
