import arsd.nanovega;
import arsd.simpledisplay : gl3, openGLContextCompatible, setOpenGLContextVersion;
import bindbc.opengl;
import context;
import dump_shapes;
import std.stdio;

void main(string[] args)
{
	if (args.length == 2 && args[1] == "--dump")
	{
		dump_shapes.dump_shapes();
		return;
	}

	setOpenGLContextVersion(3, 3);
	openGLContextCompatible = false;

	auto window = new NVGWindow(800, 600, "Pixelart3D");

	auto context = Context(window);
	context.window = window;

	auto nvgInit = window.visibleForTheFirstTime;
	window.visibleForTheFirstTime = delegate() {
		window.setAsCurrentOpenGlContext;
		gl3.loadDynamicLibrary();

		if (!loadOpenGL())
			throw new Exception("Failed to load OpenGL");

		context.render3d.setupContext();

		nvgInit();
		window.nvg.beginFrame(1, 1); // start frame to setup nanovega stuffs
		context.initNanovega(window.nvg);
		window.nvg.endFrame();
	};

	window.clearOnEachFrame = false;
	window.redrawNVGScene = &context.redraw;
	auto nvgRedraw = window.redrawOpenGlScene;
	window.redrawOpenGlScene = {
		glClearColor(0.2f, 0.2f, 0.22f, 1.0f);
		glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT | GL_STENCIL_BUFFER_BIT);

		nvgRedraw();
		context.redrawOpengl();
	};
	window.handleMouseEvent = &context.handleMouseEvent;
	window.handleKeyEvent = &context.handleKeyEvent;

	window.eventLoop(0);
}
