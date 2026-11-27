extends MainLoop

func _process(_delta: float) -> bool:
	var root = Engine.get_main_loop().root
	print("--- INSPECTING PROGRESS_MANAGER ---")
	var pm = root.get_node_or_null("ProgressManager")
	print("PM node:", pm)
	if pm:
		print("is_chapter_unlocked(1):", pm.is_chapter_unlocked(1))
		print("is_chapter_unlocked(2):", pm.is_chapter_unlocked(2))
		print("is_chapter_unlocked(3):", pm.is_chapter_unlocked(3))
		print("is_chapter_unlocked(4):", pm.is_chapter_unlocked(4))
		print("stage_progress:", pm.stage_progress)
		print("completed_chapters:", pm.completed_chapters)
	return true
