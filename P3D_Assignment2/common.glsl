/**
 * common.glsl
 * Common types and functions used for ray tracing.
 */

const float pi = 3.14159265358979;
const float epsilon = 0.001;

struct Ray {
    vec3 o;     // origin
    vec3 d;     // direction - always set with normalized vector
    float t;    // time, for motion blur
};

Ray createRay(vec3 o, vec3 d, float t)
{
    Ray r;
    r.o = o;
    r.d = d;
    r.t = t;
    return r;
}

Ray createRay(vec3 o, vec3 d)
{
    return createRay(o, d, 0.0);
}

vec3 pointOnRay(Ray r, float t)
{
    return r.o + r.d * t;
}

float gSeed = 0.0;

uint baseHash(uvec2 p)
{
    p = 1103515245U * ((p >> 1U) ^ (p.yx));
    uint h32 = 1103515245U * ((p.x) ^ (p.y>>3U));
    return h32 ^ (h32 >> 16);
}

float hash1(inout float seed) {
    uint n = baseHash(floatBitsToUint(vec2(seed += 0.1,seed += 0.1)));
    return float(n) / float(0xffffffffU);
}

vec2 hash2(inout float seed) {
    uint n = baseHash(floatBitsToUint(vec2(seed += 0.1,seed += 0.1)));
    uvec2 rz = uvec2(n, n * 48271U);
    return vec2(rz.xy & uvec2(0x7fffffffU)) / float(0x7fffffff);
}

vec3 hash3(inout float seed)
{
    uint n = baseHash(floatBitsToUint(vec2(seed += 0.1, seed += 0.1)));
    uvec3 rz = uvec3(n, n * 16807U, n * 48271U);
    return vec3(rz & uvec3(0x7fffffffU)) / float(0x7fffffff);
}

float rand(vec2 v)
{
    return fract(sin(dot(v.xy, vec2(12.9898, 78.233))) * 43758.5453);
}

vec3 toLinear(vec3 c)
{
    return pow(c, vec3(2.2));
}

vec3 toGamma(vec3 c)
{
    return pow(c, vec3(1.0 / 2.2));
}

vec2 randomInUnitDisk(inout float seed) {
    vec2 h = hash2(seed) * vec2(1.0, 6.28318530718);
    float phi = h.y;
    float r = sqrt(h.x);
	return r * vec2(sin(phi), cos(phi));
}

vec3 randomInUnitSphere(inout float seed)
{
    vec3 h = hash3(seed) * vec3(2.0, 6.28318530718, 1.0) - vec3(1.0, 0.0, 0.0);
    float phi = h.y;
    float r = pow(h.z, 1.0/3.0);
	return r * vec3(sqrt(1.0 - h.x * h.x) * vec2(sin(phi), cos(phi)), h.x);
}

struct Camera
{
    vec3 eye;
    vec3 u, v, n;
    float width, height;
    float lensRadius;
    float planeDist, focusDist;
    float time0, time1;
};

Camera createCamera(
    vec3 eye,
    vec3 at,
    vec3 worldUp,
    float fovy,
    float aspect,
    float aperture,  //diametro em multiplos do pixel size
    float focusDist,  //focal ratio
    float time0,
    float time1)
{
    Camera cam;
    if(aperture == 0.0) cam.focusDist = 1.0; //pinhole camera then focus in on vis plane
    else cam.focusDist = focusDist;
    vec3 w = eye - at;
    cam.planeDist = length(w);
    cam.height = 2.0 * cam.planeDist * tan(fovy * pi / 180.0 * 0.5);
    cam.width = aspect * cam.height;

    cam.lensRadius = aperture * 0.5 * cam.width / iResolution.x;  //aperture ratio * pixel size; (1 pixel=lente raio 0.5)
    cam.eye = eye;
    cam.n = normalize(w);
    cam.u = normalize(cross(worldUp, cam.n));
    cam.v = cross(cam.n, cam.u);
    cam.time0 = time0;
    cam.time1 = time1;
    return cam;
}

Ray getRay(Camera cam, vec2 pixel_sample)  //rnd pixel_sample viewport coordinates
{
    vec2 ls = cam.lensRadius * randomInUnitDisk(gSeed);  //ls - lens sample for DOF
    float time = cam.time0 + hash1(gSeed) * (cam.time1 - cam.time0);
    
    ls *= cam.lensRadius;
    pixel_sample.x = cam.width * ((pixel_sample.x / iResolution.x) - 0.5f);
    pixel_sample.y = cam.width * ((pixel_sample.y / iResolution.y) - 0.5f);
    pixel_sample *= cam.focusDist;

    vec3 up = cam.u * (pixel_sample.x - ls.x);
    vec3 view = cam.v * (pixel_sample.y - ls.y);
    vec3 normal = cam.n * (cam.focusDist * cam.planeDist);

    vec3 offset = cam.eye + (cam.u * ls.x) + (cam.v * ls.y);
    vec3 direction = normalize(up + view - normal);

    return createRay(offset, normalize(direction), time);
}

// MT_ material type
#define MT_DIFFUSE 0
#define MT_METAL 1
#define MT_DIALECTRIC 2

struct Material
{
    int type;
    vec3 albedo;
    float roughness; // controls roughness for metals
    float refIdx; // index of refraction for dialectric
};

Material createDiffuseMaterial(vec3 albedo)
{
    Material m;
    m.type = MT_DIFFUSE;
    m.albedo = albedo;
    return m;
}

Material createMetalMaterial(vec3 albedo, float roughness)
{
    Material m;
    m.type = MT_METAL;
    m.albedo = albedo;
    m.roughness = roughness;
    return m;
}

Material createDialectricMaterial(vec3 albedo, float refIdx)
{
    Material m;
    m.type = MT_DIALECTRIC;
    m.albedo = albedo;
    m.refIdx = refIdx;
    return m;
}

struct HitRecord
{
    vec3 pos;
    vec3 normal;
    float t;            // ray parameter
    Material material;
};


float schlick(float cosine, float refIdx)
{
    float n1 = 1.0;
    float r0 = (n1-refIdx) / (n1+refIdx);
    r0 *= r0;
    if (n1 > refIdx)
    {
        float n = n1/refIdx;
        float sinT2 = n*n*(1.0-cosine*cosine);
        // Total internal reflection
        if (sinT2 > 1.0)
            return 1.0;
        cosine = sqrt(1.0-sinT2);
    }
    float x = 1.0-cosine;
    float ret = r0+(1.0-r0)*x*x*x*x*x;
 
    // adjust reflect multiplier for object reflectivity
    return ret;
}

bool scatter(Ray rIn, HitRecord rec, out vec3 atten, out Ray rScattered)
{
    if(rec.material.type == MT_DIFFUSE)
    {
        vec3 S = rec.pos + rec.normal + normalize(randomInUnitSphere(gSeed));
        rScattered = createRay((rec.pos+rec.normal*epsilon), S);
        atten = rec.material.albedo * max(dot(rScattered.d, rec.normal), 0) / pi;
        atten = rec.material.albedo*0.01;
        return true;
    }
    if(rec.material.type == MT_METAL)
    {
        //INSERT CODE HERE, consider fuzzy reflections
        //float doSpecular = (hash1(gSeed) < rec.material.roughness) ? 1.0f : 0.0f;
        vec3 diffuseRayDir = normalize(rec.normal + hash1(gSeed));
        vec3 specularRayDir = reflect(rIn.d, rec.normal);
        specularRayDir = normalize(mix(specularRayDir, diffuseRayDir, rec.material.roughness * rec.material.roughness));
        //rayDir = mix(diffuseRayDir, specularRayDir, doSpecular);
        vec3 rayDir = mix(diffuseRayDir, specularRayDir, 1.);
        //ret += rec.material.emissive * throughput;
        //atten = mix(rec.material.albedo, rec.material.specularColor, doSpecular);
        rScattered = createRay(rec.pos, rayDir);
        atten = rec.material.albedo;
        return true;
    }
    if(rec.material.type == MT_DIALECTRIC)
    {
        //atten = rec.material.albedo;
        atten = vec3(1.);
        vec3 outwardNormal;
        float niOverNt;
        float cosine;

        if(dot(rIn.d, rec.normal) > 0.0) //hit inside
        {
            outwardNormal = -rec.normal;
            niOverNt = rec.material.refIdx;
            cosine = rec.material.refIdx * dot(rIn.d, rec.normal); 
        }
        else  //hit from outside
        {
            outwardNormal = rec.normal;
            niOverNt = 1.0 / rec.material.refIdx;
            cosine = -dot(rIn.d, rec.normal); 
        }

        //Use probabilistic math to decide if scatter a reflected ray or a refracted ray
        float reflectProb = schlick(cosine, rec.material.refIdx);
        //if no total reflection  reflectProb = schlick(cosine, rec.material.refIdx);  
        //else reflectProb = 1.0;

        if(hash1(gSeed) < reflectProb){
            vec3 reflR = reflect(rIn.d, outwardNormal);
            rScattered = createRay((rec.pos+rec.normal*epsilon), reflR);
            //atten *= vec3(reflectProb); not necessary since we are only scattering reflectProb rays and not all reflected rays
        
        }   //Reflection
        
        else{
            //rScattered = calculate refracted ray
            vec3 refrR = refract(rIn.d, outwardNormal, niOverNt);
            rScattered = createRay((rec.pos-outwardNormal*epsilon), refrR);
            // atten *= vec3(1.0 - reflectProb); not necessary since we are only scattering 1-reflectProb rays and not all refracted rays
        
        }   //Refraction

        return true;
    }
    return false;
}

struct pointLight {
    vec3 pos;
    vec3 color;
};

pointLight createPointLight(vec3 pos, vec3 color) 
{
    pointLight l;
    l.pos = pos;
    l.color = color;
    return l;
}

struct Triangle {vec3 a; vec3 b; vec3 c; };

Triangle createTriangle(vec3 v0, vec3 v1, vec3 v2)
{
    Triangle t;
    t.a = v0; t.b = v1; t.c = v2;
    return t;
}

bool hit_triangle(Triangle tri, Ray r, float tmin, float tmax, out HitRecord rec)
{
    //INSERT YOUR CODE HERE
    //calculate a valid t and normal
    /**/
    float t;
    vec3 v0v1, v0v2, h, s, q;
    v0v1 = tri.b - tri.a;
	v0v2 = tri.c - tri.a;
	const float eps = 0.0000001f;
	float a, f, u, v;

	h = cross(r.d, v0v2);
	a = dot(v0v1, h);
	if (a > -eps && a < eps)
		return false;    // This ray is parallel to this triangle.
	f = 1.0f / a;
	s = r.o - tri.a;
	u = dot(s, h) * f;
	if (u < 0.0f || u > 1.0f)
		return false;
	q = cross(s, v0v1);
	v = dot(r.d, q) * f;
	if (v < 0.0f || u + v > 1.0f)
		return false;
	// At this stage we can compute t to find out where the intersection point is on the line.
	t = dot(v0v2, q) * f;
	if (t > eps) // ray intersection
	{
		if(t < tmax && t > tmin)
        {
            rec.t = t;
            rec.normal = -cross(v0v1,v0v2);
            rec.pos = pointOnRay(r, rec.t);
            return true;
        }
	}
    /**/
    return false;
}


struct Sphere
{
    vec3 center;
    float radius;
    float SqRadius;
};

Sphere createSphere(vec3 center, float radius)
{
    Sphere s;
    s.center = center;
    s.radius = radius;
    s.SqRadius = radius*radius;
    return s;
}


struct MovingSphere
{
    vec3 center0, center1;
    float radius;
    float time0, time1;
    float sqRadius;
};

MovingSphere createMovingSphere(vec3 center0, vec3 center1, float radius, float time0, float time1)
{
    MovingSphere s;
    s.center0 = center0;
    s.center1 = center1;
    s.radius = radius;
    s.time0 = time0;
    s.time1 = time1;
    s.sqRadius = radius*radius;
    return s;
}

vec3 center(MovingSphere mvsphere, float time)
{
    vec3 a;
    return a;
    //return moving_center;
}


/*
 * The function naming convention changes with these functions to show that they implement a sort of interface for
 * the book's notion of "hittable". E.g. hit_<type>.
 */

bool hit_sphere(Sphere s, Ray r, float tmin, float tmax, out HitRecord rec)
{
    float a, b, c, t, t0, t1;
	a = dot(r.d, r.d);
	b = dot(((r.o - s.center) * 2.0f), r.d);
	c = dot((r.o - s.center), (r.o - s.center)) - s.SqRadius;

    float disc = b * b - 4.0f * a * c;
	if (disc < 0.0f) return false;
	else if (disc == 0.0f) t0 = t1 = -0.5f * b / a;
	else {
		float q = (b > 0.0f) ?
			-0.5 * (b + sqrt(disc)) : -0.5 * (b - sqrt(disc));
		t0 = q / a;
		t1 = c / q;
	}
	if (t0 > t1) {
		disc = t0;
		t0 = t1;
		t1 = disc;
	}
    if (t0 > t1) {
		a = t0;
		t0 = t1;
		t1 = a;
	}
	if (t0 < 0.0f) {
		t0 = t1;
		if (t0 < 0.0f) return false;
	}
	t = t0;
    if(t < tmax && t > tmin) {
        rec.t = t;
        rec.pos = pointOnRay(r, rec.t);
        rec.normal = normalize(rec.pos - s.center);
        return true;
    }
    else return false;
}

bool hit_movingSphere(MovingSphere s, Ray r, float tmin, float tmax, out HitRecord rec)
{
    float a, b, c, t, t0, t1, delta;
    bool outside;
    s.time0 = s.time1;
    s.time1 = r.t;
    delta = s.time1 - s.time0;
    vec3 movCenter = s.center0 + normalize(s.center1 - s.center0) * delta;
    //INSERT YOUR CODE HERE
    //Calculate the moving center
	a = dot(r.d, r.d);
	b = dot(((r.o - movCenter) * 2.0f), r.d);
	c = dot((r.o - movCenter), (r.o - movCenter)) - s.sqRadius;

    float disc = b * b - 4.0f * a * c;
	if (disc < 0.0f) return false;
	else if (disc == 0.0f) t0 = t1 = -0.5f * b / a;
	else {
		float q = (b > 0.0f) ?
			-0.5 * (b + sqrt(disc)) : -0.5 * (b - sqrt(disc));
		t0 = q / a;
		t1 = c / q;
	}
	if (t0 > t1) {
		disc = t0;
		t0 = t1;
		t1 = disc;
	}
    if (t0 > t1) {
		a = t0;
		t0 = t1;
		t1 = a;
	}
	if (t0 < 0.0f) {
		t0 = t1;
		if (t0 < 0.0f) return false;
	}
	t = t0;
    if(t < tmax && t > tmin) {
        rec.t = t;
        rec.pos = pointOnRay(r, rec.t);
        rec.normal = normalize(rec.pos - movCenter);
        return true;
    }
    else return false;
    
}
