module palettes;

uint[][string] palettes;
shared static this()
{
	palettes = [
		"PixelArt 32": [
			0x000000,
			0x222034,
			0x45283c,
			0x663931,
			0x8f563b,
			0xdf7126,
			0xd9a066,
			0xeec39a,
			0xfbf236,
			0x99e550,
			0x6abe30,
			0x37946e,
			0x4b692f,
			0x524b24,
			0x323c39,
			0x3f3f74,
			0x306082,
			0x5b6ee1,
			0x639bff,
			0x5fcde4,
			0xcbdbfc,
			0xffffff,
			0x9badb7,
			0x847e87,
			0x696a6a,
			0x595652,
			0x76428a,
			0xac3232,
			0xd95763,
			0xd77bba,
			0x8f974a,
			0x8a6f30,
		]
	];

	foreach (ref p; palettes)
		foreach (ref v; p)
			v = (v << 8) | 0x000000FF;

	version (LittleEndian)
	{
		import std.bitmanip : swapEndian;
		foreach (ref p; palettes)
			foreach (ref v; p)
				v = swapEndian(v);
	}

	import std.stdio;
	foreach (name, palette; palettes)
		writefln("%s: %(#%06x %)", name, palette);
}
