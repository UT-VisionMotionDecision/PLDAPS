#version 330 compatibility
#extension GL_ARB_explicit_attrib_location : require
#extension GL_ARB_explicit_uniform_location : require

// Hacked attempt at vertex shader for drawing geodesic spheres
// as dots in PLDAPS (Matlab>PTB>openGL)
//
// based on mashup of ParticleSimple.vert (PTB DrawDots3dDemo.m)
//  and Particle.vert
//
// 2017-11-29  TBC
//
// edits:
// float dotSize = xyzs.w;
// vec3 dotPos = xyzs.xyz;
//
//vec3 vertPos = dotPos + (dotVertices.xyz * dotSize);
//
// Input vertex data, different for all executions of this shader.

layout(location = 0) in vec3 dotVertices;
layout(location = 1) in vec4 xyzs;
layout(location = 2) in vec4 color;
out vec4 color2frag;

void main() {
    vec4 vertPos = vec4(xyzs.xyz + (dotVertices.xyz * xyzs.w), 1.0);
    
    gl_Position = gl_ModelViewProjectionMatrix * vertPos;
    
    color2frag = color;
}
