shader_type spatial;
uniform vec4 marks[16];
uniform vec4 pigments[16];
uniform int count=0;
uniform float awaken=0.;
uniform float energy=0.;
vec3 hsv(float h){return clamp(abs(fract(vec3(h)+vec3(0.,.666667,.333333))*6.-3.)-1.,0.,1.);}
varying vec3 local_pos;
varying vec3 view_x;
varying vec3 view_y;
void vertex(){local_pos=VERTEX;view_x=(MODELVIEW_MATRIX*vec4(1.,0.,0.,0.)).xyz;view_y=(MODELVIEW_MATRIX*vec4(0.,1.,0.,0.)).xyz;}
void fragment(){
 vec3 color=vec3(.52,.51,.50);
 vec2 ridge=vec2(0.);
 float wetness=0.;
 for(int i=0;i<16;i++){
  if(i>=count) break;
  vec3 d=local_pos-marks[i].xyz;
  float age=marks[i].w;
  float growth=1.-exp(-age*6.);
  float a=atan(d.y,d.x);
  float radius=mix(.06,.7,growth)*(1.+.15*sin(a*7.+float(i))+.04*sin(a*11.));
  float mask=1.-smoothstep(radius-.025,radius+.025,length(d));
  for(int j=0;j<8;j++){
   float angle=float(j)*2.39996+float(i);
   vec3 satellite=vec3(cos(angle),sin(angle),0.)*(.65+.12*sin(float(j)*7.))*growth;
   float r=(.04+.025*sin(float(j)*3.))*growth;
   mask=max(mask,1.-smoothstep(r-.015,r+.015,length(d-satellite)));
  }
  ridge+=normalize(d.xy+vec2(.0001))*exp(-pow((length(d)-radius)/.04,2.))*.27*mask;
  float rim=exp(-pow((length(d)-radius)/.045,2.));
  vec3 ink=pigments[i].rgb*(.9+.1*sin(d.x*5.+d.y*3.));
  ink+=rim*.08;
  color=mix(color,ink,mask*.97);
  wetness=max(wetness,mask*(.25+.75*exp(-age*2.)));
 }
 float hue=local_pos.x*.14+local_pos.y*.2+sin(local_pos.y*2.+TIME*.7)*.09+TIME*.045;
 vec3 rainbow=mix(vec3(1.),hsv(hue),.72);
 color=mix(color,rainbow,awaken);
 NORMAL=normalize(NORMAL-(view_x*ridge.x+view_y*ridge.y)*(1.-awaken));
 ALBEDO=color;
 EMISSION=rainbow*awaken*(.12+energy*.6);
 ROUGHNESS=mix(mix(.48,.12,wetness),.19,awaken);
 SPECULAR=.65;
}
