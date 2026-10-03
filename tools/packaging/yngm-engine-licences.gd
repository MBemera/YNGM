extends SceneTree

func _initialize() -> void:
	var output_path := OS.get_cmdline_user_args()[0]
	var notices := {
		"version": Engine.get_version_info(),
		"engine_license": Engine.get_license_text(),
		"third_party_licenses": Engine.get_license_info(),
		"third_party_copyrights": Engine.get_copyright_info(),
	}
	var output := FileAccess.open(output_path, FileAccess.WRITE)
	output.store_string(JSON.stringify(notices, "\t"))
	quit()