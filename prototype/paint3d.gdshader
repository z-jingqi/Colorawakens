shader_type spatial;
uniform vec4 marks[16];
uniform vec4 pigments[16];
uniform int count=0;
varying vec3 local_pos;
void vertex(){local_pos=VERTEX;}
void fragment(){
 vec3 color=vec3(.57,.60,.65);
 float wetness=0.;
 for(int i=0;i<16;i++){
  if(i>=count) break;
  vec3 d=local_pos-marks[i].xyz;
  float age=marks[i].w;
  float growth=1.-exp(-age*6.);
  float a=atan(d.y,d.x);
  float radius=mix(.06,.7,growth)*(1.+.15*sin(a*7.+float(i))+.08*sin(a*13.));
  float mask=1.-smoothstep(radius-.025,radius+.025,length(d));
  for(int j=0;j<8;j++){
   float angle=float(j)*2.39996+float(i);
   vec3 satellite=vec3(cos(angle),sin(angle),0.)*(.65+.12*sin(float(j)*7.))*growth;
   float r=(.04+.025*sin(float(j)*3.))*growth;
   mask=max(mask,1.-smoothstep(r-.015,r+.015,length(d-satellite)));
  }
  color=mix(color,pigments[i].rgb,mask*.97);
  wetness=max(wetness,mask*(.25+.75*exp(-age*2.)));
 }
 ALBEDO=color;
 ROUGHNESS=mix(.72,.16,wetness);
 SPECULAR=.65;
}
