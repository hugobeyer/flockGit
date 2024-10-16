@tool
extends Resource

## The metadata all goes into this method. You can also override it
## in inheritors of this class to change the details.
static func rw_metadata():
	return {
	&"noinstance" : true # true would exclude this resource from the graph.rw texture nodes
	}

## This resource will not instance in Resource Wrangler.
## At least that's the plan...

@export var stuff:Resource
