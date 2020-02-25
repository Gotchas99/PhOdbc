Extension { #name : #ByteArray }

{ #category : #'*CAs-ODBC' }
ByteArray >> asNullTerminatedString [
	| nullPos |
	nullPos := (self indexOf: 0) - 1.
	^ (String new: nullPos) replaceFrom: 1 to: nullPos with: self startingAt:1
]

{ #category : #'*CAs-ODBC' }
ByteArray >> asNullTerminatedStrings [
	| nullPos start strings len |
	strings:=OrderedCollection new.
	start:=1.
	[nullPos := (self indexOf: 0 startingAt: start) .
	len:= nullPos-start.
	strings add: ((String new: len)
		replaceFrom: 1
		to:len
		with: self
		startingAt: start)]doWhileFalse: [ start:= nullPos+1.(self at:start)=0 ].^strings
]
