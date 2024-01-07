module dump_shapes;

import std.algorithm;
import std.conv;
import std.file;
import std.range;
import std.stdio;

import shapes;

static immutable svgHeader = `<svg width="3" height="3" viewBox="-1 -1 3 3" xmlns="http://www.w3.org/2000/svg">
	<rect width="1" height="1" fill="#ff000011" stroke="red" stroke-width="0.01" />
	<path d="`;
static immutable svgMid = `"/><path d="`;
static immutable svgEnd = `" fill="#00000000" stroke="blue" stroke-width="0.02"/>
</svg>`;

/// Dumps all rasterized shapes to a folder called `shapes` in SVG format to look at in an SVG viewer.
void dump_shapes()
{
	writeln(allShapes.map!"a.name");

	if (!exists("shapes"))
		mkdir("shapes");

	int[string] count;

	foreach (shape; allShapes)
	{
		int v = count[shape.name] += 1;
		auto f = File("shapes/" ~ shape.name ~ " " ~ v.to!string ~ ".svg", "w");
		f.writeln(svgHeader);

		if (shape.sidesClosed[Side.left])
			f.writeln("M -1 0 H -0.8 V 1 H -1 Z");
		if (shape.sidesClosed[Side.top])
			f.writeln("M 0 -1 H 1 V -0.8 H 0 Z");
		if (shape.sidesClosed[Side.right])
			f.writeln("M 1.8 0 H 2 V 1 H 1.8 Z");
		if (shape.sidesClosed[Side.bottom])
			f.writeln("M 0 1.8 H 1 V 2 H 0 Z");

		if (shape.sidesFullyOpen[Side.left])
			f.writeln("M -0.25 0.25 H -0.5 V 0.75 H -0.25 Z");
		if (shape.sidesFullyOpen[Side.top])
			f.writeln("M 0.25 -0.25 H 0.75 V -0.5 H 0.25 Z");
		if (shape.sidesFullyOpen[Side.right])
			f.writeln("M 1.25 0.25 H 1.5 V 0.75 H 1.25 Z");
		if (shape.sidesFullyOpen[Side.bottom])
			f.writeln("M 0.25 1.25 H 0.75 V 1.5 H 0.25 Z");

		// CW/CCW doesn't matter for SVG
		foreach (triIdx; shape.rawIndices.chunks(3))
		{
			f.writeln("M ", shape.vertices[triIdx[0]][0], " ", shape.vertices[triIdx[0]][1]);
			f.writeln("L ", shape.vertices[triIdx[1]][0], " ", shape.vertices[triIdx[1]][1]);
			f.writeln("L ", shape.vertices[triIdx[2]][0], " ", shape.vertices[triIdx[2]][1]);
			f.writeln("Z");
		}

		f.writeln(svgMid);
		foreach (i, vert; shape.vertices)
		{
			f.writeln(i == 0 ? "M " : "L ", vert[0], " ", vert[1]);
		}

		f.writeln(svgEnd);
	}
}
