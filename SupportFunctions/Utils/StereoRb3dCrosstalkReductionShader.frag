/* vim: syntax=glsl
 * StereoRb3dCrosstalkReductionShader.frag.txt
 *
 * Tweaked version of the PTB standard that operates only once on the
 * merged R & B color channels (during FinalFormatting) rather than separately
 * on each eye. ...PTB version (3.0.13) was terribly slow, and causing massive
 * frame drops during even trivial operations in PLDAPS.
 * 
 * Implemented in openScreen.m when using Rb3d mode w/crosstalk correction &&
 * .useOverlay == 1;
 * 	(...could tweak to drop dependence on .useOverlay apply more broadly,
 * 	but thats just where it fit at the moment. --TBC 2017-10-04)
 * 
 * A fragment shader that receives a input image after stereo pairs have been
 * blitted into R & B color channels. Computes a corrected stereo output image
 * by subtraction after negating background contrast.
 *
 * 'Image' is the primary stereo input image, which should be written back
 * as output image. NO 'Image2' necessary in this adaptation.
 *
 * crosstalkGain = [L-gain*R, 0, R-gain*L]
 * -!- 2nd crosstalk gain value (green channel) must be zero, or will
 * interfere with Overlay.
 *
 * background luminance / color level (set by backGroundClr uniform)
 * should not be zero as then there is no way to invert contrast w.r.t.
 * the background.
 * 
 * Based on Psychtoolbox ver3.0.13 StereoCrosstalkReductionShader.frag.txt
 *  by Diederick Niehorster, licensed under MIT license.
 * 
 * 2017-10-04  T. Czuba 
 */

#extension GL_ARB_texture_rectangle : enable

uniform sampler2DRect Image;
uniform vec3  crosstalkGain;
uniform vec3  backGroundClr;

void main()
{
    vec2 texCoord = gl_TexCoord[0].st;

    /* Get current input image pixel color values
     * at current location texCoord: */
    vec3 imageIn = texture2DRect(Image, texCoord).rgb;

    /* Sub background, flip position of RB channels for subtraction, scale by gain : */
    vec3 imageOut = imageIn.bgr - backGroundClr.bgr;
    imageOut.rgb *= -crosstalkGain;

    /* Write output pixel color as sum of original (imageIn)
     * and crosstalk corrections (imageOut) */
    gl_FragColor.rgb = imageIn + imageOut;
}
