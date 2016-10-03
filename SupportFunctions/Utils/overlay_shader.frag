/* overlay_shader.frag -- Overlay Window shader
 *
 * This shader emulates the overlay windows availiable in Datapixx devices,
 * which have a main window for (monochrome) hight bit depth images and
 * and overlay window with indexes into a color look up table.
 * The devices then duplicate the output and can apply different loop up tables
 * which allows for a somewhat convenient way to add experimentor information to
 * a mirrored display.
 * 
 * This shader expects that the window is twice the size of the display screen and 
 * covers the display screen and a screen for an experimentor copy.
 * 
 * You can draw to the first half of main image pointer just like a regular screen
 * The second half is filled in to be identical to the first half.
 * DIFFERENCE TO HARDWARE IMPLEMENTATIONS: Color is preserved as there is not benefit 
 * in monochrome output. 
 *
 * Non-zero indeces drawn into an overlay pointer will replace the value from the main pointer
 * if the looked up color is different to the specified transparency color.
 * A different look up table is used for each half of the image (i.e. each screen)
 *
 * This shader is intended for use as a plugin for the 'FinalOutputFormattingBlit'
 * chain of the Psychtoolbox-3 imaging pipeline.
 *
 * (c)2016 by Jonas Knoell, licensed to you under MIT license.
 */

#extension GL_ARB_texture_rectangle : enable

uniform sampler2DRect Image;
uniform sampler2DRect overlayImage;
uniform vec2 res;

uniform sampler2DRect lookup1;
uniform sampler2DRect lookup2;

uniform vec3 transparencycolor;

/* Declare external function for luminance color conversion: */
vec4 icmTransformColor(vec4 incolor);

void main()
{
    vec2 texCoord = gl_TexCoord[0].st;
    if(texCoord.s > res.s){
        texCoord.s = texCoord.s - res.s;
    }
    
    /* Retrieve main window color value.*/
    vec4 incolor = texture2DRect(Image, texCoord);
    
    int overlayindex = int(floor(texture2DRect(overlayImage, texCoord).r*255. + 0.5));

    vec3 overlaycolor;
    if(overlayindex>0){
        if (texCoord[0]==gl_TexCoord[0].s){
           overlaycolor.r = texture2DRect(lookup1, vec2(overlayindex, 0.5)).r;
           overlaycolor.g = texture2DRect(lookup1, vec2(overlayindex, 1.5)).g;
           overlaycolor.b = texture2DRect(lookup1, vec2(overlayindex, 2.5)).b;
        }else{
           overlaycolor.r = texture2DRect(lookup2, vec2(overlayindex, 0.5)).r;
           overlaycolor.g = texture2DRect(lookup2, vec2(overlayindex, 1.5)).g;
           overlaycolor.b = texture2DRect(lookup2, vec2(overlayindex, 2.5)).b;
        }
    
        if (any(notEqual(overlaycolor, transparencycolor))){
            incolor.rgb = overlaycolor;
        }
    }
    
    /* Apply some color transformation (clamping, gamma correction etc.): */
    incolor = icmTransformColor(incolor);
    
    gl_FragColor.rgb = incolor.rgb;
        
    /* Fix alpha channel to 1.0. */
    gl_FragColor.a = 1.0;
}
