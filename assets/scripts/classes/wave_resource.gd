extends Resource

class_name WaveResource

## ScriptableObject-based wave configuration ported from Unity Wave.cs.
## Replicates:
##   public string StartOn;
##   public string EndOn;
##   public int MaxEntitys;
##   public SpawnEntityInfo[] entities;

@export var start_event : String = "Start"
@export var end_event : String = ""
@export var step_event : String = ""
@export var wave_spawn_cooldown : float = 1.0
@export var max_entities : int = 200
@export var wave_enteries : Array[WaveEntryResource] = []

# Uppercase and alternative aliases matching Unity C# naming convention
var StartOn : String:
	get: return start_event
	set(val): start_event = val

var EndOn : String:
	get: return end_event
	set(val): end_event = val

var MaxEntitys : int:
	get: return max_entities
	set(val): max_entities = val

var MaxEntities : int:
	get: return max_entities
	set(val): max_entities = val

var entities : Array[WaveEntryResource]:
	get: return wave_enteries
	set(val): wave_enteries = val
