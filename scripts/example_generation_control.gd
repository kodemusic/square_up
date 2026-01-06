extends Node

## Example: How to control level generation with the new API

func _ready() -> void:
	print("\n" + "=" * 60)
	print("  GENERATION CONTROL EXAMPLES")
	print("=" * 60 + "\n")

	# Run examples
	example_1_default_behavior()
	example_2_pre_generate()
	example_3_manual_control()
	example_4_conditional_generation()

	print("\n" + "=" * 60)
	print("  ALL EXAMPLES COMPLETE")
	print("=" * 60 + "\n")

## EXAMPLE 1: Default behavior (auto-generate + cache)
func example_1_default_behavior() -> void:
	print("\n--- EXAMPLE 1: Default Behavior ---")
	print("Auto-generate enabled, caching enabled\n")

	LevelData.clear_cache()  # Start fresh

	# First call - generates and caches
	var start1 = Time.get_ticks_msec()
	var level1 = LevelData.create_level(3)
	var time1 = Time.get_ticks_msec() - start1
	print("First call to create_level(3): %d ms (generated)" % time1)

	# Second call - returns cached
	var start2 = Time.get_ticks_msec()
	var level2 = LevelData.create_level(3)
	var time2 = Time.get_ticks_msec() - start2
	print("Second call to create_level(3): %d ms (cached)" % time2)

	print("Cache size: %d levels" % LevelData.get_cache_size())

## EXAMPLE 2: Pre-generate at startup (recommended)
func example_2_pre_generate() -> void:
	print("\n--- EXAMPLE 2: Pre-Generate at Startup ---")
	print("Generate levels 1-10 upfront\n")

	LevelData.clear_cache()

	# Pre-generate levels 1-10
	LevelData.pre_generate_levels(1, 10)

	# Now all calls are instant
	var start = Time.get_ticks_msec()
	for i in range(1, 11):
		var level = LevelData.create_level(i)
	var elapsed = Time.get_ticks_msec() - start

	print("Loaded 10 cached levels in: %d ms" % elapsed)
	print("Average per level: %.1f ms" % (elapsed / 10.0))

## EXAMPLE 3: Manual control (disable auto-generation)
func example_3_manual_control() -> void:
	print("\n--- EXAMPLE 3: Manual Control ---")
	print("Disable auto-generation, control when levels are created\n")

	LevelData.clear_cache()
	LevelData.configure_generation(false, true)  # Disable auto-gen

	# Try to create level without pre-generating
	var level_bad = LevelData.create_level(5)
	print("Tried to create level 5: '%s' (placeholder)" % level_bad.level_name)

	# Now pre-generate it
	print("\nPre-generating level 5...")
	LevelData.pre_generate_levels(5, 5)

	# Now it works
	var level_good = LevelData.create_level(5)
	print("Created level 5: '%s' (real level)" % level_good.level_name)
	print("Is cached: %s" % LevelData.is_cached(5))

	# Re-enable auto-generation for other examples
	LevelData.configure_generation(true, true)

## EXAMPLE 4: Conditional generation (generate on demand)
func example_4_conditional_generation() -> void:
	print("\n--- EXAMPLE 4: Conditional Generation ---")
	print("Generate levels in batches as needed\n")

	LevelData.clear_cache()

	# Simulate player progression
	var current_level = 1

	# Generate first batch (levels 1-5)
	print("Player starts game - generating levels 1-5")
	LevelData.pre_generate_levels(1, 5)
	print("Cache size: %d" % LevelData.get_cache_size())

	# Player reaches level 4 - generate next batch
	current_level = 4
	print("\nPlayer reached level %d - generating levels 6-10" % current_level)
	LevelData.pre_generate_levels(6, 10)
	print("Cache size: %d" % LevelData.get_cache_size())

	# Player reaches level 9 - generate next batch
	current_level = 9
	print("\nPlayer reached level %d - generating levels 11-15" % current_level)
	LevelData.pre_generate_levels(11, 15)
	print("Cache size: %d" % LevelData.get_cache_size())

	print("\nTotal levels ready: %d" % LevelData.get_cache_size())

## Bonus: Show how to check cache before loading
func smart_level_loader(level_id: int) -> LevelData:
	if not LevelData.is_cached(level_id):
		print("Level %d not cached, generating..." % level_id)
		LevelData.pre_generate_levels(level_id, level_id)

	return LevelData.create_level(level_id)
