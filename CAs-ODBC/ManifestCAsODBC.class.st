Class {
	#name : #ManifestCAsODBC,
	#superclass : #PackageManifest,
	#category : #'CAs-ODBC'
}

{ #category : #'code-critics' }
ManifestCAsODBC class >> ruleGRAnsiConditionalsRuleV1FalsePositive [
	^ #(#(#(#RGClassDefinition #(#OdbcEnv)) #'2020-02-25T11:10:29.359896+01:00') #(#(#RGPackageDefinition #(#'CAs-ODBC')) #'2020-02-26T10:28:24.798896+01:00') )
]

{ #category : #'code-critics' }
ManifestCAsODBC class >> ruleGRAnsiConvertorRuleV1FalsePositive [
	^ #(#(#(#RGPackageDefinition #(#'CAs-ODBC')) #'2020-02-26T12:32:17.940896+01:00') )
]

{ #category : #'code-critics' }
ManifestCAsODBC class >> ruleGRUsesCurlyBraceArraysRuleV1FalsePositive [
	^ #(#(#(#RGPackageDefinition #(#'CAs-ODBC')) #'2020-02-26T10:24:33.504896+01:00') )
]

{ #category : #'code-critics' }
ManifestCAsODBC class >> ruleRBExcessiveArgumentsRuleV1FalsePositive [
	^ #(#(#(#RGMethodDefinition #(#OdbcStmt #uFFIdescribeCol:type:buf:bufLen:strLenPtr:dataTypePtr:columnSizePtr:decimalDigitsPtr:nullablePtr: #false)) #'2020-02-14T06:40:55.525183+01:00') #(#(#RGMethodDefinition #(#OdbcStmt #uFFIdescribeCol:buf:bufLen:strLenPtr:dataTypePtr:columnSizePtr:decimalDigitsPtr:nullablePtr: #false)) #'2020-02-14T06:43:57.213183+01:00') )
]

{ #category : #'code-critics' }
ManifestCAsODBC class >> ruleRBLiteralArrayContainsCommaRuleV1FalsePositive [
	^ #(#(#(#RGPackageDefinition #(#'CAs-ODBC')) #'2020-02-07T18:05:46.349653+01:00') )
]
