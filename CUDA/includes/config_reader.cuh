#pragma once

#include <vector>
#include <fstream>
#include <iostream>
#include <string>
#include <cstddef> 
#include <memory>
#include <sstream>
#include <algorithm>
#include "cuda_runtime.h"
#include "device_launch_parameters.h"
#include "material.cuh"
#include "shape.cuh"
#include "scene.cuh"
#include "vec3.cuh"
#include "color.cuh"

typedef struct SceneParams {
        Scene **scene;
        int samples_per_pixel;
        int max_depth;
        int log;
        float t_min;
        float t_max;
        int TX;
        int TY;
        int width;
        int height;
        std::string filename;
} SceneParams;

typedef struct Configs {
        float aspect_ratio;
        int largura;
        int altura;
        int TX;
        int TY;
        float viewport_height;
        float viewport_width;
        float focal_length;
        float vfov;
        float aperture;
        float focus_dist;
        point3 origin;
        point3 lookat;
        vec3 horizontal;
        vec3 vertical;
        vec3 vup;
        point3 lower_left_corner;
        std::vector<std::shared_ptr<Shape>> objects;
} Configs;

typedef struct SphereParams {
    float radius;
    MATERIALS material;
    point3 center;
    color obj_color;
    float fuzz;
    float index;
} SphereParams;

typedef struct PlaneParams {
    MATERIALS material;
    point3 center;
    vec3 u;
    vec3 v;
    color obj_color;
    float width;
    float height;
    float fuzz;
    float index;
} PlaneParams;

SceneParams read_scene_from(const char* config_file);
int get_int(std::string text);
float get_float(std::string text);
double get_double(std::string text);
vec3 get_vec3(std::string text);
color get_color(std::string text);
std::string get_string(std::string text);
SphereParams get_sphere_params(std::string text);
PlaneParams get_plane_params(std::string text);
__global__ void get_sphere(Shape** sphere, SphereParams params);
__global__ void get_plane(Shape** plane, PlaneParams params);
__global__ inline void get_camera(Camera** camera, Configs config, int camera_type);
__global__ inline void get_scene(Scene** scene, Camera** camera, Shape** objects, int n_obj, int height, int width);

__host__ inline SceneParams read_scene_from(const char* config_file){
	std::string text;
	
	std::fstream file(config_file, std::fstream::in);

    point3 lower_left_corner;
    Shape** objects;
    std::vector<Shape*> tmp_objects;

    Configs config;
    SceneParams ret;
    ret.log = 0;
    ret.max_depth = 50;
    ret.samples_per_pixel = 500;
    ret.t_min = 0.001;
    ret.t_max = infinity;

    std::string filename = "../images/exemplo_draw_config.ppm";
    config.aspect_ratio = 16/9;
    config.altura = 400;
    config.largura = 710;
    config.viewport_height = 2.0f;
    config.viewport_width = config.aspect_ratio * config.viewport_height;
    config.focal_length = 1.0f;
    config.TX = 8;
    config.TY = 8;

    config.horizontal = vec3(config.viewport_width, 0, 0);
    config.vertical = vec3(0, config.viewport_height, 0);
    config.origin = point3(0, 0, 0);
    config.lookat = point3(0,0,-1);
    config.vup = vec3(0,0,-1);
    config.vfov = 90;
    config.focus_dist = (float) (config.origin-config.lookat).length();
    config.aperture = 2.0f;

    int camera_type = 0;

	while(getline(file, text)){ 
		if(text.size() == 0 || text.at(0) == '#')
			continue;
		else if(text.find("filename") != std::string::npos)
			filename = get_string(text);
		else if(text.find("camera_type") != std::string::npos)
			camera_type = get_int(text);
		else if(text.find("aperture") != std::string::npos)
			config.aperture = get_float(text);
		else if(text.find("focus_dist") != std::string::npos)
			config.focus_dist = get_float(text);
		else if(text.find("aspect_ratio") != std::string::npos)
			config.aspect_ratio = get_float(text);
		else if(text.find("altura") != std::string::npos)
			config.altura = get_int(text);
		else if(text.find("largura") != std::string::npos)
			config.largura = get_int(text);
		else if(text.find("TX") != std::string::npos)
			config.TX = get_int(text);
		else if(text.find("TY") != std::string::npos)
			config.TY = get_int(text);
        else if(text.find("lookat") != std::string::npos)
            config.lookat = get_vec3(text);
        else if(text.find("vup") != std::string::npos)
            config.vup = get_vec3(text);
        else if(text.find("vfov") != std::string::npos)
            config.vfov = get_float(text);
		else if(text.find("viewport_height") != std::string::npos)
			config.viewport_height = get_float(text);
		else if(text.find("viewport_width") != std::string::npos)
			config.viewport_width = get_float(text);
		else if(text.find("focal_length") != std::string::npos)
			config.focal_length = get_float(text);
		else if(text.find("origin") != std::string::npos)
			config.origin = get_vec3(text);
		else if(text.find("horizontal") != std::string::npos)
			config.horizontal = get_vec3(text);
		else if(text.find("vertical") != std::string::npos)
			config.vertical = get_vec3(text);
        else if(text.find("sphere") != std::string::npos){
            Shape** tmp_sphere;
            checkCudaErrors(cudaMallocManaged((void **)&tmp_sphere, sizeof(Shape*)));
            get_sphere<<<1,1>>>(tmp_sphere, get_sphere_params(text));
            check_and_wait();
			tmp_objects.push_back(*tmp_sphere);
        }
        else if(text.find("plane") != std::string::npos){
            Shape** tmp_plane;
            checkCudaErrors(cudaMallocManaged((void **)&tmp_plane, sizeof(Shape*)));
            get_plane<<<1,1>>>(tmp_plane, get_plane_params(text));
            check_and_wait();
			tmp_objects.push_back(*tmp_plane);
        }
        else if(text.find("max_depth") != std::string::npos)
			ret.max_depth = get_int(text);
        else if(text.find("samples_per_pixel") != std::string::npos)
			ret.samples_per_pixel = get_int(text);
        else if(text.find("log") != std::string::npos)
			ret.log = get_int(text);
	}

    checkCudaErrors(cudaMallocManaged((void ***)&objects, sizeof(Shape*)*tmp_objects.size()));

    for(int i = 0; i < tmp_objects.size(); i++){
        objects[i] = tmp_objects[i];
    }

    Camera** camera;
    checkCudaErrors(cudaMallocManaged((void **)&camera, sizeof(Camera*)));

    get_camera<<<1,1>>>(camera, config, camera_type);
    check_and_wait();

    Scene** scene;
    checkCudaErrors(cudaMallocManaged((void **)&scene, sizeof(Scene*)));
    get_scene<<<1,1>>>(scene, camera, objects, (int) tmp_objects.size(), config.altura, config.largura);
    check_and_wait();

    ret.scene = scene;
    ret.filename = filename;
    ret.TX = config.TX;
    ret.TY = config.TY;
    ret.width = config.largura;
    ret.height = config.altura;

    return ret;
}

__host__ inline int get_int(std::string text){
    std::stringstream ss(text);
    int ret = 0;
    std::string trash = "";
    
    ss >> trash >> trash >> ret;

    return ret;
}

__host__ inline float get_float(std::string text){
    std::stringstream ss(text);
    float ret = 0;
    std::string trash = "";
    
    ss >> trash >> trash >> ret;
    return ret;
}

__host__ inline double get_double(std::string text){
    std::stringstream ss(text);
    double ret = 0;
    std::string trash = "";

    ss >> trash >> trash >> ret;
    return ret;
}

__host__ inline vec3 get_vec3(std::string text){
    std::replace(text.begin(), text.end(), ',', ' ');
    std::replace(text.begin(), text.end(), '(', ' ');
    std::replace(text.begin(), text.end(), ')', ' ');
    std::istringstream ss(text);
    double x, y, z;
    std::string trash = "";

    ss  >> trash >> trash >> x >> y >> z;
    return vec3(x,y,z); 
}

__host__ inline color get_color(std::string text){
    std::replace(text.begin(), text.end(), ',', ' ');
    std::replace(text.begin(), text.end(), '(', ' ');
    std::replace(text.begin(), text.end(), ')', ' ');

    std::istringstream ss(text);
    double x, y, z;
    std::string trash = "";
    
    ss  >> trash >> trash >> x >> y >> z;
    return color(x,y,z); 
}

__host__ inline std::string get_string(std::string text){
    std::istringstream ss(text);
    std::string name;
    std::string trash = "";

    ss  >> trash >> trash >> name;
    
    return name; 
}

__host__ inline SphereParams get_sphere_params(std::string text){
    std::replace(text.begin(), text.end(), ',', ' ');
    std::replace(text.begin(), text.end(), '(', ' ');
    std::replace(text.begin(), text.end(), ')', ' ');

    std::istringstream ss(text);
    std::string trash = "";
    double a,b,c,radius;
    ss >> trash >> trash >> a >> b >> c >> radius; 
    point3 center = point3(a,b,c);
    SphereParams params;

    params.radius = radius;
    params.center = center;

    if(text.find("metal") != std::string::npos){
        float r, g, b, fuzz;
        ss >> trash >> r >> g >> b >> fuzz;
        params.material = METAL;
        params.obj_color = color(r,g,b);
        params.fuzz = fuzz;
    }else if(text.find("opaque") != std::string::npos){
        float r, g, b;
        ss >> trash >> r >> g >> b;
        params.material = OPAQUE;
        params.obj_color = color(r,g,b);
    }else if(text.find("glass") != std::string::npos){
        float r, g, b, index;
        ss >> trash >> r >> g >> b >> index;
        params.material = GLASS;
        params.obj_color = color(r,g,b);
        params.index = index;
    }

    return params;
}

__host__ inline PlaneParams get_plane_params(std::string text){
    std::replace(text.begin(), text.end(), ',', ' ');
    std::replace(text.begin(), text.end(), '(', ' ');
    std::replace(text.begin(), text.end(), ')', ' ');

    std::istringstream ss(text);
    std::string trash = "";

    double x1,x2,x3,y1,y2,y3,z1,z2,z3, width, height;
    ss >> trash >> trash >> x1 >> y1 >> z1 >> x2 >> y2 >> z2 >> x3 >> y3 >> z3 >> width >> height; 
    point3 center = point3(x1,y1,z1);
    vec3 u = vec3(x2,y2,z2);
    vec3 v = vec3(x3,y3,z3);

    PlaneParams params;

    params.u = u;
    params.v = v;
    params.center = center;
    params.width = width;
    params.height = height;

    if(text.find("metal") != std::string::npos){
        float r, g, b, fuzz;
        ss >> trash >> r >> g >> b >> fuzz;
        params.material = METAL;
        params.obj_color = color(r,g,b);
        params.fuzz = fuzz;
    }else if(text.find("opaque") != std::string::npos){
        double r, g, b;
        ss >> trash >> r >> g >> b;
        params.material = OPAQUE;
        params.obj_color = color(r,g,b);
    }else if(text.find("glass") != std::string::npos){
        double r, g, b, index;
        ss >> trash >> r >> g >> b >> index;
        params.material = GLASS;
        params.obj_color = color(r,g,b);
        params.index = index;
    }

    return params;
}

__global__ inline void get_sphere(Shape** sphere, SphereParams params){
    if(params.material == METAL)
        *sphere = new Sphere(params.center, params.radius, new Metal(params.obj_color, params.fuzz));
    else if(params.material==OPAQUE)
        *sphere = new Sphere(params.center, params.radius, new Opaque(params.obj_color));
    else if(params.material==GLASS)
        *sphere = new Sphere(params.center, params.radius, new Glass(params.obj_color, params.index));
}

__global__ inline void get_plane(Shape** plane, PlaneParams params){
    if(params.material == METAL)
        *plane = new Plane(params.center, params.u, params.v, params.width, params.height, new Metal(params.obj_color, params.fuzz));
    else if(params.material == OPAQUE)
        *plane = new Plane(params.center, params.u, params.v, params.width, params.height, new Opaque(params.obj_color));
    else if(params.material == GLASS)
        *plane = new Plane(params.center, params.u, params.v, params.width, params.height, new Glass(params.obj_color, params.index));    
}

__global__ inline void get_camera(Camera** camera, Configs config, int camera_type){
    if(camera_type == 0){
        config.lower_left_corner = config.origin - config.horizontal/2 - config.vertical/2 - vec3(0, 0, config.focal_length);

        *camera = new Camera(config.viewport_height,
                                    config.viewport_width,
                                    config.focal_length,
                                    config.origin,
                                    config.horizontal,
                                    config.vertical,
                                    config.lower_left_corner);
    }else
        *camera = new Camera(config.origin,
                                    config.lookat,
                                    config.vup,
                                    config.vfov,
                                    config.aspect_ratio,
                                    config.aperture,
                                    config.focus_dist
                                    );
}

__global__ inline void get_scene(Scene** scene, Camera** camera, Shape** objects, int n_obj, int height, int width){
    *scene = new Scene(*camera, objects, n_obj, width, height);
}

__host__ inline void free_scene(SceneParams params){
    for(int i = 0; i < (*params.scene)->n_obj; i++)
        checkCudaErrors(cudaFree((*params.scene)->objects[i]));

    checkCudaErrors(cudaFree((*params.scene)->objects));
    checkCudaErrors(cudaFree((*params.scene)->camera));
    checkCudaErrors(cudaFree(params.scene));
}