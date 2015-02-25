# psychTask.cs generic

## Set up PsiTurk and preload the pages that will be shown after task is done
psiTurk = PsiTurk(uniqueId, adServerLoc)
psiTurk.preloadPages(['postquestionnaire.html', 'debriefing.html'])

all_stim = {"stim": [["stim1", "something"], ["stim2", "something"]]}

instructions = [" This is the first instruction block \n
You can separate lines with this \n\n
Now there's two spaces"
]

# Some global variables
trialLength = 5000
IBI = 1000

## Set up canvas
c = document.getElementById("canvas")
ctx = c.getContext("2d")
width = canvas.width
height = canvas.height

# Calculates the mean of a numeric array (for feedback)
mean = (numericArray) ->
	sum = numericArray.reduce((a, b) -> a + b)
	avg = sum / numericArray.length

	return avg

# Clears canvas
clear_canvas = ->
	ctx.clearRect(0, 0, canvas.width, canvas.height)# 

# Writes multline text onto the canvas, and by default clears
multilineText = (txt, x, y, font, lineheight=30, clear=true, fillColor='black') ->
	clear_canvas() if clear

	ctx.fillStyle = fillColor
	ctx.font = font

	if x is "center"
		ctx.textAlign = "center"
		x = canvas.width/2 
	else
		ctx.textAlign = "start"

	y = canvas.height/2 if y is "center"

	lines = txt.split('\n')
	i = 0
	while i < lines.length
	  ctx.fillText lines[i], x, y + (i * lineheight)
	  i++

# Draws a circle. Can have a fill and edge colors, and can be put behind everything on the canvas
drawCircle = (x, y, radius, fillColor=null, edgeColor='black', behind=true) ->
	ctx.arc(x, y, radius, 0, 2 * Math.PI)

	if behind
		ctx.globalCompositeOperation="destination-over"
	else
		ctx.globalCompositeOperation="source-over"
		
	if edgecolor?
		ctx.lineWidth = 4
		ctx.strokeStyle = edgeColor
		ctx.stroke()

	if fillColor?
		ctx.fillStyle = fillColor
		ctx.fill()

	ctx.globalCompositeOperation="source-over"

# Hides left and right buttons
hideButtons = ->
	$("#leftButton").hide()
	$("#rightButton").hide()

# Sets the text of left and right buttoms
keyText = (text, key, color) ->
	if key is 'left'
		$("#leftText").html(text)
		$("#leftButton").show()
		$("#leftButton").css('background-color',color)
	else
		$("#rightText").html(text)
		$("#rightButton").show()
		$("#rightButton").css('background-color',color)

class Session
	constructor: (@blocks) ->
		hideButtons()
		@blockNumber = 0
		@max_blocks = @blocks.length
		@imgs_loaded = 0
		
	start: ->
		psiTurk.finishInstructions()

		# This ensures that the images for the two buttons are loaded
		# Could probably be done better
		@imgs_loaded++
		if @imgs_loaded is 2
			@nextBlock()

	# Go to next block
	nextBlock: ->
		@currBlock = @blocks[@blockNumber]
		if @blockNumber >= @max_blocks
			@endSession()
		else
			@blockNumber++

			# Start the next block
			# When block ends, call exitBlock with argument
			# Argument is whether to continue or go back (instructions)
			@currBlock.start ((arg1) => @exitBlock arg1)
	
	# Go back a block	
	prevBlock: ->
		if @blockNumber > 1
			@blockNumber = @blockNumber - 2

		@currBlock = @blocks[@blockNumber]

		@blockNumber++
		@currBlock.start ((arg1) => @exitBlock arg1)

	# This gets called when block is over.
	# Saves data and goes back or forward
	exitBlock: (next = true) ->
		psiTurk.saveData()
		if next
			@nextBlock()
		else
			@prevBlock()
	
	# Ends it all
	endSession: ->
		psiTurk.completeHIT()
		
	# Key presses are sent down to blocks to handle
	keyPress: (e) ->
		# Extracts code. Done differently for different browsers
		code = e.charCode || e.keyCode
		input = String.fromCharCode(code).toLowerCase()

		if input == "j"
			$('rightButton').click()
		
		@currBlock.keyPress input

	# Handles button clocks (mostly for questionnaires)
	buttonClick: ->
		@currBlock.buttonClick()


## Instruction block
## Will display instructions in @message, and set left and right buttons to said text
## Can optionally take a correct response (if incorrect, will not allow you to advance) & button colors
class Instruction
	constructor: (@message, @leftKey = null, @rightKey = "Continue", @corrResp = null, @leftColor = 'white', @rightColor = 'white') ->

	# Called by Session. Given exit function
	# Starts timer, displays text, and displays buttons that are not null
	start: (@exitTrial) ->
		@startTime = (new Date).getTime()
		multilineText(@message, 10, 30, "25px Arial", 33)
		
		hideButtons()
		if @leftKey?
			keyText(@leftKey, 'left', @leftColor)

		## Show key picture and text next to it
		keyText(@rightKey, 'right', @rightColor)

	# Record RT, check if response is correct (if applicable), and 
	keyPress: (key) ->
		rt = (new Date).getTime() - @startTime

		if @corrResp?
			if @corrResp is key
				$('#correct').modal('show')
				setTimeout (=> $('#correct').modal('hide')), 1250
				setTimeout (=> @exitTrial()), 1250
				acc = 1
			else
			## Show incorrect message
				$('#error').modal('show')
				setTimeout (=> $('#error').modal('hide')), 1250
				acc = 0
		else # If there is no correct answer, just record what was pressed
			if key is 'f'
				acc = 'BACK'
				@exitTrial false
			else if key is 'j'
				acc = 'FORWARD'
				@exitTrial()

		psiTurk.recordTrialData({'block': @message, 'rt': rt, 'resp': key, 'acc': acc})

## Here's an example of how to modify an Instruction by extending it
## This simply draws to additional elements to the page, while still calling the original 
## start function
class Slide1 extends Instruction
	start: (@exitTrial) ->
		# Call original start function
		super @exitTrial

		# Draw text and a key onto the page
		multilineText("#{String.fromCharCode(9888)}", 0, 185, "80px Arial", 30, false, fillColor='red')
		ctx.drawImage(jkey, 88, canvas.height-267, 43, 43)

## The Block class is composed of Trials that have show() and logResponse() functions
## It cycles through them and displays a message at the beginning of the block
## Similar to a Session, 
class Block
	constructor: (@condition, @message, @trials) ->
		@trials = trials
		@trialNumber = 0
		@max_trials = @trials.length
		@data = []

	# When block starts, hide buttons, show message, and after IBI start first trial
	start: (@exitBlock) ->
		# Show ready message
		hideButtons()
		multilineText(@message, "center", "center", "35px Arial", 75)

		setTimeout (=> @nextTrial()), IBI

	nextTrial: ->
		@currTrial = @trials[@trialNumber]
		if @trialNumber >= @max_trials
			@trialNumber++
			@endBlock()
		else
			@trialNumber++
			@currTrial.show ((arg1) => @logTrial arg1)

	endBlock: ->
		# Call exit function (given by Session -- nextTrial())
		@exitBlock()

	logTrial: (trialData) ->
		# Save data to server in JSON format
		psiTurk.recordTrialData({'block': @condition, 'rt': trialData[0], 'resp': trialData[1], 'acc': trialData[2]})

		# Save data locally in block
		@data.push(trialData)

		@nextTrial()

	keyPress: (key) ->
		# Send key press down to trials
		@currTrial.logResponse(key)

# This extention of block adds accuracy feedback and displays it after block is over
class PracticeBlock extends Block
	constructor: (@condition, @message, @trials, @minacc) ->
		super @condition @message @trials

	endBlock: ->
		@feedback()

	feedback: ->
		# Calculate mean accuracy from saved data
		# Exclude strings ('NAs')
		accs = ((if typeof n[2] == 'string' then 0 else n[2]) for n in @data)
		@accs = mean(accs)

		multilineText("You got #{Math.round(@accs*100.toString(), )}% of trials correct", 10, 60, "30px Arial")

		if @accs < @minacc
			multilineText("You need to get at least #{@minnacc.toString()}% right to continue", 10, 130, "25px Arial", 20, false)
			
			keyText("Try again", 'left')
			
			@done = false
		else
			multilineText("Good job, let's continue", 10, 130, "25px Arial", 20, false)
			keyText("Okay, continue", 'right')

			@done = true

	keyPress: (key) ->
		# Handle key presses if we're done with trials
		if @trialNumber > @max_trials
			# Only allowed to continue if accuracy was above minimum. 
			# Otherwise restart
			if @done
				if key is 'j'
					@exitBlock()
			else if key is 'f'
				#Dont forget to log trials -add
				@restartBlock()

		else super key

	# If accuracy is not above threshold, reset trials and block
	# Record that block was restarted
	restartBlock: ->
		trial.reset() for trial in @trials
			
		@trialNumber = 0
		## Save old data -- add this
		@data = []
		hideButtons()

		# Log that practice was restarted
		psiTurk.recordTrialData({'block':@condition, 'rt': 'REST', 'resp': 'REST', 'acc': @accs})

		@nextTrial()

# A trial class. 
# Displays itself, handles keys, keep track of accuracy and responses
# Assumes there is a correct response
class Trial
	constructor: (@item, @corrResp) ->
		@reset()

	# Initial variable conditions
	reset: ->
		@rt = 'NA'
		@resp = 'NA'
		@acc = 'NA'

		# Trial starts as inactive. Inactive trials do not responsd to key presses 
		# Also serves the purpose that trials can expire (timeout), but only if they haven't received
		# a key press that flips this to true
		@inactive = true

	show: (@exitTrial)  ->
		clear_canvas()
		@inactive = false

		# DO Trial timing here

		# First show something
		multilineText("Show something", "center", canvas.height/2 - 75, "40px Arial")

		# After ITI show something else
		setTimeout (=>

			# Set middle center text to stimuli
			multilineText(@item, "center", "center", "35px Arial", 20, false)

			# Log trial start time. Starts after all stimuli is on screen
			@startTime = (new Date).getTime()
			setTimeout (=> @endTrial()), trialLength

			), ITI

	endTrial: ->
		if @inactive is false
			@inactive = true

			# Iff accuracy is 'NA', it means user did not response before trial ended
			if @acc is 'NA'
				multilineText("You took too long!", "center", canvas.height/2+140, "30px Arial", lineheight = 20, clear=false)
				drawCircle(canvas.width/2, canvas.height/2-40, 100, fillColor = 'lightyellow')
			else
				drawCircle(canvas.width/2, canvas.height/2-40, 100, fillColor = 'lightyellow')

			# After ITI, end trial and give data to block in JSON format
			setTimeout (=> @exitTrial({'rt': @rt, 'resp': @resp, 'acc': @acc}), ITI

	# This gets called if a key is pressed. 
	logResponse: (resp) ->
		if @inactive is false

			# Calculate RT and resp
			@rt = (new Date).getTime() - @startTime
			@resp = resp

			if resp is "f"
				## Some example conditions for accuracy
				if @corrResp is "nonliv" or @corrResp is "small"
					@acc = 1
				else
					@acc = 0
			else if resp is "j"
				if @corrResp is "living" or @corrResp is "big"
					@acc = 1
				else
					@acc = 0
			# If other key is pressed
			else
				@acc = 'other'

			@endTrial()

# This class simply displays the post questionnaire and 
# collects information from it once button is clocked
class Questionnaire
	start: (@exitTrial) ->
		$('body').html(psiTurk.getPage('postquestionnaire.html'))

	buttonClick: ->
		$("select").each (i, val) ->
		  psiTurk.recordUnstructuredData @id, @value

		psiTurk.recordUnstructuredData 'openended', $('#openended').val()

		@exitTrial()

# Displays debriefing and when button is clicked ends
class Debriefing
	start: (@exitTrial) ->
		$('body').html(psiTurk.getPage('debriefing.html'))

	buttonClick: ->
		@exitTrial()		

# jQuery call to set key and click handlers
jQuery ->
	$(document).keypress (event) ->
		currSession.keyPress(event)

	$("body").on('click','button',  ->
		currSession.buttonClick())

# This is where you set the order of your blocks
# Simply an array that will get passed down to the Session
blocks = [
	new Instruction instructions[0], "Back"
	new Slide1 instructions[1]
	new LivingKeyMap "Show this text!!", "Back"

	## This is how you create a block. Pass arguments and then itirate over a list of stimuli to create New trials
	## In this case it makes a PracticeBlock of new PracFeedbackTrials from all_stim
	new PracticeBlock "nameofPracticeBlock", "Initial message", (new PracFeedbackTrial(n[0], n[1]) for n in all_stim['stim'])
	new Instruction instructions[9], null, "Continue"
	new Block "nameofSecondBlock", "Set an inital message", (new FeedbackTrial(n[0], n[1]) for n in all_stim['stim'])

	# Include this to show questionnaire and debriefing
	new Questionnaire
	new Debriefing
]

## These have to be at the bottom
# Create the session with block array above
currSession = new Session(blocks)

# Create and load the f and k keys
fkey = new Image()
jkey = new Image()

fkey.onload = ( -> currSession.start())
jkey.onload = ( -> currSession.start())

fkey.src = "static/img/f_key.png"
jkey.src = "static/img/j_key.png"