// gen.glsl — full-res generative pass for T6a filter benchmark.
// Written in Processing texture-shader convention so it runs on both
// desktop OpenGL (Mac) and GLES (Pi V3D driver).

#ifdef GL_ES
precision mediump float;
precision mediump int;
#endif

#define PROCESSING_TEXTURE_SHADER

uniform sampler2D texture;
varying vec4 vertTexCoord;
uniform float time;

void main() {
  vec2 uv = vertTexCoord.st;
  float v = sin(uv.x * 40.0 + time)
          + sin(uv.y * 37.0 - time * 1.3)
          + sin((uv.x + uv.y) * 29.0 + time * 0.7)
          + sin(length(uv - 0.5) * 45.0);
  vec3 plasma = 0.5 + 0.5 * cos(vec3(v, v + 2.1, v + 4.2));
  vec4 t = texture2D(texture, uv);
  gl_FragColor = vec4(mix(plasma, t.rgb, 0.25), 1.0);
}
