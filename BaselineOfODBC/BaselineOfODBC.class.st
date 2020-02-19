Class {
	#name : #BaselineOfODBC,
	#superclass : #BaselineOf,
	#category : #BaselineOfODBC
}

{ #category : #baselines }
BaselineOfODBC >> baseline: spec [
	<baseline>
	spec for: #common do: [ spec package: 'CAs-ODBC' ]
]
