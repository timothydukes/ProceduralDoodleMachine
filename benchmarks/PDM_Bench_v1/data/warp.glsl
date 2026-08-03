// warp.glsl — slight zoom + decay for the T6b ping-pong feedback benchmark.
// Processing texture-shader convention; runs on desktop GL and GLES.

#ifdef GL_ES
precision mediump float;
precision mediump int;
#endif

#define PROCESSING_TEXTURE_SHADER

uniform sampler2D texture;
varying vec4 vertTexCoord;

void main() {
  vec2 uv = vertTexCoord.st;
  vec2 c = vec2(0.5, 0.5);
  // zoom slightly toward center + tiny rotation
  vec2 d = uv - c;
  float ca = cos(0.004), sa = sin(0.004);
  d = vec2(d.x * ca - d.y * sa, d.x * sa + d.y * ca) * 0.995;
  vec4 col = texture2D(texture, c + d);
  gl_FragColor = vec4(col.rgb * 0.985, 1.0);
}
