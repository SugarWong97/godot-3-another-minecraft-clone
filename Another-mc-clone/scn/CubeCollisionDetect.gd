extends Spatial
# Built-in physics collision the size of a block. It could probably be used more, I added it late.

var query = PhysicsShapeQueryParameters.new()
var cube_shape = BoxShape.new()
func _ready():
	cube_shape.extents = Vector3(0.5, 0.5, 0.5)
	query.exclude = []
	query.margin = 0.00
	query.shape_rid = cube_shape
	query.collide_with_bodies = true
	query.collide_with_areas = true

func detect(collides_with, pos):
	query.collision_mask = collides_with
	query.transform = Transform(Vector3(1,0,0),Vector3(0,1,0),Vector3(0,0,1),Vector3(0.5+pos.x,0.5+pos.y,0.5+pos.z))
	return get_world().get_direct_space_state().intersect_shape(query)
