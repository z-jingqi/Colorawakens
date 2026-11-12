shader_type spatial;
uniform sampler2D screen_tex : hint_screen_texture, filter_linear_mipmap;
uniform vec4 marks[16];
uniform vec4 pigments[16];
uniform int count=0;
uniform float awaken=0.;
uniform float energy=0.;
varying vec3 local_pos;
float smin(float a,float b,float k){float h=max(k-abs(a-b),0.)/k;return min(a,b)-h*h*k*.25;}
float footprint(vec3 p,vec4 hit,float idx){
 float age=hit.w;
 float spread=1.-exp(-age*13.);
 vec3 d=p-hit.xyz;
 float wobble=sin(age*21.)*exp(-age*5.5)*.055;
 float body=length(d/vec3(1.,.83,1.))-(.05+.36*spread+wobble);
 for(int j=0;j<7;j++){
  float a=float(j)*2.39996+idx*1.71;
  float reach=(.46+.20*sin(float(j)*4.1+idx))*spread;
  vec3 q=d-vec3(cos(a),sin(a),0.)*reach;
  float lobe=length(q)-(.08+.055*(.5+.5*sin(float(j)*7.3+idx)))*spread;
  body=smin(body,lobe,.16*spread+.001);
 }
 // Gravity draws viscous fingers out of the bottom edge, with rounded beads.
 float flow=(1.-exp(-max(age-.17,0.)*.95));
 for(int j=0;j<3;j++){
  float x=(float(j)-1.)*.23+.045*sin(idx*3.+float(j));
  float end_y=-.28-flow*(.3+.32*(.5+.5*sin(float(j)*5.+idx)));
  vec3 q=d-vec3(x,clamp(d.y,end_y,-.1),0.);
  float width=(.075+.025*sin(float(j)+idx))*(.3+.7*spread);
  body=smin(body,length(q)-width,.13);
  body=smin(body,length(d-vec3(x,end_y,0.))-width*1.24,.09);
 }
 return body;
}
float height_at(vec3 p){
 float h=0.;
 for(int i=0;i<16;i++){
  if(i>=count)break;
  float f=footprint(p,marks[i],float(i));
  float edge=1.-smoothstep(-.15,.012,f);
  h=max(h,edge*(.085+.018*exp(-marks[i].w*2.)));
 }
 return h*(1.-awaken);
}
void vertex(){local_pos=VERTEX;VERTEX+=NORMAL*height_at(VERTEX);}
void fragment(){
 vec3 color=vec3(.42,.45,.49);float coverage=0.;
 for(int i=0;i<16;i++){
  if(i>=count)break;
  float f=footprint(local_pos,marks[i],float(i));
  float mask=1.-smoothstep(-.008,.006,f);
  color=mix(color,pigments[i].rgb,mask);
  coverage=max(coverage,mask);
 }
 float h=height_at(local_pos);
 vec3 dp1=dFdx(VERTEX),dp2=dFdy(VERTEX);
 vec3 r1=cross(dp2,NORMAL),r2=cross(NORMAL,dp1);
 float det=dot(dp1,r1);
 vec3 grad=(r1*dFdx(h)+r2*dFdy(h))/(abs(det)+.000001)*sign(det);
 NORMAL=normalize(NORMAL-grad*1.25);
 vec3 reflection=reflect(-normalize(VIEW),NORMAL);
 float softbox=exp(-pow((reflection.x+reflection.y*.55-.25)/.09,2.));
 EMISSION=vec3(1.,.94,.89)*softbox*coverage*.32;
 vec3 eye=normalize(VIEW);vec3 cn=normalize(NORMAL);
 float edge=pow(1.-abs(dot(cn,eye)),2.3);vec3 refl=reflect(-eye,cn);
 vec2 bend=cn.xy*(.017+.013*edge)+local_pos.xy*.0025;vec2 uv=SCREEN_UV+bend;
 vec3 through=vec3(textureLod(screen_tex,uv+bend*.11,0.).r,textureLod(screen_tex,uv,0.).g,textureLod(screen_tex,uv-bend*.11,0.).b);
 float strip=exp(-pow((refl.x+refl.y*.48-.32)/.095,2.));
 float narrow=exp(-pow((refl.x-refl.y*.3+.51)/.025,2.));
 float soft=exp(-pow((refl.y-.75)/.3,2.));
 vec3 tint=mix(vec3(.81,.94,1.),vec3(1.,.79,.92),smoothstep(-1.5,1.5,local_pos.x+local_pos.y*.4));
 vec3 spectral=.5+.5*cos(vec3(0.,2.1,4.2)+local_pos.x*1.7+local_pos.y*1.2);
 vec3 glass=through*tint*.88+vec3(.025,.04,.065);
 glass+=tint*strip*.40+vec3(.8,.92,1.)*narrow*.48+soft*.065;
 glass=mix(glass,tint*.32+spectral*.25,edge*.67);
 glass+=edge*.15+vec3(.75,.92,1.)*energy*.025;
 ALBEDO=color*(1.-awaken);
 EMISSION=mix(EMISSION,glass,awaken);
 ROUGHNESS=mix(mix(.48,.115,coverage),1.,awaken);SPECULAR=.8*(1.-awaken);
}
