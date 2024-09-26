extends Node

# Define global signals that can be emitted by any node
signal enemy_killed  # Add parameters if needed (like enemy ID or reference)
signal enemy_knockback_finished(enemy: Node2D)
