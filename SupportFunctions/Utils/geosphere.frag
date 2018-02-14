//#version 330 compatibility
#extension GL_ARB_explicit_attrib_location : require
//#extension GL_ARB_explicit_uniform_location : require

// Corresponding fragment shader to geosphere.vert
// Hacked attempt at vertex shader for drawing geodesic spheres
// as dots in PLDAPS (Matlab>PTB>openGL)
//
// based on mashup of ParticleSimple.vert (PTB DrawDots3dDemo.m)
//  and Particle.vert
//
// 2017-11-29  TBC
// Input vertex data, different for all executions of this shader.


in vec4 color2frag;

void main(void)
{    
    gl_FragColor = color2frag;
}

