extends Label

func _on_Wait_timeout():
	var fps = Engine.get_frames_per_second()
	var textLine1 = str(fps)+' FPS'
	var textLine2 = str(1000*(Performance.get_monitor(Performance.TIME_PROCESS)))+"ms Frame time"
	text = textLine1+'\n'+textLine2
