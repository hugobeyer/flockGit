@tool
extends PopupMenu

# MIT License
#
# Copyright (c) 2023 Donn Ingle (donn.ingle@gmail.com)
# Copyright (c) 2022 Nathan Hoad
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.

enum {ITEM_DUPLICATE, ITEM_MAKEUNIQUE, ITEM_EXTEND}

#const NSrw = preload("../../ns.gd")

var board: Control
var selected_things:Array # peeked from board in _can_pop()


func popup_if_valid_at(next_position: Vector2) -> void:
	if _can_pop():
		position = next_position
		popup()


func _can_pop():
	selected_things = board.get_selected_rwnodes()
	return selected_things.size() > 0


### Signals
func _on_id_pressed(id: int) -> void:
	match id:
		ITEM_DUPLICATE:
			board.duplicate_as_clone()#selected_things)
		ITEM_MAKEUNIQUE:
			board.duplicate_as_unique()#selected_things)


func _on_about_to_popup() -> void:
	clear()
	size = Vector2.ZERO
	add_item("Duplicate unique", ITEM_MAKEUNIQUE)
	add_separator()
	add_item(NSrw.clone_string, ITEM_DUPLICATE)
