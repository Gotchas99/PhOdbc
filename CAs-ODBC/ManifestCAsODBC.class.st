"
I store metadata for this package. These meta data are used by other tools such as the SmalllintManifestChecker and the critics Browser
"
Class {
	#name : #ManifestCAsODBC,
	#superclass : #PackageManifest,
	#category : #'CAs-ODBC-Manifest'
}

{ #category : #'code-critics' }
ManifestCAsODBC class >> ruleRBExcessiveArgumentsRuleV1FalsePositive [
	^ #(#(#(#RGMethodDefinition #(#OdbcStmt #uFFIdescribeCol:type:buf:bufLen:strLenPtr:dataTypePtr:columnSizePtr:decimalDigitsPtr:nullablePtr: #false)) #'2020-02-14T06:40:55.525183+01:00') #(#(#RGMethodDefinition #(#OdbcStmt #uFFIdescribeCol:buf:bufLen:strLenPtr:dataTypePtr:columnSizePtr:decimalDigitsPtr:nullablePtr: #false)) #'2020-02-14T06:43:57.213183+01:00') )
]

{ #category : #'code-critics' }
ManifestCAsODBC class >> ruleRBLiteralArrayContainsCommaRuleV1FalsePositive [
	^ #(#(#(#RGPackageDefinition #(#'CAs-ODBC')) #'2020-02-07T18:05:46.349653+01:00') )
]
