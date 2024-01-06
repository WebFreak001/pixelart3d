module context;

import arsd.nanovega;
import arsd.simpledisplay;
import shapes;
import std.math;

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
		layout(window, ctx);
		ctx.translate(computedX, computedY);
		inner.draw(ctx);
	}

	bool pointerWithin(int mx, int my)
	{
		return mx >= computedX && mx <= computedX + inner.width
			&& my >= computedY && my <= computedY + inner.height;
	}

	static if (__traits(hasMember, T, "handleClick"))
		bool handleClick(int x, int y)
		{
			return inner.handleClick(x - computedX, y - computedY);
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

		layers.length++;
		width = 16;
		height = 16;
		palette = palettes.palettes["PixelArt 32"];
		layers[0].width = layers[0].height = 16;
		layers[0].data.length = 16 * 16;
		layers[0].data[1 + 1 * 16] = Pixel(5, 5, 2, 0);
		layers[0].data[2 + 1 * 16] = Pixel(4, 4, 2, 0);
		layers[0].data[3 + 1 * 16] = Pixel(3, 3, 2, 0);
		layers[0].data[1 + 2 * 16] = Pixel(5, 5, 2, 1);
		layers[0].data[1 + 3 * 16] = Pixel(5, 5, 2, 5);
		layers[0].data[1 + 4 * 16] = Pixel(5, 5, 2, 10);
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

	Container!Label filenameLabel = Container!Label(Align.Start, Align.End, 32, -32);
	Container!Label sizeLabel = Container!Label(Align.End, Align.End, -32, -32);
	Container!Toolbox toolbox = Container!Toolbox(Align.Start, Align.Middle, 32, 0);

	bool nanovegaInitialized;
	NVGPaint transparentPaint;

	@disable this();
	@disable this(this);

	this(NVGWindow window)
	{
		this.window = window;
		toolbox.initialize();
		loadImage();
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
			return;
		}
		else if (e.type == MouseEventType.buttonReleased)
		{
			mouseButtonStates[e.buttonLinear].dragging = false;
			if (e.button == MouseButton.left && mouseButtonStates[e.buttonLinear].qualifiesClick)
			{
				if (toolbox.pointerWithin(e.x, e.y) && toolbox.handleClick(e.x, e.y))
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
		ctx.resetTransform();

		filenameLabel.draw(window, ctx);
		sizeLabel.draw(window, ctx);
		toolbox.draw(window, ctx);
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
}

struct Toolbox
{
	enum renderSize = 20;
	enum gap = 4;

	int columns = 2;
	int width, height;
	int rotation;
	int selectedIndex;

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
		if (rotation >= countsLcm)
			rotation -= countsLcm;
		if (rotation < 0)
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
		if (i < 0 || i >= shapeStartIndices.length || selectedIndex == i)
			return false;

		selectedIndex = i;
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

			if (selectedIndex == i)
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

	size_t getShapeIndex(int idx) const
	{
		return shapeStartIndices[idx] + rotation % shapeCounts[idx];
	}

	const(Shape) getShape(int idx) const
	{
		return allShapes[getShapeIndex(idx)];
	}

	const(Shape) selectedShape() const
	{
		return getShape(selectedIndex);
	}
}

struct Label
{
	string text;
	int width, height;

	void layout(NVGWindow window, NVGContext ctx)
	{
		float[4] b = 0;
		ctx.textBounds(0, 0, text, b);
		width = cast(int) ceil(b[2]);
		height = cast(int) ceil(b[3]);
	}

	void draw(NVGContext ctx)
	{
		ctx.text(0, 0, text);
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
