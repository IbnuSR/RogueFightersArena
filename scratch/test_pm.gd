extends SceneTree

func _init() -> void:
	_run()

func _run() -> void:
	await process_frame
	await process_frame
	var pm = root.get_node_or_null("ProgressManager")
	print("--- INSPECTING PM ---")
	print("PM found:", pm != null)
	if pm:
		print("is_chapter_unlocked(1):", pm.is_chapter_unlocked(1))
		print("is_chapter_unlocked(2):", pm.is_chapter_unlocked(2))
		print("is_chapter_unlocked(3):", pm.is_chapter_unlocked(3))
		print("is_chapter_unlocked(4):", pm.is_chapter_unlocked(4))
		print("stage_progress:", pm.stage_progress)
		print("completed_chapters:", pm.completed_chapters)
		print("highest_chapter:", pm.highest_chapter)
	quit()
