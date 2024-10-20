# The point of threaded chunk clearing is to solve the spikes/lags in the profiler when deleting a large array.
extends Node
var thread = Thread.new()
var semaphore = Semaphore.new()

func _ready():
	thread.start(self, "threadedUnloading") #begin running a thread that never finishes.

var freeChunks = []
var currentlyFreeing = false
func addToFreeQueue(chunkID):
	chunkID.translation = Vector3(-1000000,-1000000,-1000000) # Move the chunk out of sight while this thread takes its time to remove it properly.
	freeChunks.append(chunkID)

func _physics_process(delta):
	if freeChunks.empty() == false:
		if currentlyFreeing == false:
			currentlyFreeing = true
			semaphore.post()

func threadedUnloading(userdata):
	while true: #thread is constantly running, never finishes.
		semaphore.wait() # Thread is idle until posted.
		
		var chunkID = freeChunks.pop_front()
		chunkID.blockMap.clear()
		chunkID.meshArrays.clear()
		chunkID.meshInfo.clear()
		chunkID.call_deferred('deleteSelf')
		currentlyFreeing = false
