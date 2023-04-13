# Helper class to setup and cleanup UPNP for easy server hosting.
extends Node

# I made this a node even if it should not need to be, because when using RefCounted, threads add a
# reference to the object of the method they run, and since the thread is owned by that same
# reference, we get a cycle. So one way to break the cycle is to use an Object instead, but using a
# Node instead is less error-prone as the user won't forget to free it.

var _upnp : UPNP
var _port := -1
var _protocols : PackedStringArray
# Not using a thread for now
#var _thread : Thread


#func _init():
#	_thread = Thread.new()


#func _notification(what: int):
#	if what == NOTIFICATION_PREDELETE:
#		pass


func setup(port: int, protocols: PackedStringArray, description: String, duration_seconds: int):
	_setup(port, protocols, description, duration_seconds)


func is_setup() -> bool:
	return _upnp != null


func cleanup():
	_cleanup()


func _setup(port: int, protocols: PackedStringArray, description: String, duration_seconds: int) \
	-> bool:
	
	if _upnp != null:
		_log_error("UPNP setup failed: already setup")
		return false
	
	var upnp := UPNP.new()
	print("UPNP setup discover...")
	var discover_result := upnp.discover()
	if discover_result != UPNP.UPNP_RESULT_SUCCESS:
		_log_error(str("UPNP discover failed: returned ", _format_result(discover_result)))
		return false
	
	var gateway := upnp.get_gateway()
	if gateway == null:
		_log_error("UPNP setup failed: no gateway")
		return false
	
	if not gateway.is_valid_gateway():
		_log_error("UPNP setup failed: no valid gateway")
		return false
	
	for protocol in protocols:
		_log_info(str("UPNP adding port mapping for ", protocol, "..."))
		var result := upnp.add_port_mapping(port, port, description, protocol, duration_seconds)
		if result != UPNP.UPNP_RESULT_SUCCESS:
			_log_error(str("UPNP failed to add port mapping (port ", port, ", protocol ", protocol, 
				"): returned ", _format_result(result)))
			return false

	var address := upnp.query_external_address()
	_log_info(str("External address: ", address))
	
	_upnp = upnp
	_port = port
	_protocols = protocols
	_log_info("UPNP setup done")
	return true


func _cleanup() -> bool:
	if _upnp == null:
		_log_error("UPNP cleanup failed: wasn't setup")
		return false
	
	for protocol in _protocols:
		_log_info(str("UPNP remove port mapping for ", protocol, "..."))
		var result := _upnp.delete_port_mapping(_port, protocol)
		if result != UPNP.UPNP_RESULT_SUCCESS:
			_log_error(str("UPNP port mapping removal failed (port ", _port, ", protocol ",
				protocol, "): returned ", _format_result(result)))
#			return false

	_upnp = null
	_log_info("UPNP cleanup done")
	return true


func _exit_tree():
	if is_setup():
		_cleanup()


func _log_info(msg: String):
	print(msg)


func _log_error(msg: String):
	push_error(msg)


static func _format_result(result: int) -> String:
	return str(_get_result_as_string(result), " (", result, ")")


static func _get_result_as_string(result: int) -> String:
	var items := ClassDB.class_get_enum_constants(&"UPNP", &"UPNPResult")
	return items[result]

