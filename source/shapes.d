module shapes;

import std.algorithm;
import std.bitmanip : BitArray;
import std.conv;
import std.math;
import std.string;

import earcut_ctfe;

enum Side
{
	left,
	top,
	right,
	bottom
}

enum arc_resolution = 10;

struct Shape
{
	string name;
	double[2][] vertices;
	ushort[] rawIndices;
	BitArray isMoveTo;
	bool[4] sidesClosed;
	bool reverseIndices;

	/// Implicitly starts at 0 0 and closes the path.
	static Shape fromSVG(return string name, scope const(char)[] path)
	{
		import svg_arc;

		auto remaining = path.splitter;

		Shape ret;
		ret.name = name;

		double nextFloat()
		{
			double f;
			if (remaining.front == "SQRT3-1")
				f = sqrt(3.0) - 1.0;
			else
				f = remaining.front.to!double;
			remaining.popFront;
			return f;
		}

		bool nextBool()
		{
			auto v = remaining.front;
			remaining.popFront;
			if (v == "0")
				return false;
			else if (v == "1")
				return true;
			else
				throw new Exception("Expected 0 or 1, but got " ~ v.idup);
		}

		double x = 0, y = 0;
		double[2][] polygon = [[x, y]];

		void addPoint(double x, double y)
		{
			if (vectorLength(cast(double[2]) [x - polygon[$ - 1][0], y - polygon[$ - 1][1]]) <= 0.01)
				return;
			polygon ~= [round(x * 10000) / 10000, round(y * 10000) / 10000];
		}

		void close()
		{
			if (polygon.length == 1)
			{
				polygon[0] = [x, y];
				return;
			}

			Earcut!(ushort, typeof(polygon)[]) earcut;
			double[2][][] area = [polygon];
			earcut.run(area);
			ret.vertices ~= polygon;
			ret.isMoveTo ~= true;
			foreach (i; 0 .. polygon.length - 1)
				ret.isMoveTo ~= false;
			if (ret.rawIndices.length)
				earcut.indices[] += cast(ushort) ret.rawIndices.length;
			ret.rawIndices ~= earcut.indices;
			polygon = [[x, y]];
		}

		while (!remaining.empty)
		{
			auto cmd = remaining.front;
			remaining.popFront;
			switch (cmd)
			{
			case "M":
				close();
				polygon[0][0] = x = nextFloat;
				polygon[0][1] = y = nextFloat;
				break;
			case "m":
				close();
				x += nextFloat;
				y += nextFloat;
				polygon[0][0] = x;
				polygon[0][1] = y;
				break;
			case "L":
				x = nextFloat;
				y = nextFloat;
				addPoint(x, y);
				break;
			case "l":
				x += nextFloat;
				y += nextFloat;
				addPoint(x, y);
				break;
			case "H":
				x = nextFloat;
				addPoint(x, y);
				break;
			case "h":
				x += nextFloat;
				addPoint(x, y);
				break;
			case "V":
				y = nextFloat;
				addPoint(x, y);
				break;
			case "v":
				y += nextFloat;
				addPoint(x, y);
				break;
			case "Z":
			case "z":
				close();
				break;
			case "A":
				double[2] start = [x, y];
				double[2] radii = [nextFloat, nextFloat];
				double xAngle = nextFloat;
				bool flagA = nextBool;
				bool flagS = nextBool;
				double[2] end = [nextFloat, nextFloat];

				double[2] center = 0;
				double[2] angles = 0;

				trace(format!"%s Arc %s %s %s %s %s %s %s %s"(name, start, end, radii, xAngle, flagA, flagS, center, angles));

				endpointToCenterArcParams(start, end, radii, xAngle, flagA, flagS, center, angles);

				trace(format!"-> %s %s %s"(radii, center, angles));
				// [1, 1] [1, 1] [-1.5708, -7.85398]

				foreach (i; 0 .. arc_resolution)
				{
					// TODO: Large-circle minor has incorrect angles and becomes just a straight line!
					auto angle = lerp(angles[0], angles[1], i / cast(double)arc_resolution
						// horrible hack... idk why but this works
						* (flagS ? 1.0 : 0.25));
					auto p = ellipticArcPoint(center, radii, xAngle, angle);
					addPoint(p[0], p[1]);
				}
				x = end[0];
				y = end[1];
				addPoint(x, y);
				break;
			default:
				throw new Exception("Unsupported SVG command: " ~ cmd.idup);
			}
		}

		close();

		assert(ret.vertices.length, "no vertices?!");
		assert(ret.rawIndices.length, "no indices?!");
		assert(ret.isMoveTo.length == ret.vertices.length);
		foreach (i, vertex; ret.vertices)
		{
			assert(vertex[0] >= 0 && vertex[0] <= 1
				&& vertex[1] >= 0 && vertex[1] <= 1,
				"vertex #" ~ i.to!string ~ " (" ~ vertex.to!string ~ ") out of bounds!");
		}

		ret.recomputeSidesClosed();

		return ret;
	}

	void recomputeSidesClosed()
	in (vertices.length)
	{
		sidesClosed[] = false;
		// for all sides: interval that is covered - almost no support for gaps
		// and heavily dependent on sorting if a side is comprised of more than
		// 2 lines
		float[2][4] rangeSidesCovered = 0;
		foreach (i; 0 .. vertices.length)
		{
			auto a = vertices[i];
			auto b = vertices[i == $ - 1 ? 0 : i + 1];
			Side side;
			double lower, upper;
			if (isClose(a[0], b[0]))
			{
				// vertical line
				lower = min(a[1], b[1]);
				upper = max(a[1], b[1]);

				if (a[0] < 0.001)
					side = Side.left;
				else if (a[0] >= 0.999)
					side = Side.right;
				else
					continue;
			}
			else if (isClose(a[1], b[1]))
			{
				// horizontal line
				lower = min(a[0], b[0]);
				upper = max(a[0], b[0]);

				if (b[1] < 0.001)
					side = Side.top;
				else if (b[1] >= 0.999)
					side = Side.bottom;
				else
					continue;
			}
			else
				continue;


			auto range = rangeSidesCovered[cast(int) side][];
			if (range[0] is range[1])
				range[] = [lower, upper];
			else
			{
				if (lower >= range[0] - 0.001 && lower <= range[1] + 0.001)
					range[1] = max(range[1], upper);
				if (upper >= range[0] - 0.001 && upper <= range[1] + 0.001)
					range[0] = min(range[0], lower);
			}
		}

		// trace(name, ": ", rangeSidesCovered);

		foreach (i, range; rangeSidesCovered)
			if (range[0] <= 0.001 && range[1] >= 0.999)
				sidesClosed[i] = true;
		// trace("-> ", sidesClosed);
	}

	Shape dup() const
	{
		Shape ret;
		ret.name = this.name;
		ret.vertices ~= this.vertices;
		ret.rawIndices ~= this.rawIndices;
		ret.isMoveTo = this.isMoveTo.dup;
		ret.tupleof[4 .. $] = this.tupleof[4 .. $];
		return ret;
	}

	void rot90()
	{
		foreach (ref vertex; vertices)
			vertex = [1.0 - vertex[1], vertex[0]];

		bool[4] original = sidesClosed;
		sidesClosed[1] = original[0];
		sidesClosed[2] = original[1];
		sidesClosed[3] = original[2];
		sidesClosed[0] = original[3];
	}

	void rot180()
	{
		flipX();
		flipY();
	}

	void rot270()
	{
		rot180();
		rot90();
	}

	void flipX()
	{
		foreach (ref vertex; vertices)
			vertex[0] = 1.0 - vertex[0];
		swap(sidesClosed[0], sidesClosed[2]);
		reverseIndices = !reverseIndices;
	}

	void flipY()
	{
		foreach (ref vertex; vertices)
			vertex[1] = 1.0 - vertex[1];
		swap(sidesClosed[1], sidesClosed[3]);
		reverseIndices = !reverseIndices;
	}
}

// static immutable Shape[] allShapes = generateShapes(`
const(Shape[]) allShapes() {
	static Shape[] shapes;
	if (shapes.length)
		return shapes;
	return shapes = generateShapes(`
		# go clockwise, top-left = 0,0, bottom-right = 1,1
		# modifiers:
		# [rot] = add rotating variants
		# [fliprot] = add rotated variants + rotated variants after X flip
		# implicit: M 0 0 at start - Z at end
		# SQRT3-1 = sqrt(3) - 1 ≈ 0.73205087568877193

		Filled: H 1 V 1 H 0
		Triangle[rot]: H 1 L 0 1
		Quarter Circle[rot]: L 1 0 A 1 1 0 0 1 0 1
		Inverted Quarter Circle[rot]: L 1 0 A 1 1 0 0 0 0 1
		Three-Quarter Inverted Quarter Circle[rot]: L 1 0 V 0.5 A 0.5 0.5 0 0 0 0.5 1 H 0
		Three-Quarter Cutoff[rot]: H 1 V 0.5 L 0.5 1 H 0
		Three-Quarter Block[rot]: H 1 V 0.5 H 0.5 V 1 H 0
		Half Block[rot]: H 1 V 0.5 H 0
		Full Triangle[rot]: H 1 L 0.5 1
		Star Corner[rot]: H 0.5 L 1 1 L 0 0.5
		Half Triangle[rot]: H 1 L 0.5 0.5
		Half Triangle Offset[rot]: H 1 V 0.5 L 0.5 1 L 0 0.5
		Half Dome[rot]: H 1 A 0.5 0.5 0 0 1 0 0
		Half Dome Offset[rot]: H 1 V 0.5 A 0.5 0.5 0 0 1 0 0.5
		Notched[rot]: H 0.5 L 0 0.5 Z M 0.5 0 H 1 V 0.5
		Notched Offset[rot]: H 1 V 1 L 0.5 0.5 L 0 1
		Wide-slope major[fliprot]: H 1 V 0.5 L 0 1
		Wide-slope minor[fliprot]: H 1 L 0 0.5
		Large-circle major[fliprot]: H 1 A 2 2 0 0 1 SQRT3-1 1 H 0
		Large-circle minor[rot]: H SQRT3-1 A 2 2 0 0 1 0 SQRT3-1
		Small Triangle[rot]: H 0.5 L 0 0.5
		Small Quad[rot]: H 0.5 V 0.5 H 0
	`);
}

Shape[] generateShapes(string shapes)
{
	Shape[] ret;
	void addShapes(Shape s, bool rotations)
	{
		ret ~= s;
		if (rotations)
		{
			auto r90 = s.dup;
			auto r180 = s.dup;
			auto r270 = s.dup;
			r90.rot90();
			r180.rot180();
			r270.rot270();
			ret ~= r90;
			ret ~= r180;
			ret ~= r270;
		}
	}

	foreach (line; shapes.lineSplitter)
	{
		line = line.strip;
		if (!line.length || line.startsWith("#"))
			continue;
		auto parts = line.findSplit(":");
		auto name = parts[0];
		bool rot = name.endsWith("[rot]");
		if (rot)
			name = name[0 .. $ - "[rot]".length];
		bool fliprot = name.endsWith("[fliprot]");
		if (fliprot)
		{
			name = name[0 .. $ - "[fliprot]".length];
			rot = true;
		}
		assert(name.length, "shape must have a name!");
		assert(parts[2].length, "shape must have SVG data!");

		auto shape = Shape.fromSVG(name, parts[2].strip);
		addShapes(shape, rot);
		if (fliprot)
		{
			auto copy = shape.dup;
			copy.name ~= " (flipped)";
			copy.flipX();
			addShapes(copy, true);
		}
	}
	return ret;
}

void trace(Args...)(auto ref Args args)
{
	if (!__ctfe)
	{
		import std.logger;

		std.logger.trace(args);
	}
}
