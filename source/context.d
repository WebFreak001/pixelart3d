module context;

import arsd.nanovega;
import arsd.simpledisplay;
import std.algorithm;
import std.file;
import std.math;
import std.meta : AliasSeq;
import std.stdio;

import render3d;
import shapes;

struct Pixel
{
	ubyte color;
	ubyte backColor;
	ubyte depth;
	ubyte shape;

	enum invalid = Pixel(ubyte.max, ubyte.max, ubyte.max, ubyte.max);
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
					writefln!"layers[%s].data[%s + %s * %s] = %s;"(layerNo, i % layer
							.width, i / layer.width, layer.width, px);
				}
			}
		}
	}
}

struct Context
{
	NVGWindow window;
	Image image;
	Layer workingOverride;
	Guide[] guides;
	float viewOffsetX = 0;
	float viewOffsetY = 0;
	float zoom = 5.0f;
	int activeLayer = 0;

	auto filenameLabel = Container!Label(Align.Start, Align.End, 32, -32, Label(
			"ななひらさん大好き"));
	auto sizeLabel = Container!(FormattedLabel!("%d x %d", int, int))(
		Align.End, Align.End, -32, -32);
	auto shapebox = Container!Shapebox(Align.Start, Align.Middle, 32, 0);
	auto toolbox = Container!Toolbox(Align.Middle, Align.End, 0, -32);
	alias GUI = AliasSeq!(
		filenameLabel,
		sizeLabel,
		shapebox,
		toolbox
	);

	NVGPaint transparentPaint;
	Render3D render3d;

	@disable this();
	@disable this(this);

	this(NVGWindow window)
	{
		this.window = window;
		shapebox.initialize();
		loadImage();
		toolbox.palette.palette = image.palette;
	}

	void initNanovega(NVGContext ctx)
	{
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
				if (state.qualifiesClick && abs(e.x - state.dragStartX) + abs(
						e.y - state.dragStartY) > 8)
					state.qualifiesClick = false;
				else if (state.dragging && (btn == MouseButtonLinear.middle
						|| ((state.dragModifierState & ModifierState.alt) != 0
						&& (btn == MouseButtonLinear.left || btn == MouseButtonLinear
						.right))))
				{
					viewOffsetX += e.dx;
					viewOffsetY += e.dy;
					queueRedraw();
				}
				else if (state.dragging && focusControl == -1 && (btn == MouseButtonLinear.left || btn == MouseButtonLinear
						.right))
				{
					if (canvasDrawTo(e.x, e.y))
						queueRedraw();
				}
			}
		}
		else if (e.type == MouseEventType.buttonPressed && (
				e.button == MouseButton.wheelDown || e.button == MouseButton
				.wheelUp))
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
				shapebox.rotate(d);
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

			if (e.button == MouseButton.left && mouseButtonStates[e.buttonLinear]
				.qualifiesClick)
			{
				static foreach (control; GUI)
					if (control.pointerWithin(e.x, e.y) && control.handleClick(e
							.x, e.y))
						{
						queueRedraw();
						return;
					}
			}
		}
	}

	void handleKeyEvent(KeyEvent e)
	{
		if (e.pressed)
		{
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
			else if (auto rot = e.among("Left", "Up", "Right", "Down"))
			{
				shapebox.rotation = rot % 4;
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

	void redrawOpengl()
	{
		glViewport(64, 64, 256, 256);
		render3d.redraw(256, 256);
	}

	void redraw(NVGContext ctx)
	{
		redrawQueued = false;

		ctx.resetTransform();
		ctx.translate(window.width * 0.5f + viewOffsetX, window.height * 0.5f + viewOffsetY);
		double scale = pow(2.0, zoom);
		ctx.scale(scale, scale);
		ctx.translate(-image.width / 2.0f, -image.height / 2.0f);

		ctx.drawShadow(image.x, image.y + 0.2f, image.width, image.height, 0.2f, 3.0f, NVGColor(0, 0, 0, 0.5f));

		ctx.beginPath();
		ctx.roundedRect(image.x, image.y, image.width, image.height, 0.2f);
		ctx.strokeColor = NVGColor.white;
		ctx.strokeWidth = 0.2f;
		ctx.stroke();
		ctx.fillPaint = transparentPaint;
		ctx.fill();

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
		bool isActiveLayer = layerNo == activeLayer;

		for (int y = 0; y < layer.height; y++)
			for (int x = 0; x < layer.width; x++)
			{
				int tx = lx + x;
				int ty = ly + y;
				size_t index = y * layer.width + x;
				Pixel px = layer.data[index];

				if (isActiveLayer
					&& workingOverride.data.length == layer.data.length
					&& workingOverride.data[index] !is Pixel.invalid)
					px = workingOverride.data[index];

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

	bool canvasPainting;
	bool acquireCanvasPaintLock()
	{
		if (canvasPainting)
			return false;
		canvasPainting = true;
		return true;
	}

	int[2] canvasStart;
	bool canvasErase;
	Tool canvasTool;
	bool canvasStartStroke(int mx, int my, bool erase)
	{
		if (!acquireCanvasPaintLock())
			return false;

		workingOverride.x = image.layers[activeLayer].x;
		workingOverride.y = image.layers[activeLayer].y;
		workingOverride.width = image.layers[activeLayer].width;
		workingOverride.height = image.layers[activeLayer].height;
		if (workingOverride.data.length != image.layers[activeLayer].data.length)
		{
			workingOverride.data.length = image.layers[activeLayer].data.length;
			workingOverride.data[] = Pixel.invalid;
		}

		canvasErase = erase;
		canvasTool = toolbox.toolSelector.selected;
		canvasStart = mouseToImagePixels(mx, my);
		return canvasDrawTo(mx, my);
	}

	bool putCurrentPixel(int x, int y)
	{
		if (workingOverride.data.length != image.layers[activeLayer].data.length)
			return false;

		x -= workingOverride.x;
		y -= workingOverride.y;

		if (x < 0 || y < 0 || x >= workingOverride.width || y >= workingOverride.height)
			return false;

		size_t index = y * workingOverride.width + x;

		if (canvasTool == Tool.paint)
		{
			if (image.layers[activeLayer].data[index].color == 0)
				return false;
			workingOverride.data[index].shape =
				image.layers[activeLayer].data[index].shape;
		}
		else
		{
			workingOverride.data[index].shape = cast(ubyte) shapebox
				.selectedShapeId;
		}
		workingOverride.data[index].color = canvasErase ? 0 : cast(ubyte)(
			toolbox.palette.selected + 1);

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
		if (!canvasPainting)
			return false;

		auto end = mouseToImagePixels(mx, my);

		switch (canvasTool)
		{
		case Tool.draw:
		case Tool.paint:
			auto ret = drawLine(canvasStart[0], canvasStart[1], end[0], end[1]);
			canvasStart = end;
			return ret;
		case Tool.line:
			workingOverride.data[] = Pixel.invalid;
			return drawLine(canvasStart[0], canvasStart[1], end[0], end[1]);
		default:
			return false;
		}
	}

	bool canvasFinishStroke(int mx, int my)
	{
		canvasPainting = false;
		bool any = canvasDrawTo(mx, my);
		// TODO: undo stack
		foreach (i, px; workingOverride.data)
			if (px !is Pixel.invalid)
			{
				image.layers[activeLayer].data[i] = px;
				any = true;
			}
		workingOverride.data[] = Pixel.invalid;
		return any;
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

mixin template StackContainer(bool horizontal, bool backdrop, int gap, Align alignItems, Items...)
{
	enum lengthProp = horizontal ? "width" : "height";
	enum orthoProp = horizontal ? "height" : "width";
	enum axis = horizontal ? "x" : "y";
	enum orthoAxis = horizontal ? "y" : "x";

	int sumSize(string prop)() const @property
	{
		int ret;
		static foreach (i, Item; Items)
		{
			static if (i != 0)
				ret += gap;
			ret += __traits(getMember, Item, prop);
		}
		return ret;
	}

	int maxSize(string prop)() const @property
	{
		int ret;
		static foreach (i, Item; Items)
			if (__traits(getMember, Item, prop) > ret)
				ret = __traits(getMember, Item, prop);
		return ret;
	}

	static if (horizontal)
	{
		alias width = sumSize!"width";
		alias height = maxSize!"height";
	}
	else
	{
		alias width = maxSize!"width";
		alias height = sumSize!"height";
	}

	/// For horizontal layouts: y positions of members, otherwise x positions of members
	int[Items.length] orthoLayouts;

	bool handleClick(int x, int y)
	{
		int dim = -gap / 2;
		int offset = 0;
		static foreach (i, Item; Items)
		{
			offset = dim + gap / 2;
			dim += gap;
			dim += __traits(getMember, Item, lengthProp);
			if (mixin(axis) <= dim
				&& mixin(orthoAxis) >= orthoLayouts[i]
				&& mixin(orthoAxis) <= orthoLayouts[i] + __traits(getMember, Item, orthoProp))
			{
				static if (__traits(hasMember, Item, "handleClick"))
				{
					static if (horizontal)
						return Item.handleClick(x - offset, y - orthoLayouts[i]);
					else
						return Item.handleClick(x - orthoLayouts[i], y - offset);
				}
				else
					return false;
			}
		}
		return false;
	}

	void layout(NVGWindow window, NVGContext ctx)
	{
		static foreach (Item; Items)
			Item.layout(window, ctx);

		int width = this.width;
		int height = this.height;

		static if (alignItems == Align.Start)
			orthoLayouts[] = 0;
		else static if (alignItems == Align.End)
		{
			static foreach (i, Item; Items)
				orthoLayouts[i] = mixin(orthoProp) - __traits(getMember, Item, orthoProp);
		}
		else static if (alignItems == Align.Middle)
		{
			static foreach (i, Item; Items)
				orthoLayouts[i] = (mixin(orthoProp) - __traits(getMember, Item, orthoProp)) / 2;
		}
		else
			static assert(false);
	}

	void draw(NVGContext ctx)
	{
		static if (backdrop)
		{
			ctx.beginPath();
			ctx.roundedRect(-4, -4, width + 8, height + 8, 4);
			ctx.fillColor = NVGColor(0, 0, 0, 0.3);
			ctx.fill();
		}

		auto t = ctx.currTransform;
		int dim;
		static foreach (i, Item; Items)
		{
			ctx.currTransform = t;
			static if (horizontal)
				ctx.translate(dim, orthoLayouts[i]);
			else
				ctx.translate(orthoLayouts[i], dim);
			dim += __traits(getMember, Item, lengthProp) + gap;

			Item.draw(ctx);
		}
	}
}

struct Toolbox
{
	ToolSelector toolSelector;
	Palette palette;

	mixin StackContainer!(
		true,
		true,
		16,
		Align.Middle,
		toolSelector,
		palette
	);
}

enum Tool
{
	draw,
	line,
	paint,
	fill,
	rectSelect,
	wand,
}

struct ToolSelector
{
	enum renderSize = 42;

	int width, height;

	Tool selected;

	bool handleClick(int x, int y)
	{
		int i = x / renderSize;
		if (i < 0 || i > Tool.max)
			return false;

		selected = cast(Tool) i;
		return true;
	}

	void layout(NVGWindow window, NVGContext ctx)
	{
		height = renderSize;
		width = renderSize * (Tool.max + 1);
	}

	void draw(NVGContext ctx)
	{
		static foreach (tool; __traits(allMembers, Tool))
		{
			if (selected == __traits(getMember, Tool, tool))
			{
				ctx.beginPath();
				ctx.roundedRect(6, 6, 32, 32, 4);
				ctx.strokeWidth = 2;
				ctx.strokeColor = NVGColor.white;
				ctx.stroke();
			}

			drawTool!(__traits(getMember, Tool, tool))(ctx);
			ctx.translate(renderSize, 0);
		}
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

struct Shapebox
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
	/// Most likely this is `4` since shapes have at most 4 rotations and no 3-rot variants yet
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

void drawTool(Tool tool)(NVGContext ctx)
{
	ctx.translate(22, 22);
	scope (exit)
		ctx.translate(-22, -22);
	ctx.beginPath();
	final switch (tool)
	{
	case Tool.draw:
		ctx.moveTo(4, -8);
		ctx.lineTo(8, -4);
		ctx.lineTo(-2, 6);
		ctx.lineTo(-6, 2);

		ctx.moveTo(5, -9);
		ctx.lineTo(7, -11);
		ctx.lineTo(11, -7);
		ctx.lineTo(9, -5);

		ctx.moveTo(-7, 3);
		ctx.lineTo(-3, 7);
		ctx.lineTo(-12, 12);
		ctx.fillColor = NVGColor.white;
		ctx.fill();
		break;
	case Tool.line:
		ctx.moveTo(3, -5);
		ctx.lineTo(3, -10);
		ctx.lineTo(10, -10);
		ctx.lineTo(10, -3);
		ctx.lineTo(5, -3);

		ctx.lineTo(-3, 5);
		ctx.lineTo(-3, 10);
		ctx.lineTo(-10, 10);
		ctx.lineTo(-10, 3);
		ctx.lineTo(-5, 3);
		ctx.fillColor = NVGColor.white;
		ctx.fill();
		break;
	case Tool.paint:
		ctx.moveTo(-5, -5);
		ctx.lineTo(5, -15);

		ctx.lineTo(7, -13);
		ctx.lineTo(1, -7);
		ctx.lineTo(2, -6);
		ctx.lineTo(8, -12);
		ctx.lineTo(11, -9);
		ctx.lineTo(5, -3);
		ctx.lineTo(6, -2);
		ctx.lineTo(12, -8);

		ctx.lineTo(15, -5);
		ctx.lineTo(5, 5);
		ctx.lineTo(2, 2);
		ctx.lineTo(0, 2);
		ctx.lineTo(-2, 4);
		ctx.lineTo(-4, 8);
		ctx.lineTo(-6, 10);
		ctx.lineTo(-6.5, 10);
		ctx.bezierTo(-10, 20, -20, 10, -10, 6.5);
		ctx.lineTo(-10, 6);
		ctx.lineTo(-8, 4);
		ctx.lineTo(-4, 2);
		ctx.lineTo(-2, 0);
		ctx.lineTo(-2, -2);
		ctx.fillColor = NVGColor.white;
		ctx.fill();
		break;
	case Tool.fill:
		ctx.moveTo(0, -11);
		ctx.lineTo(11, 0);
		ctx.lineTo(13, 4);
		ctx.lineTo(11, 6);
		ctx.lineTo(9, 4);
		ctx.lineTo(9, 0);
		ctx.lineTo(-3, 12);
		ctx.lineTo(-13, 2);
		ctx.lineTo(-3, -8);
		ctx.lineTo(-7, -12);
		ctx.lineTo(-6, -13);
		ctx.lineTo(-2, -9);
		ctx.fillColor = NVGColor.white;
		ctx.fill();
		break;
	case Tool.rectSelect:
		ctx.rect(-10, -10, 20, 20);
		ctx.lineDash = [4, 4];
		ctx.lineDashStart = 2;
		ctx.strokeColor = NVGColor.white;
		ctx.strokeWidth = 2;
		ctx.stroke();
		ctx.lineDash = null;
		ctx.lineDashStart = 0;
		break;
	case Tool.wand:
		void star(int x, int y)
		{
			ctx.moveTo(x, y - 1);
			ctx.lineTo(x + 2, y - 2);
			ctx.lineTo(x + 1, y);
			ctx.lineTo(x + 2, y + 2);
			ctx.lineTo(x, y + 1);
			ctx.lineTo(x - 2, y + 2);
			ctx.lineTo(x - 1, y);
			ctx.lineTo(x - 2, y - 2);
		}
		ctx.moveTo(0, -5);
		ctx.lineTo(3, -2);
		ctx.lineTo(0, 1);
		ctx.lineTo(-3, -2);
		ctx.moveTo(-4, -1);
		ctx.lineTo(-1, 2);
		ctx.lineTo(-10, 11);
		ctx.lineTo(-13, 8);
		star(4, -9);
		star(12, -7);
		star(8, -1);
		ctx.fillColor = NVGColor.white;
		ctx.fill();
		break;
	}
}

void drawShadow(NVGContext ctx, float x, float y, float w, float h, float boxRadius, float blurRadius, NVGColor color)
{
	static struct Args
	{
		float w, h;
		float boxRadius;
		float blurRadius;
		NVGColor color;
	}

	auto args = Args(w, h, boxRadius, blurRadius, color);
	static NVGPaint[Args] paintDict;
	auto paint = paintDict.require(args, ctx.boxGradient(
		0, 0, w, h,
		boxRadius,
		blurRadius, color, NVGColor.transparent));

	auto t = ctx.currTransform;
	ctx.translate(x, y);
	ctx.beginPath();
	ctx.fillPaint = paint;
	ctx.rect(-blurRadius, -blurRadius, w + blurRadius * 2, h + blurRadius * 2);
	ctx.fill();
	ctx.currTransform = t;
}
