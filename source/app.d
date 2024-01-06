import arsd.nanovega;
import arsd.simpledisplay;
import context;

void main()
{
	auto window = new NVGWindow(800, 600, "Pixelart3D");

	auto context = Context(window);
	context.window = window;

	window.redrawNVGScene = &context.redraw;
	window.handleMouseEvent = &context.handleMouseEvent;

	window.eventLoop(0,
		delegate(KeyEvent event) {
			if (event == "*-Q" || event == "Escape")
			{
				window.close();
				return;
			}
		},
	);
}
