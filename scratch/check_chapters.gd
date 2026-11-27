extends SceneTree

func _init():
	print("--- TEST CHAPTER UNLOCKED ---")
	print("is_chapter_unlocked(1):", ProgressManager.is_chapter_unlocked(1))
	print("is_chapter_unlocked(2):", ProgressManager.is_chapter_unlocked(2))
	print("is_chapter_unlocked(3):", ProgressManager.is_chapter_unlocked(3))
	print("is_chapter_unlocked(4):", ProgressManager.is_chapter_unlocked(4))
	print("stage_progress:", ProgressManager.stage_progress)
	print("completed_chapters:", ProgressManager.completed_chapters)
	quit()
