shader_type spatial;
render_mode unshaded, cull_back;
uniform sampler2D screen_tex: hint_screen_texture, filter_linear_mipmap;
uniform float phase=0.;
uniform int lobes=1;
varying vec3 local_p;
void vertex(){
 float displacement=.018*sin(VERTEX.y*3.+phase*1.7)*sin(VERTEX.x*2.3+phase*.8)+.012*sin(VERTEX.z*3.+phase*1.3);
 VERTEX+=NORMAL*displacement;
 local_p=VERTEX;
}
float lamp(vec3 d,vec3 axis,float radius,float blur){return 1.-smoothstep(radius-blur,radius+blur,acos(clamp(dot(d,normalize(axis)),-1.,1.)));}
void fragment(){
 vec3 n=normalize(NORMAL);
 vec3 v=normalize(VIEW);
 float facing=max(dot(n,v),0.);
 float fresnel=.0204+.9796*pow(1.-facing,5.);
 vec3 tint=vec3(.03,.42,.9);
 if(lobes>=2){
  tint=mix(vec3(.03,.42,.9),vec3(.95,.12,.36),smoothstep(-.35,.35,local_p.x));
 }
 if(lobes==3){tint=mix(tint,vec3(.97,.65,.06),smoothstep(.02,.65,local_p.y));}
 vec2 warp=n.xy*vec2(-.035,.035)*(1.-.4*facing);
 vec3 bg=textureLod(screen_tex,clamp(SCREEN_UV+warp,vec2(.001),vec2(.999)),.0).rgb;
 vec3 transmitted=bg*mix(vec3(1.),tint,.48);
 transmitted+=tint*.16*facing;
 vec3 reflected=vec3(.16,.23,.29);
 vec3 r=reflect(-v,n);
 reflected+=vec3(.83,.94,1.)*lamp(r,vec3(-.8,1.2,.6),.42,.09)*20.;
 reflected+=vec3(.56,.84,1.)*lamp(r,vec3(1.4,.3,-.6),.33,.10)*3.;
 vec3 col=mix(transmitted,reflected,fresnel);
 // Surface tension gives one shared contour and flexible neck, not crystal facets.
 col+=tint*.28*pow(1.-facing,3.);
 ALBEDO=pow(max(col/(vec3(1.)+col*.25),vec3(0.)),vec3(.75));
}
