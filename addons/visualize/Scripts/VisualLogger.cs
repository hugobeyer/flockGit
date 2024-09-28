﻿using Godot;
using System.Collections.Generic;
using Visualize.Core;
using Visualize.Utils;

namespace Visualize;

public class VisualLogger
{
    // This is ugly using public static here but I don't know how else to do it
    public static Dictionary<Node, VBoxContainer> VisualNodes { get; set; }

    private static readonly Dictionary<Node, VBoxContainer> visualNodesWithoutVisualAttribute = new();

    private const int MAX_LABELS_VISIBLE_AT_ONE_TIME = 5;

    public virtual void Log(object message, Node node, double fadeTime = 5)
    {
        VBoxContainer vbox = GetOrCreateVBoxContainer(node);

        if (vbox != null)
        {
            AddLabel(vbox, message, fadeTime);
        }
    }

    private static VBoxContainer GetOrCreateVBoxContainer(Node node)
    {
        if (VisualNodes != null && VisualNodes.TryGetValue(node, out VBoxContainer vbox))
        {
            return vbox;
        }

        if (node is not Control and not Node2D)
        {
            return null;
        }

        if (!visualNodesWithoutVisualAttribute.TryGetValue(node, out vbox))
        {
            vbox = new VBoxContainer
            {
                Scale = Vector2.One * VisualUI.VISUAL_UI_SCALE_FACTOR
            };

            node.AddChild(vbox);
            visualNodesWithoutVisualAttribute[node] = vbox;
        }

        return vbox;
    }

    private static void AddLabel(VBoxContainer vbox, object message, double fadeTime)
    {
        Label label = new() { Text = message?.ToString() };

        vbox.AddChild(label);
        vbox.MoveChild(label, 0);

        if (vbox.GetChildCount() > MAX_LABELS_VISIBLE_AT_ONE_TIME)
        {
            vbox.RemoveChild(vbox.GetChild(vbox.GetChildCount() - 1));
        }

        _ = new GTween(label)
            .SetAnimatingProp(CanvasItem.PropertyName.Modulate)
            .AnimateProp(Colors.Transparent, fadeTime)
            .Callback(label.QueueFree);
    }
}
