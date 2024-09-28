@tool
extends Node

class_name BehaviorManager

@export var behavior: Resource  # Change this to Resource

# Temporary do-nothing function
func execute():
    if behavior and behavior.has_method("execute"):
        behavior.execute(get_parent())

# Original code commented out:
"""
# ... (previous code remains commented out) ...
"""
