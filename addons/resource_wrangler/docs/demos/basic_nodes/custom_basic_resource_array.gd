@tool
class_name CustomArrayResource
extends Resource

@export var teststring:String

@export_group("Plug many resources in")
@export var thing:Mesh

@export var stuff:Array[CustomResource] # many CustomResources
@export var stuff2:Array[Resource] # many Resources
