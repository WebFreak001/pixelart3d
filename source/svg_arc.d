// Code from https://mortoray.com/rendering-an-svg-elliptical-arc-as-bezier-curves/

module svg_arc;

import std.algorithm;
import std.math;

/**
    Perform the endpoint to center arc parameter conversion as detailed in the SVG 1.1 spec.
    F.6.5 Conversion from endpoint to center parameterization

    @param r must be a ref in case it needs to be scaled up, as per the SVG spec
*/
void endpointToCenterArcParams(double[2] p1, double[2] p2, ref double[2] r_, double xAngle,
	bool flagA, bool flagS, out double[2] c, out double[2] angles)
{
	double rX = abs(r_[0]);
	double rY = abs(r_[1]);

	//(F.6.5.1)
	double dx2 = (p1[0] - p2[0]) / 2.0;
	double dy2 = (p1[1] - p2[1]) / 2.0;
	double x1p = cos(xAngle) * dx2 + sin(xAngle) * dy2;
	double y1p = -sin(xAngle) * dx2 + cos(xAngle) * dy2;

	//(F.6.5.2)
	double rxs = rX * rX;
	double rys = rY * rY;
	double x1ps = x1p * x1p;
	double y1ps = y1p * y1p;
	// check if the radius is too small `pq < 0`, when `dq > rxs * rys` (see below)
	// cr is the ratio (dq : rxs * rys)
	double cr = x1ps / rxs + y1ps / rys;
	if (cr > 1)
	{
		//scale up rX,rY equally so cr == 1
		auto s = sqrt(cr);
		rX = s * rX;
		rY = s * rY;
		rxs = rX * rX;
		rys = rY * rY;
	}
	double dq = (rxs * y1ps + rys * x1ps);
	double pq = (rxs * rys - dq) / dq;
	double q = sqrt(max(0, pq)); //use Max to account for double precision
	if (flagA == flagS)
		q = -q;
	double cxp = q * rX * y1p / rY;
	double cyp = -q * rY * x1p / rX;

	//(F.6.5.3)
	double cx = cos(xAngle) * cxp - sin(xAngle) * cyp + (p1[0] + p2[0]) / 2;
	double cy = sin(xAngle) * cxp + cos(xAngle) * cyp + (p1[1] + p2[1]) / 2;

	//(F.6.5.5)
	double theta = svgAngle(1, 0, (x1p - cxp) / rX, (y1p - cyp) / rY);
	//(F.6.5.6)
	double delta = svgAngle(
		(x1p - cxp) / rX, (y1p - cyp) / rY,
		(-x1p - cxp) / rX, (-y1p - cyp) / rY);

	if (__ctfe)
		delta = delta % (PI * 2);
	else
		delta = fmod(delta, PI * 2);

	if (!flagS)
		delta -= 2 * PI;

	r_ = [rX, rY];
	c = [cx, cy];
	angles = [theta, delta];
}

static double svgAngle(double ux, double uy, double vx, double vy)
{
	double[2] u = [ux, uy];
	double[2] v = [vx, vy];
	//(F.6.5.4)
	auto dot = vectorDot(u, v);
	auto len = vectorLength(u) * vectorLength(v);
	auto ang = acos(clamp(dot / len, -1, 1)); //floating point precision, slightly over values appear
	if ((u[0] * v[1] - u[1] * v[0]) < 0)
		ang = -ang;
	return ang;
}

double vectorDot(double[2] a, double[2] b)
{
	return a[0] * b[0] + a[1] * b[1];
}

double vectorLength(double[2] v)
{
	return sqrt(v[0] * v[0] + v[1] * v[1]);
}

T lerp(T)(T a, T b, double v)
{
	return a * (1.0 - v) + b * v;
}

double[2] ellipticArcPoint(double[2] c, double[2] r, double xAngle, double t)
{
	return [
		c[0] + r[0] * cos(xAngle) * cos(t) - r[1] * sin(xAngle) * sin(t),
		c[1] + r[0] * sin(xAngle) * cos(t) + r[1] * cos(xAngle) * sin(t)
	];
}
