extends Resource

class_name WaveEntryResource

## Wave entry configuration ported from Unity Wave.cs SpawnEntityInfo.
## Replicates:
##   public Entity entity;
##   public int Amount;

@export var entity : EntityResource
@export var amount : int = 1
@export var spawn_chance := 100

# Uppercase aliases matching Unity C# naming convention
var Amount : int:
	get: return amount
	set(val): amount = val

var EntityData : EntityResource:
	get: return entity
	set(val): entity = val
