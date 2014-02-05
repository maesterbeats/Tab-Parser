#-------------------------------------------------------------
# CHET replace this with the path to your underscorejs lib...
#-------------------------------------------------------------

_ = require '/usr/local/lib/node_modules/underscore'


#==============================================================================
#						PARSE TAB
#==============================================================================
#
# @param: txt			Takes a formatting intact block of text for
#						processing.
#
# Returns: ParsedTab		Parsed Tab.... An array of note objects. 
#---------------------------------------------------------------------
# 
# SEE PROCESS LINE for details on format of ParsedTab.
#
#	This funciton, Parse Tab, should be the single entrypoint to the tab
#	parser. 
#
#---------------------------------------------------------------------
# TODO: 
#	
#	- Handle Bar Lines, Repeat Symbols, and String Names
#
#	- Handle Lines with tab intersperced with other content...
#
#	- Remove like 90% of the commenting...
#
#	- Replace the generic note object being pushed into the
#		results array with a custom Note object class...
#		That way it can have an SVG drawing api, a midi API
#		ect... without having to write adapters all over the
#		place, just update the getter/setters on the note 
#		object prototype/ optionaly extend it for each use case
#	
#==============================================================================


parseTab = (txt)->
	

	#-----------------------------------------------
	#		Pre process tab
	#----------------------------------------------
	 	
	splitText = txt.split "\n"
				
	try 
		filteredText = strip_non_Tab(splitText)
		
		if filteredText.length % 6 isnt 0
			throw new Error("bad num of tab lines")
		
	catch error
		console.log error	
		
	finally			
		extras = filteredText.length % 6
		addLines = 6 - extras
		for i in [0...addLines]			
			filteredText.push("--------")
		
	gtrStrings = flattenLines(filteredText)
	

	#-----------------------------------------------
	#		Parse it......
	#-----------------------------------------------
	
	ParsedTab = (processLine(_string) for _string in gtrStrings)
	
	
	
	return ParsedTab
	




#------------------------------------------------------------------------ 
#						STRIP NON TAB LINES
#------------------------------------------------------------------------ 
#
# @param: lines 			an array of strings to be searched and filtered
#
# RETURNS: Filtered		returns a filtered array of strings whos
#						contents are valid guitar tab
#
#------------------------------------------------------------------------ 


strip_non_Tab = (lines)->

	#------------------------------------------------
	# Returns true on POSTIVE match
	#------------------------------------------------
	enough_dashes = (line, minDashes)->
		_match = line.match /-/g
		if _match? and _match.length > minDashes
			true 
		else 
			false
			
	#------------------------------------------------
	# Returns true on NEGATIVE match
	#------------------------------------------------
	noWords = (line)->
		_match = line.match /[a-z]{4,100}/g
		not _match
	
	#------------------------------------------------
	# This Essentialy just a handler function for 
	# the tab tests. It applies each tab test to each 
	# line and allows only those that pass all the
	# tests to added to the returned array
	#------------------------------------------------
	
	Filtered = _.filter lines, (line)->
		dashTest = enough_dashes(line,4)
		wordTest = noWords(line,4)
		dashTest and wordTest


	return Filtered

		



			
#------------------------------------------------------------------------ 
#						FLATTEN LINES
#------------------------------------------------------------------------
#
# @param: lines			an array of strings containing valid guitar tab
#
# RETURNS: Strings		An array with six elements, each of which 
#						corresponds to one of the 6 guitarStrings
#
# Unraveling the vertical formatting of user input into a continuous
# horizontal representation. It uses a (i modulo 6) operation to 
# decide which of the six gtrStrings the current string should be
# appended to. 
#-----------------------------------------------------------------------


flattenLines = (lines)->
	Strings = ([] for i in [0..5])
	for line,i in lines
		idx = i % 6
		Strings[idx] += line
	return Strings		







#------------------------------------------------------------------------ 
#						PROCESS LINE
#------------------------------------------------------------------------
#
# @param: tab			A single Guitar string containing valid tab
#
# Returns: Results		An array of Note Objects each of which has
#						the following:
#						
#						prefixes: 	Prefix articulation symbols 
#						fretNum: 	The fret Number
#						postfixes: 	Postfix articulation symbols
#						duration:	The number of dashes untill
#									the next note
#-----------------------------------------------------------------------

processLine = (tab)->
	
	Results = []
	
	
	_preFixes = [
		"h"
		"p"
		"\\"
		"/"
		"("
		"b"
	]

	#------------------------------------------------------------------------
	# Im aware that defining these helper functions here is inefficient
	# because theyll get redefined on each iteration... But its only 6
	# calls and I dont have enough confidence with javascript yet to
	# get fancy with scope
	#------------------------------------------------------------------------

	sortPre_vs_Post = (rest)->
		[prefix, postfix] = [[],[]]
		for c in rest
			if c in _preFixes then prefix.push c else postfix.push c
		[prefix, postfix]


	processPost =(l)->
		[post, dash] = [[],0]
		for v in l
			if v is "-" then dash++ else post.push v
		[post,dash]
			
			

	updateResults = (pre, fret, post, blank, contex)->
		contex.push {prefix: pre, fretNum: fret, postFix: post, dur: blank}
			


	split_tab_at_frets = (_tab)->
		r = _tab.match /\d\d?\D*/g
		if r?
			return r
		else
			return ""
	

	# prep tab string for processing by breaking it into
	# sub-strings starting with frets.
	
	matches = split_tab_at_frets(tab)
	


	# Time to actualy process some tab. The general idea is this...
	#
	# FIRST split each match into two parts
	# 	1) The Fret number: which should be the first 1-2 characters
	#	in each match
	#	2) Everything else untill the next fret:
	#		NOTE:	some of this stuff will be post-articulations
	#				for the current fret such as vibrato....
	#				And some of it will be pre-articulations
	#				for the upcoming fret
	# 
	# NEXT sort out the "everything else" part by...
	#	1) splitting it off from the fret number
	#	2) splitting it into an array
	#	3) Taking that new array and feeding it to
	# 		the sortPrePost fn which basicaly just
	#		groups the symbols as either pre or post
	# 		fix simbols based on a lookup.
	#
	# THEN processing the postfix results a bit
	#	with processPost() since the postfix results
	# 	could still contain not only valid post-fix
	#	articulations but also blank spaces denoted as
	#	dashes
	#
	# FINALY taking the freshly minted pre, fret, post,
	#	and duration data for the current fret and
	# 	adding it to the results

	for m in matches
		
		fret = m.match(/\d\d?/)[0]
		rest = m.split(fret)[1].split ""
		
		pre = prefix
		 
		[prefix, postfix] = sortPre_vs_Post(rest)	
		[post, dur] = processPost(postfix)
		
		
		updateResults(pre, fret, post, dur, Results)	
		
	return Results
		
		

