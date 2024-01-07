import arsd.nanovega;
import arsd.simpledisplay;
import dump_shapes;
import context;

void main(string[] args)
{
	if (args.length == 2 && args[1] == "--dump")
	{
		dump_shapes.dump_shapes();
		return;
	}

	auto window = new NVGWindow(800, 600, "Pixelart3D");

	auto context = Context(window);
	context.window = window;

	window.redrawNVGScene = &context.redraw;
	window.handleMouseEvent = &context.handleMouseEvent;
	window.handleKeyEvent = &context.handleKeyEvent;

	window.eventLoop(0);
}
