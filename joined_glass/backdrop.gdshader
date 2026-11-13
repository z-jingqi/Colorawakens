shader_type spatial;
render_mode unshaded;
varying vec3 world_p;
void vertex(){world_p=(MODEL_MATRIX*vec4(VERTEX,1.)).xyz;}
void fragment(){
 vec2 p=world_p.xy;
 vec3 col=mix(vec3(.40,.49,.58),vec3(.78,.84,.88),clamp(.5+p.y*.12,0.,1.));
 float ribbon=exp(-pow((p.x-.35*sin(p.y*.75))/.30,2.));
 col+=vec3(.18,.18,.16)*ribbon;
 float other=exp(-pow((p.x+1.6+.1*p.y)/.12,2.));
 ALBEDO=(col+vec3(.08,.09,.09)*other)*1.15;
}
