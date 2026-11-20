class_name OSUtil
extends Node

## Returns a dict of command line arguments.
## Only accepted arguments are in the form "--example" and "--example=value" 
static func parse_cmd_args() -> Dictionary:
	var arguments = {}
	for argument in OS.get_cmdline_args():
		if argument.contains("="):
			var key_value = argument.split("=")
			arguments[key_value[0].trim_prefix("--")] = key_value[1]
		else:
			arguments[argument.trim_prefix("--")] = ""
	
	return arguments


static func get_system_username():
	if OS.has_environment("USER"):
		return OS.get_environment("USER")
	elif OS.has_environment("USERNAME"):
		return OS.get_environment("USERNAME")
	else:
		var id = OS.get_unique_id()
		return "Player_" + id.substr(0, 6)
