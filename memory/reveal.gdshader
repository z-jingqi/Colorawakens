shader_type canvas_item;
uniform vec2 centers[12];
uniform float amounts[12];
uniform float complete = 0.0;
void fragment(){
 vec4 tex = texture(TEXTURE, UV);
 float mask = complete;
 for(int i=0;i<12;i++){
  float d=length((UV-centers[i])*vec2(600.0,620.0));
  mask=max(mask,(1.0-smoothstep(105.0*amounts[i],135.0*amounts[i]+0.01,d))*amounts[i]);
 }
 float gray=dot(tex.rgb,vec3(.299,.587,.114));
 vec3 faded=mix(vec3(.20,.24,.31),vec3(.55,.59,.64),gray);
 COLOR=vec4(mix(faded,tex.rgb,mask),tex.a);
}
