#pragma once

#include "vec3.hpp"
#include "ray.hpp"
#include "color.hpp"
#include "material.hpp"

class Shape {
    public:
        point3 position;
        color shape_color;
        shared_ptr<Material> obj_material;
    public:
        virtual double hit(const ray& r, float t_min, float t_max) = 0;
        virtual vec3 normal(const ray& r, point3 point) = 0;
};

class Sphere : public Shape{
    public:
        double radius;
    public:
        Sphere(point3 center, double rad, shared_ptr<Material> m);
        double hit(const ray& r, float t_min, float t_max);
        vec3 normal(const ray& r, point3 point);
};

class Cube : public Shape{
    public:
        double hit(const ray& r, float t_min, float t_max);
        vec3 normal(const ray& r, point3 point);
};

class Plane : public Shape{
    public:
        vec3 u_dir;
        vec3 v_dir;
        vec3 n;
        double u;
        double v;
    public:
        Plane(point3 center, vec3 u_dir, vec3 v_dir, double u, double v, shared_ptr<Material> m);
        double hit(const ray& r, float t_min, float t_max);
        vec3 normal(const ray& r, point3 point);
};