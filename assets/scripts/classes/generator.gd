extends Node
##Generator of level tile maps, generates.
class_name Generator
##Tilemap to use.
@export var level_data : LevelTileMap
##Items to use.
@export var items_data : Array[ItemResource]
##Entity to lock on the generation(spawn tilemap in it parent).
@export var lock_to_entity : CharacterBody2D
##Is generator running?
@export var is_running = false
##Dictionary of loaded chunks, key is chunk position.
@export var chunks_loaded := {}
##Dictionary of unloaded chunks, key is chunk position.
@export var chunks_unloaded := {}
##Dictionary of loaded items, key is chunk position.
@export var items_loaded := {}
##Dictionary of unloaded items, key is chunk position.
@export var items_unloaded := {}
##Range of tile generation, it will generate in radius, so it range*2+1.
@export var range := 1
##Seed used in generation.
@export var seed = 0
##Generators noise function.
@export var noise_generator = FastNoiseLite.new()
##Tilemap it generate on.
@export var tilemap : TileMap
##Template for empty tile.
@export var empty_tile : TileMapPattern

func _init(level_data : LevelTileMap, items_data : Array[ItemResource],  lock_to_entity : CharacterBody2D, seed := 0) -> void:
	name = "Generator"
	self.empty_tile = TileMapPattern.new()
	self.level_data = level_data
	self.empty_tile.set_size(self.level_data.tile_size)
	for x in self.level_data.tile_size.x:
		for y in self.level_data.tile_size.y:
			self.empty_tile.set_cell(Vector2(x, y))
	self.items_data = items_data
	self.lock_to_entity = lock_to_entity
	self.seed = seed
	self.noise_generator.seed = seed
	if self.lock_to_entity != null:
		self.lock_to_entity.tree_exiting.connect(_on_entity_tree_exiting)
	Global.generate_inited.emit(level_data, lock_to_entity)

func _on_entity_tree_exiting() -> void:
	if is_instance_valid(tilemap):
		tilemap.queue_free()
	queue_free()

func _on_tilemap_tree_exiting() -> void:
	is_running = false

##Start chunk generation, if not started.
func generate() -> void:
	if self.is_running:
		return
	self.is_running = true
	self.tilemap = TileMap.new()
	tilemap.name = "Level"
	self.tilemap.tree_exiting.connect(_on_tilemap_tree_exiting)
	self.tilemap.tile_set = self.level_data.tile_set
	for layer in self.level_data.get_layers_count():
		self.tilemap.add_layer(layer)
		self.tilemap.set_layer_z_index(layer, self.level_data.get_layer_z_index(layer))
	self.lock_to_entity.add_sibling(self.tilemap)
	while self.is_running:
		var position_tilemap = self.tilemap.local_to_map(self.lock_to_entity.position)
		var position = Vector2i(floor(float(position_tilemap.x) / self.level_data.tile_size.x), floor(float(position_tilemap.y) / self.level_data.tile_size.y)) * self.level_data.tile_size
		var range_with_tile_size = self.range*self.level_data.tile_size
		for x in range(position.x - range_with_tile_size.x, position.x + (self.range+1)*self.level_data.tile_size.x, self.level_data.tile_size.x):
			for y in range(position.y - range_with_tile_size.y, position.y + (self.range+1)*self.level_data.tile_size.y, self.level_data.tile_size.y):
					chunk_load(Vector2i(x,y), chunks_unloaded.get(Vector2i(x,y)))
		var area_of_chunks = Rect2i(position - range_with_tile_size, range_with_tile_size * 2 + self.level_data.tile_size)
		for chunk_position in chunks_loaded:
			if !area_of_chunks.has_point(chunk_position):
				chunk_unload(chunk_position)
		await self.lock_to_entity.get_tree().process_frame
	Global.generate_stopped.emit(self.level_data, self.lock_to_entity)

##Load chunk at position in tilemap.
func chunk_load(position : Vector2i, tile : LevelTileMap.Tile = null) -> void:
	if chunks_loaded.has(position):
		return
	if tile == null:
		chunks_loaded[position] = self.level_data.tiles[abs(round(self.noise_generator.get_noise_2dv(position)*len(self.level_data.tiles)))]
	else:
		chunks_loaded[position] = tile
		chunks_unloaded.erase(position)
	self.tilemap.set_pattern(chunks_loaded[position].layer, position, chunks_loaded[position].pattern) 
	if tile == null:
		Global.generate_on_new_loaded.emit(position, tile)
	Global.generate_on_loaded.emit(position, tile)

##Unload chunk at position.
func chunk_unload(position : Vector2i) -> void:
	if chunks_unloaded.has(position):
		return
	chunks_unloaded[position] = chunks_loaded[position]
	chunks_loaded.erase(position)
	self.tilemap.set_pattern(chunks_unloaded[position].layer, position, self.empty_tile)
	Global.generate_on_unloaded.emit(position, chunks_unloaded[position])

##Stops the generator, returns if stopped.
func stop() -> bool:
	if not self.is_running:
		return false
	self.is_running = false
	return true
