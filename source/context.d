module context;

import arsd.nanovega;
import arsd.simpledisplay;
import shapes;
import std.algorithm;
import std.file;
import std.math;
import std.meta : AliasSeq;
import std.stdio;

struct Pixel
{
	ubyte color;
	ubyte backColor;
	ubyte depth;
	ubyte shape;
}

struct Layer
{
	ushort width, height;
	short x, y;
	Pixel[] data;
}

struct Guide
{
	bool locked;
	bool horizontal;
	float d;
}

enum Align
{
	Start,
	Middle,
	End
}

struct Container(T)
{
	static assert(__traits(hasMember, T, "draw"),
		T.stringof ~ " must have a draw function, drawing to nanovega");
	static assert(__traits(hasMember, T, "layout"),
		T.stringof ~ " must have a layout function calculating width and height");
	static assert(__traits(hasMember, T, "width"),
		T.stringof ~ " must have width and height properties");
	static assert(__traits(hasMember, T, "height"),
		T.stringof ~ " must have width and height properties");

	Align xAlign, yAlign;
	int offsetX, offsetY;
	T inner;
	int computedX, computedY;
	bool canFocus = __traits(hasMember, T, "handleClick");

	alias inner this;

	void layout(NVGWindow window, NVGContext ctx)
	{
		inner.layout(window, ctx);
		computedX = computedY = 0;
		if (xAlign == Align.Middle)
			computedX = (cast(int)(window.width - inner.width)) / 2;
		else if (xAlign == Align.End)
			computedX = cast(int)(window.width - inner.width);

		if (yAlign == Align.Middle)
			computedY = (cast(int)(window.height - inner.height)) / 2;
		else if (yAlign == Align.End)
			computedY = cast(int)(window.height - inner.height);

		computedX += offsetX;
		computedY += offsetY;
	}

	void draw(NVGWindow window, NVGContext ctx)
	{
		ctx.resetTransform();
		layout(window, ctx);
		ctx.translate(computedX, computedY);
		inner.draw(ctx);
	}

	bool pointerWithin(int mx, int my)
	{
		return mx >= computedX && mx <= computedX + inner.width
			&& my >= computedY && my <= computedY + inner.height;
	}

	bool handleClick(int x, int y)
	{
		static if (__traits(hasMember, T, "handleClick"))
			return inner.handleClick(x - computedX, y - computedY);
		else
			return false;
	}
}

struct Image
{
	ushort x, y, width, height;
	// 0 is always transparent, this array starts indexing at 1
	uint[] palette;
	Layer[] layers;

	void loadSample()
	{
		import palettes;
		palette = palettes.palettes["PixelArt 32"];

		layers.length = 1;
		width = 16;
		height = 16;
		layers[0].width = 16;
		layers[0].height = 16;
		layers[0].data.length = 16 * 16;
		layers[0].data[1 + 7 * 16] = Pixel(7, 0, 2, 3);
		layers[0].data[2 + 7 * 16] = Pixel(7, 0, 2, 4);
		layers[0].data[4 + 7 * 16] = Pixel(7, 0, 2, 3);
		layers[0].data[5 + 7 * 16] = Pixel(7, 0, 2, 4);
		layers[0].data[7 + 7 * 16] = Pixel(7, 0, 2, 3);
		layers[0].data[8 + 7 * 16] = Pixel(7, 0, 2, 4);
		layers[0].data[10 + 7 * 16] = Pixel(7, 0, 2, 3);
		layers[0].data[11 + 7 * 16] = Pixel(7, 0, 2, 4);
		layers[0].data[13 + 7 * 16] = Pixel(7, 0, 2, 3);
		layers[0].data[14 + 7 * 16] = Pixel(7, 0, 2, 4);
		layers[0].data[1 + 8 * 16] = Pixel(7, 0, 2, 0);
		layers[0].data[2 + 8 * 16] = Pixel(7, 0, 2, 0);
		layers[0].data[4 + 8 * 16] = Pixel(7, 0, 2, 0);
		layers[0].data[5 + 8 * 16] = Pixel(7, 0, 2, 0);
		layers[0].data[7 + 8 * 16] = Pixel(7, 0, 2, 0);
		layers[0].data[8 + 8 * 16] = Pixel(7, 0, 2, 0);
		layers[0].data[10 + 8 * 16] = Pixel(7, 0, 2, 0);
		layers[0].data[11 + 8 * 16] = Pixel(7, 0, 2, 0);
		layers[0].data[13 + 8 * 16] = Pixel(7, 0, 2, 0);
		layers[0].data[14 + 8 * 16] = Pixel(7, 0, 2, 0);
		layers[0].data[0 + 9 * 16] = Pixel(5, 0, 1, 50);
		layers[0].data[1 + 9 * 16] = Pixel(7, 0, 2, 0);
		layers[0].data[2 + 9 * 16] = Pixel(7, 0, 2, 0);
		layers[0].data[3 + 9 * 16] = Pixel(5, 0, 1, 0);
		layers[0].data[4 + 9 * 16] = Pixel(7, 0, 2, 0);
		layers[0].data[5 + 9 * 16] = Pixel(7, 0, 2, 0);
		layers[0].data[6 + 9 * 16] = Pixel(5, 0, 1, 0);
		layers[0].data[7 + 9 * 16] = Pixel(7, 0, 2, 0);
		layers[0].data[8 + 9 * 16] = Pixel(7, 0, 2, 0);
		layers[0].data[9 + 9 * 16] = Pixel(5, 0, 1, 0);
		layers[0].data[10 + 9 * 16] = Pixel(7, 0, 2, 0);
		layers[0].data[11 + 9 * 16] = Pixel(7, 0, 2, 0);
		layers[0].data[12 + 9 * 16] = Pixel(5, 0, 1, 0);
		layers[0].data[13 + 9 * 16] = Pixel(7, 0, 2, 0);
		layers[0].data[14 + 9 * 16] = Pixel(7, 0, 2, 0);
		layers[0].data[15 + 9 * 16] = Pixel(5, 0, 1, 52);
		layers[0].data[1 + 10 * 16] = Pixel(7, 0, 2, 0);
		layers[0].data[2 + 10 * 16] = Pixel(7, 0, 2, 0);
		layers[0].data[4 + 10 * 16] = Pixel(7, 0, 2, 0);
		layers[0].data[5 + 10 * 16] = Pixel(7, 0, 2, 0);
		layers[0].data[7 + 10 * 16] = Pixel(7, 0, 2, 0);
		layers[0].data[8 + 10 * 16] = Pixel(7, 0, 2, 0);
		layers[0].data[10 + 10 * 16] = Pixel(7, 0, 2, 0);
		layers[0].data[11 + 10 * 16] = Pixel(7, 0, 2, 0);
		layers[0].data[13 + 10 * 16] = Pixel(7, 0, 2, 0);
		layers[0].data[14 + 10 * 16] = Pixel(7, 0, 2, 0);
		layers[0].data[0 + 11 * 16] = Pixel(5, 0, 1, 50);
		layers[0].data[1 + 11 * 16] = Pixel(7, 0, 2, 0);
		layers[0].data[2 + 11 * 16] = Pixel(7, 0, 2, 0);
		layers[0].data[3 + 11 * 16] = Pixel(5, 0, 1, 0);
		layers[0].data[4 + 11 * 16] = Pixel(7, 0, 2, 0);
		layers[0].data[5 + 11 * 16] = Pixel(7, 0, 2, 0);
		layers[0].data[6 + 11 * 16] = Pixel(5, 0, 1, 0);
		layers[0].data[7 + 11 * 16] = Pixel(7, 0, 2, 0);
		layers[0].data[8 + 11 * 16] = Pixel(7, 0, 2, 0);
		layers[0].data[9 + 11 * 16] = Pixel(5, 0, 1, 0);
		layers[0].data[10 + 11 * 16] = Pixel(7, 0, 2, 0);
		layers[0].data[11 + 11 * 16] = Pixel(7, 0, 2, 0);
		layers[0].data[12 + 11 * 16] = Pixel(5, 0, 1, 0);
		layers[0].data[13 + 11 * 16] = Pixel(7, 0, 2, 0);
		layers[0].data[14 + 11 * 16] = Pixel(7, 0, 2, 0);
		layers[0].data[15 + 11 * 16] = Pixel(5, 0, 1, 52);
		layers[0].data[1 + 12 * 16] = Pixel(7, 0, 2, 0);
		layers[0].data[2 + 12 * 16] = Pixel(7, 0, 2, 0);
		layers[0].data[4 + 12 * 16] = Pixel(7, 0, 2, 0);
		layers[0].data[5 + 12 * 16] = Pixel(7, 0, 2, 0);
		layers[0].data[7 + 12 * 16] = Pixel(7, 0, 2, 0);
		layers[0].data[8 + 12 * 16] = Pixel(7, 0, 2, 0);
		layers[0].data[10 + 12 * 16] = Pixel(7, 0, 2, 0);
		layers[0].data[11 + 12 * 16] = Pixel(7, 0, 2, 0);
		layers[0].data[13 + 12 * 16] = Pixel(7, 0, 2, 0);
		layers[0].data[14 + 12 * 16] = Pixel(7, 0, 2, 0);
		layers[0].data[1 + 13 * 16] = Pixel(5, 0, 2, 0);
		layers[0].data[2 + 13 * 16] = Pixel(5, 0, 2, 0);
		layers[0].data[4 + 13 * 16] = Pixel(5, 0, 2, 0);
		layers[0].data[5 + 13 * 16] = Pixel(5, 0, 2, 0);
		layers[0].data[7 + 13 * 16] = Pixel(5, 0, 2, 0);
		layers[0].data[8 + 13 * 16] = Pixel(5, 0, 2, 0);
		layers[0].data[10 + 13 * 16] = Pixel(5, 0, 2, 0);
		layers[0].data[11 + 13 * 16] = Pixel(5, 0, 2, 0);
		layers[0].data[13 + 13 * 16] = Pixel(5, 0, 2, 0);
		layers[0].data[14 + 13 * 16] = Pixel(5, 0, 2, 0);
		layers[0].data[0 + 14 * 16] = Pixel(23, 0, 4, 7);
		layers[0].data[1 + 14 * 16] = Pixel(23, 0, 4, 0);
		layers[0].data[2 + 14 * 16] = Pixel(23, 0, 4, 0);
		layers[0].data[3 + 14 * 16] = Pixel(23, 0, 4, 0);
		layers[0].data[4 + 14 * 16] = Pixel(23, 0, 4, 0);
		layers[0].data[5 + 14 * 16] = Pixel(23, 0, 4, 0);
		layers[0].data[6 + 14 * 16] = Pixel(23, 0, 4, 0);
		layers[0].data[7 + 14 * 16] = Pixel(23, 0, 4, 0);
		layers[0].data[8 + 14 * 16] = Pixel(23, 0, 4, 0);
		layers[0].data[9 + 14 * 16] = Pixel(23, 0, 4, 0);
		layers[0].data[10 + 14 * 16] = Pixel(23, 0, 4, 0);
		layers[0].data[11 + 14 * 16] = Pixel(23, 0, 4, 0);
		layers[0].data[12 + 14 * 16] = Pixel(23, 0, 4, 0);
		layers[0].data[13 + 14 * 16] = Pixel(23, 0, 4, 0);
		layers[0].data[14 + 14 * 16] = Pixel(23, 0, 4, 0);
		layers[0].data[15 + 14 * 16] = Pixel(23, 0, 4, 8);
		layers[0].data[0 + 15 * 16] = Pixel(23, 0, 4, 0);
		layers[0].data[1 + 15 * 16] = Pixel(23, 0, 4, 0);
		layers[0].data[2 + 15 * 16] = Pixel(23, 0, 4, 0);
		layers[0].data[3 + 15 * 16] = Pixel(23, 0, 4, 0);
		layers[0].data[4 + 15 * 16] = Pixel(23, 0, 4, 0);
		layers[0].data[5 + 15 * 16] = Pixel(23, 0, 4, 0);
		layers[0].data[6 + 15 * 16] = Pixel(23, 0, 4, 0);
		layers[0].data[7 + 15 * 16] = Pixel(23, 0, 4, 0);
		layers[0].data[8 + 15 * 16] = Pixel(23, 0, 4, 0);
		layers[0].data[9 + 15 * 16] = Pixel(23, 0, 4, 0);
		layers[0].data[10 + 15 * 16] = Pixel(23, 0, 4, 0);
		layers[0].data[11 + 15 * 16] = Pixel(23, 0, 4, 0);
		layers[0].data[12 + 15 * 16] = Pixel(23, 0, 4, 0);
		layers[0].data[13 + 15 * 16] = Pixel(23, 0, 4, 0);
		layers[0].data[14 + 15 * 16] = Pixel(23, 0, 4, 0);
		layers[0].data[15 + 15 * 16] = Pixel(23, 0, 4, 0);
	}

	void saveDebug()
	{
		writefln!"layers.length = %s;"(layers.length);
		writefln!"width = %s;"(width);
		writefln!"height = %s;"(height);
		foreach (layerNo, layer; layers)
		{
			writefln!"layers[%s].width = %s;"(layerNo, width);
			writefln!"layers[%s].height = %s;"(layerNo, height);
			writefln!"layers[%s].data.length = %s * %s;"(layerNo, width, height);
			foreach (i, px; layer.data)
			{
				if (px.color != 0)
				{
					writefln!"layers[%s].data[%s + %s * %s] = %s;"(layerNo, i % layer.width, i / layer.width, layer.width, px);
				}
			}
		}
	}
}

struct Context
{
	NVGWindow window;
	Image image;
	Guide[] guides;
	float viewOffsetX = 0;
	float viewOffsetY = 0;
	float zoom = 5.0f;
	int activeLayer = 0;

	auto filenameLabel = Container!Label(Align.Start, Align.End, 32, -32, Label("ななひらさん大好き"));
	auto sizeLabel = Container!(FormattedLabel!("%d x %d", int, int))(Align.End, Align.End, -32, -32);
	auto toolbox = Container!Toolbox(Align.Start, Align.Middle, 32, 0);
	auto palette = Container!Palette(Align.Middle, Align.End, 0, -32);
	alias GUI = AliasSeq!(
		filenameLabel,
		sizeLabel,
		toolbox,
		palette
	);

	bool nanovegaInitialized;
	NVGPaint transparentPaint;

	@disable this();
	@disable this(this);

	this(NVGWindow window)
	{
		this.window = window;
		toolbox.initialize();
		loadImage();
		palette.palette = image.palette;
	}

	void initNanovega(NVGContext ctx)
	{
		if (nanovegaInitialized)
			return;
		nanovegaInitialized = true;

		static immutable uint[4] transparentColors = [
			0xffffffff,
			0xffeeeeee,
			0xffeeeeee,
			0xffffffff,
		];
		NVGImage transparentImage = ctx.createImageRGBA(2, 2, transparentColors[], NVGImageFlag.NoFiltering | NVGImageFlag
				.RepeatX | NVGImageFlag.RepeatY);
		transparentPaint = ctx.imagePattern(0, 0, 2, 2, 0, transparentImage);

		auto font = ctx.createFont("JetBrains Mono", "fonts/JetBrainsMono/JetBrainsMono-Bold.ttf");
		if (font == -1)
			assert(false, "Failed to load font");

		foreach (fallbackPath; [
			"fonts/NotoSans-Japanese/NotoSansJP-Bold.ttf",
		])
		{
			auto fallback = ctx.createFont("fallback", fallbackPath);
			if (fallback == -1)
			{
				stderr.writeln("Failed to load font ", fallbackPath);
				continue;
			}
			ctx.addFallbackFont(font, fallback);
			stderr.writeln("loaded fallback font ", fallbackPath);
		}

		ctx.fontFaceId = font;
	}

	void loadImage()
	{
		image.loadSample();
		guides = [
			Guide(true, true, image.width / 2.0f),
			Guide(true, false, image.height / 2.0f),
		];
	}

	struct MouseState
	{
		bool dragging;
		int dragStartX, dragStartY;
		int dragModifierState;
		bool qualifiesClick;
	}
	MouseState[16] mouseButtonStates;
	int focusControl = -1;
	void handleMouseEvent(MouseEvent e)
	{
		if (e.type == MouseEventType.motion)
		{
			foreach (btn, ref state; mouseButtonStates)
			{
				if (state.qualifiesClick && abs(e.x - state.dragStartX) + abs(e.y - state.dragStartY) > 8)
					state.qualifiesClick = false;
				else if (state.dragging && (btn == MouseButtonLinear.middle
					|| ((state.dragModifierState & ModifierState.alt) != 0
						&& (btn == MouseButtonLinear.left || btn == MouseButtonLinear.right))))
				{
					viewOffsetX += e.dx;
					viewOffsetY += e.dy;
					queueRedraw();
				}
				else if (state.dragging && focusControl == -1 && (btn == MouseButtonLinear.left || btn == MouseButtonLinear.right))
				{
					if (canvasDrawTo(e.x, e.y))
						queueRedraw();
				}
			}
		}
		else if (e.type == MouseEventType.buttonPressed && (e.button == MouseButton.wheelDown || e.button == MouseButton.wheelUp))
		{
			int d = e.button == MouseButton.wheelDown ? 1 : -1;
			if ((e.modifierState & ModifierState.ctrl) != 0)
			{
				zoom -= d * 0.25;
				zoom = round(zoom * 4) / 4.0;
				if (zoom <= 0.25)
					zoom = 0.25;
				else if (zoom >= 8.0)
					zoom = 8.0;
				queueRedraw();
			}
			else
			{
				toolbox.rotate(d);
				queueRedraw();
			}
		}
		else if (e.type == MouseEventType.buttonPressed)
		{
			mouseButtonStates[e.buttonLinear].dragging = true;
			mouseButtonStates[e.buttonLinear].dragStartX = e.x;
			mouseButtonStates[e.buttonLinear].dragStartY = e.y;
			mouseButtonStates[e.buttonLinear].qualifiesClick = true;
			mouseButtonStates[e.buttonLinear].dragModifierState = e.modifierState;

			if (e.button == MouseButton.left || e.button == MouseButton.right)
			{
				focusControl = -1;
				static foreach (i, control; GUI)
					if (control.pointerWithin(e.x, e.y) && control.canFocus)
					{
						focusControl = i;
						return;
					}

				assert(focusControl == -1, "logic bug! should have returned above");

				if (canvasStartStroke(e.x, e.y, e.button == MouseButton.right))
					queueRedraw();
			}
		}
		else if (e.type == MouseEventType.buttonReleased)
		{
			mouseButtonStates[e.buttonLinear].dragging = false;

			if ((e.button == MouseButton.left || e.button == MouseButton.right) && focusControl == -1)
				if (canvasFinishStroke(e.x, e.y))
					queueRedraw();

			if (e.button == MouseButton.left && mouseButtonStates[e.buttonLinear].qualifiesClick)
			{
				static foreach (control; GUI)
					if (control.pointerWithin(e.x, e.y) && control.handleClick(e.x, e.y))
					{
						queueRedraw();
						return;
					}
			}
		}
	}

	void handleKeyEvent(KeyEvent e)
	{
		if (e.pressed) {
			if (e == "Ctrl-S")
			{
				image.saveDebug();
			}
			else if (e == "Home")
			{
				viewOffsetX = 0;
				viewOffsetY = 0;
				zoom = 5.0f;
				queueRedraw();
			}
		}
	}

	bool redrawQueued;
	void queueRedraw()
	{
		if (redrawQueued)
			return;
		redrawQueued = true;
		window.redrawOpenGlSceneSoon();
	}

	void redraw(NVGContext ctx)
	{
		redrawQueued = false;

		glClearColor(0.2f, 0.2f, 0.22f, 1.0f);
		glClear(GL_COLOR_BUFFER_BIT);

		initNanovega(ctx);

		ctx.resetTransform();
		ctx.translate(window.width * 0.5f + viewOffsetX, window.height * 0.5f + viewOffsetY);
		double scale = pow(2.0, zoom);
		ctx.scale(scale, scale);
		ctx.translate(-image.width / 2.0f, -image.height / 2.0f);

		ctx.beginPath();
		ctx.roundedRect(image.x, image.y, image.width, image.height, 0.2f);
		ctx.fillPaint = transparentPaint;
		ctx.fill();
		ctx.strokeColor = NVGColor.white;
		ctx.strokeWidth = 0.1f;
		ctx.stroke();

		const px = 1.0f / scale;

		foreach (layer; 0 .. image.layers.length)
			renderLayer(layer, ctx);

		if (guides.length)
		{
			ctx.beginPath();
			foreach (guide; guides)
			{
				if (guide.horizontal)
				{
					ctx.moveTo(0, guide.d + 0.5 * px);
					ctx.lineTo(image.width, guide.d + 0.5 * px);
				}
				else
				{
					ctx.moveTo(guide.d + 0.5 * px, 0);
					ctx.lineTo(guide.d + 0.5 * px, image.height);
				}
			}
			ctx.strokeColor = NVGColor(0.5f, 0.5f, 0.5f, 0.5f);
			ctx.strokeWidth = 1 * px;

			ctx.stroke();
		}

		renderInterface(ctx);
	}

	void renderInterface(NVGContext ctx)
	{
		sizeLabel.reformatIfNeeded(image.width, image.height);
		static foreach (control; GUI)
			control.draw(window, ctx);
	}

	void renderLayer(size_t layerNo, NVGContext ctx)
	{
		auto layer = image.layers[layerNo];
		int lx = layer.x;
		int ly = layer.y;

		for (int y = 0; y < layer.height; y++)
			for (int x = 0; x < layer.width; x++)
			{
				int tx = lx + x;
				int ty = ly + y;
				Pixel px = layer.data[y * layer.width + x];

				if (px.color == 0)
					continue;

				auto m = ctx.currTransform;
				ctx.translate(tx, ty);
				ctx.scissor(0, 0, 1, 1);
				ctx.beginPath();
				ctx.drawShape(allShapes[px.shape]);
				ctx.fillColor = NVGColor(image.palette[px.color - 1]);
				ctx.fill();
				ctx.resetScissor();
				ctx.currTransform = m;
			}
	}

	int[2] canvasStart;
	bool canvasErase;
	bool canvasStartStroke(int mx, int my, bool erase)
	{
		canvasErase = erase;
		canvasStart = mouseToImagePixels(mx, my);
		return canvasDrawTo(mx, my);
	}

	bool putCurrentPixel(int x, int y)
	{
		auto layer = &image.layers[activeLayer];

		x -= layer.x;
		y -= layer.y;

		if (x < 0 || y < 0 || x >= layer.width || y >= layer.height)
			return false;

		layer.data[y * layer.width + x].shape = cast(ubyte) toolbox.selectedShapeId;
		layer.data[y * layer.width + x].color = canvasErase ? 0 : cast(ubyte)(palette.selected + 1);

		return true;
	}

	bool drawLine(int x0, int y0, int x1, int y1)
	{
		// https://en.wikipedia.org/wiki/Bresenham%27s_line_algorithm
		int dx = abs(x1 - x0);
		int sx = x0 < x1 ? 1 : -1;
		int dy = -abs(y1 - y0);
		int sy = y0 < y1 ? 1 : -1;
		int error = dx + dy;
		bool updated;

		while (true)
		{
			if (putCurrentPixel(x0, y0))
				updated = true;

			if (x0 == x1 && y0 == y1)
				break;
			int e2 = 2 * error;
			if (e2 >= dy)
			{
				if (x0 == x1)
					break;
				error += dy;
				x0 += sx;
			}
			if (e2 <= dx)
			{
				if (y0 == y1)
					break;
				error += dx;
				y0 += sy;
			}
		}

		return updated;
	}

	bool canvasDrawTo(int mx, int my)
	{
		auto end = mouseToImagePixels(mx, my);
		scope (exit) canvasStart = end;
		return drawLine(canvasStart[0], canvasStart[1], end[0], end[1]);
	}

	bool canvasFinishStroke(int mx, int my)
	{
		return canvasDrawTo(mx, my);
		// TODO: undo stack
	}

	int[2] mouseToImagePixels(int mx, int my)
	{
		float x = mx;
		float y = my;
		x -= window.width * 0.5f + viewOffsetX;
		y -= window.height * 0.5f + viewOffsetY;
		double scale = pow(2.0, zoom);
		x /= scale;
		y /= scale;
		x -= -image.width / 2.0f;
		y -= -image.height / 2.0f;
		return [
			cast(int) floor(x),
			cast(int) floor(y),
		];
	}
}
struct Palette
{
	enum renderSize = 20;
	enum gap = 2;

	int rows = 2;
	int width, height;

	uint[] palette;
	int selected;

	void rotate(int amount)
	{
		selected += amount;
		while (selected >= palette.length)
			selected -= palette.length;
		while (selected < 0)
			selected += palette.length;
	}

	bool handleClick(int x, int y)
	{
		int gx = (x + gap / 2) / (renderSize + gap);
		int gy = (y + gap / 2) / (renderSize + gap);
		if (gy < 0)
			gy = 0;
		if (gy >= rows)
			gy = rows - 1;

		int i = gx * rows + gy;
		if (i < 0 || i >= palette.length || selected == i)
			return false;

		selected = i;
		return true;
	}

	void layout(NVGWindow window, NVGContext ctx)
	{
		int columns = cast(int)(palette.length + rows - 1) / rows;
		height = rows * renderSize + gap * (rows - 1);
		width = columns * renderSize + gap * (columns - 1);
	}

	void draw(NVGContext ctx)
	{
		int x = 0;
		int y = -1;
		auto t = ctx.currTransform;
		ctx.beginPath();
		ctx.roundedRect(-4, -4, width + 8, height + 8, 4);
		ctx.fillColor = NVGColor(0, 0, 0, 0.3);
		ctx.fill();
		int[2] selectedPos;

		foreach (i; 0 .. cast(int) palette.length)
		{
			y++;
			if (y == rows)
			{
				y = 0;
				x++;
			}
			ctx.currTransform = t;
			ctx.translate(
				x * (renderSize + gap),
				y * (renderSize + gap)
			);
			ctx.scale(renderSize, renderSize);

			if (selected == i)
				selectedPos = [x, y];

			ctx.scissor(0, 0, 1, 1);
			ctx.beginPath();
			ctx.roundedRect(0, 0, 1, 1, 0.2);
			ctx.fillColor = NVGColor(palette[i]);
			ctx.fill();
			ctx.resetScissor();
		}

		{
			ctx.currTransform = t;
			ctx.translate(
				selectedPos[0] * (renderSize + gap),
				selectedPos[1] * (renderSize + gap)
			);
			ctx.scale(renderSize, renderSize);

			ctx.beginPath();
			ctx.roundedRect(-0.1, -0.1, 1.2, 1.2, 0.3);
			ctx.strokeWidth = 0.1;
			ctx.strokeColor = NVGColor.white;
			ctx.stroke();
		}
	}

	uint activeColor() const
	{
		return palette[selected];
	}
}

struct Toolbox
{
	enum renderSize = 20;
	enum gap = 4;

	int columns = 2;
	int width, height;
	int rotation;
	int selectedGroup;

	int[] shapeStartIndices;
	int[] shapeCounts;
	/// least common multiple of shape counts - used to clamp rotation
	/// Most likely this is `4` since tools have at most 4 rotations and no 3-rot variants yet
	int countsLcm;

	void initialize()
	{
		import std.numeric : lcm;

		for (int i = 0; i < allShapes.length; i++)
			if (i == 0 || allShapes[i].name != allShapes[i - 1].name)
			{
				if (i != 0)
					shapeCounts ~= i - shapeStartIndices[$ - 1];
				shapeStartIndices ~= i;
			}

		shapeCounts ~= cast(int)(allShapes.length - shapeStartIndices[$ - 1]);

		// essentially this will always be 4:
		countsLcm = shapeCounts[0];
		foreach (c; shapeCounts[1 .. $])
			countsLcm = lcm(c, countsLcm);
	}

	void rotate(int amount)
	{
		rotation += amount;
		while (rotation >= countsLcm)
			rotation -= countsLcm;
		while (rotation < 0)
			rotation += countsLcm;
	}

	bool handleClick(int x, int y)
	{
		int gx = (x + gap / 2) / (renderSize + gap);
		int gy = (y + gap / 2) / (renderSize + gap);
		if (gx < 0)
			gx = 0;
		if (gx >= columns)
			gx = columns - 1;

		int i = gy * columns + gx;
		if (i < 0 || i >= shapeStartIndices.length || selectedGroup == i)
			return false;

		selectedGroup = i;
		return true;
	}

	void layout(NVGWindow window, NVGContext ctx)
	{
		width = columns * renderSize + gap * (columns - 1);
		int rows = cast(int)(shapeStartIndices.length + columns - 1) / columns;
		height = rows * renderSize + gap * (rows - 1);
	}

	void draw(NVGContext ctx)
	{
		int x = -1;
		int y = 0;
		auto t = ctx.currTransform;
		ctx.beginPath();
		ctx.roundedRect(-8, -8, width + 16, height + 16, 4);
		ctx.fillColor = NVGColor(0, 0, 0, 0.3);
		ctx.fill();
		foreach (i; 0 .. cast(int) shapeStartIndices.length)
		{
			x++;
			if (x == columns)
			{
				x = 0;
				y++;
			}
			ctx.currTransform = t;
			ctx.translate(
				x * (renderSize + gap),
				y * (renderSize + gap)
			);
			ctx.scale(renderSize, renderSize);

			if (selectedGroup == i)
			{
				ctx.beginPath();
				ctx.roundedRect(-0.1, -0.1, 1.2, 1.2, 0.1);
				ctx.strokeWidth = 0.1;
				ctx.strokeColor = NVGColor.orange;
				ctx.stroke();
			}

			ctx.scissor(0, 0, 1, 1);
			ctx.beginPath();
			ctx.drawShape(getShape(i));
			ctx.fillColor = NVGColor.white;
			ctx.fill();
			ctx.resetScissor();
		}
	}

	size_t getActiveShapeId(int group) const
	{
		return shapeStartIndices[group] + rotation % shapeCounts[group];
	}

	const(Shape) getShape(int group) const
	{
		return allShapes[getActiveShapeId(group)];
	}

	const(Shape) selectedShape() const
	{
		return getShape(selectedGroup);
	}

	size_t selectedShapeId() const
	{
		return getActiveShapeId(selectedGroup);
	}
}

struct FormattedLabel(string formatString, Args...)
{
	import std.format;

	Label label;
	alias label this;
	Args lastArgs;

	void reformatIfNeeded(Args args)
	{
		if (lastArgs == args)
			return;
		lastArgs = args;
		label.text = format!formatString(args);
	}
}

struct Label
{
	string text;
	int width, height;
	float fontSize = 20.0;

	void layout(NVGWindow window, NVGContext ctx)
	{
		float[4] b = 0;
		ctx.fontSize = 20;
		ctx.textBounds(0, 0, text, b);
		width = cast(int) ceil(b[2]);
		height = cast(int) ceil(b[3]);
	}

	void draw(NVGContext ctx)
	{
		ctx.fontSize = 20;
		ctx.fillColor = NVGColor.white;
		ctx.text(0, height, text);
	}
}

void drawShape(NVGContext ctx, const(Shape) shape)
{
	foreach (i, v; shape.vertices)
	{
		if (shape.isMoveTo[i])
			ctx.moveTo(v[0], v[1]);
		else
			ctx.lineTo(v[0], v[1]);
	}
}
