class_name Surfaces
extends RefCounted

const TEXTURE_ROOT := "res://assets/textures/"
const LAB_CONCRETE := "concrete_wall_008"
const LOBBY_MARBLE := "marble_01"
const DIAMOND_PLATE := "metal_plate"
const ROOF_CONCRETE := "concrete_floor_worn_001"
const SIDEWALK_CONCRETE := "concrete_floor_02"
const ASPHALT := "asphalt_02"
const CARPET := "dirty_carpet"
const CORRUGATED_IRON := "corrugated_iron"
const RUSTY_GRATE := "metal_grate_rusty"
const RED_BRICK := "large_red_bricks"
const WOOD_FLOOR := "laminate_floor_02"
const HANGAR_CONCRETE := "hangar_concrete_floor"
const CLEAN_TILES := "floor_tiles_06"
const BLUE_METAL := "blue_metal_plate"

static var material_cache: Dictionary = {}


static func get_textured(texture_id: String, meters_per_tile: float, tint := Color.WHITE) -> StandardMaterial3D:
	var cache_key := "%s|%s|%s" % [texture_id, meters_per_tile, tint.to_html()]
	if material_cache.has(cache_key):
		return material_cache[cache_key]
	var folder := TEXTURE_ROOT + texture_id + "/"
	var material := StandardMaterial3D.new()
	material.albedo_texture = load(folder + "albedo.jpg")
	material.albedo_color = tint
	material.normal_enabled = true
	material.normal_texture = load(folder + "normal.jpg")
	material.roughness_texture = load(folder + "roughness.jpg")
	material.uv1_triplanar = true
	material.uv1_world_triplanar = true
	material.uv1_scale = Vector3.ONE / meters_per_tile
	material.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
	material_cache[cache_key] = material
	return material


static func get_glass() -> StandardMaterial3D:
	if material_cache.has("glass"):
		return material_cache["glass"]
	var material := StandardMaterial3D.new()
	material.albedo_color = Color(0.45, 0.7, 0.85, 0.28)
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.metallic = 0.6
	material.roughness = 0.05
	material_cache["glass"] = material
	return material


static func get_window_glass() -> StandardMaterial3D:
	if material_cache.has("window_glass"):
		return material_cache["window_glass"]
	var material := StandardMaterial3D.new()
	material.albedo_color = Color(0.08, 0.14, 0.22)
	material.metallic = 0.8
	material.roughness = 0.08
	material.emission_enabled = true
	material.emission = Color(0.2, 0.55, 0.8)
	material.emission_energy_multiplier = 0.35
	material_cache["window_glass"] = material
	return material
