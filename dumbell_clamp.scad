
Part_Selection = 0; // [0:Clamp, 1:Top, 2:Bottom, 3:Latch_Part1, 4:Latch_Part2, 5:None]
Bar_Diameter = 25;
Compression = 0.7;
Joint_Diameter = 15;
Bumper_Height = 1.5;
Bumper_Angle = 80;
Lever_Hole_Dist = 7.5;
Lever_Overhang = 9;

Height = 33;

Edge_Height = 1;
Edge_Radius = 7;

Bolt_Size = 0; // [0:M3, 1:M4, 2:M5]
Hinge_Type = 0; // [0:Bolt, 1:Pin]

Groove_Width = 5;
Groove_Height = 5;
Groove_Offset = -2;
Groove_Count = 1;

Grooves = true;
Bridges = false;
Cut_in_Half = false;
Second_Half = false;

/* [Hidden] */

od = Bar_Diameter+2*Joint_Diameter+2*Bumper_Height;
id = Bar_Diameter+2*Bumper_Height;
bar_d = Bar_Diameter - Compression;
bar_r = bar_d/2;
sub_h = Height/3;
alpha = (180-Bumper_Angle)/2;
joint_t = 0.8;
jd = Joint_Diameter + joint_t;
t = 0.25;
w = (od/2)*cos(30)*2;

Joint_Radius = Joint_Diameter/2;
jr = id/2+Joint_Radius;

//Kosinussatz https://de.wikipedia.org/wiki/Kosinussatz
function law_of_cos(a, b, gamma) = sqrt(a*a+b*b-2*a*b*cos(gamma));
function law_of_acos(a, b, c) = acos((a*a+b*b-c*c)/(2*a*b));
beta = law_of_acos(id/2+Joint_Radius, id/2+Joint_Radius, Joint_Diameter);
echo("beta", beta);

groove_dist = law_of_cos(bar_r, bar_r, Bumper_Angle);

$fn=30;

// Gewindedurchmesser, Schraubenkopfdurchmesser, Schraubenkopfhöhe
bolt_specs = [
    [3, 5.5, 3],
    [4, 7, 4],
    [5, 8.5, 5]
];
bolt_spec_t = [0.4, 0.7, 0.2];

// width across flats, thickness
nut_specs = [
    [5.5, 2.4],
    [7, 3.2],
    [8, 4.7]
];
nut_spec_t = [0.4, 0.3];

bolt_spec = bolt_specs[Bolt_Size];
nut_spec = nut_specs[Bolt_Size];

hinge_d = (Hinge_Type == 0) ? bolt_spec[0] + bolt_spec_t[0] : bolt_spec[0] + 0.1;
bolt_head_d = bolt_spec[1] + bolt_spec_t[1];
bolt_head_h = bolt_spec[2] + bolt_spec_t[2];
nut_w = nut_spec[0] + nut_spec_t[0];
nut_h = nut_spec[1] + nut_spec_t[1];

gamma = law_of_acos(id/2+Joint_Radius, id/2+Joint_Radius, Lever_Hole_Dist);
Latch_Angle = beta+gamma;

module hinge_base(Height=Height) {
    cylinder(d=hinge_d, h=Height);
}

//hinge_cut();

module hinge_cut(Height=Height) {

    layer_h = 0.2;

    if(Hinge_Type == 0) { //Bolt
        rotate(30)
        nut(nut_w, nut_h);

        if (Bridges) {
            hinge_h = Height-bolt_head_h-nut_h-2*layer_h;
            translate([0,0,nut_h+layer_h])
            hinge_base(hinge_h);
        }
        else {
            hinge_base();
        }

        translate([0,0,Height-bolt_head_h])
        cylinder(d=bolt_head_d, h=bolt_head_h);

        
    } else {
        hinge_base();
    }
}

module nut(w, h){
    $fn = 6;
    r = w/sqrt(3);
    cylinder(r=r, h=h);
}

module hexagon(d, h, e=Edge_Height) {
    r = d/2 - Edge_Radius/2;

    hull(){
        for(i = [0:5]){
            rotate([0,0,60*i])
            translate([r, 0])
            pillar(Edge_Radius, Edge_Radius-2*Edge_Height, h, Edge_Height);
        }
    }
}

//hexagon(od, Height);

module cone(d1, d2, h, angle=360) {
    r1 = d1/2;
    r2 = d2/2;
    
    rotate_extrude(angle=angle, convexity=10)
    polygon([
        [0,0],
        [r1, 0],
        [r2, h],
        [0, h]
    ]);
}

module rcube(size, e=-Edge_Height, r=Edge_Radius) {
    d = 2*r;
    s = [size[0]-d, size[1]-d, size[2]];

    translate([r,r])
    union(){
        long_pillar(d, d+2*e, s[2], abs(e), s[0]);
    
        translate([0, s[1]])
        long_pillar(d, d+2*e, s[2], abs(e), s[0]);
        
        rotate([-90,0,0])
        linear_extrude(s[1])
        projection()
        rotate([90,0,0])
        long_pillar(d, d+2*e, s[2], abs(e), s[0]);
    }
    
    
}

module pillar(d, base_d, h, base_h, angle=360) {
    cone(base_d, d, base_h, angle);
    translate([0, 0, base_h])
    cone(d, d, h-2*base_h, angle);
    translate([0, 0, h-base_h])
    cone(d, base_d, base_h, angle);
}

module long_pillar(d, base_d, h, base_h, l){
    
    pillar(d, base_d, h, base_h);
    translate([l,0])
    pillar(d, base_d, h, base_h);

    translate([l,0])
    rotate([0,-90,0])
    linear_extrude(l)
    projection()
    rotate([0,90,0])
    pillar(d, base_d, h, base_h);
    
}

function reverse(vec) = [for(i = [len(vec)-1:-1:0]) vec[i]];

function sum(vec, i=0) = vec[i] + 
    (i < len(vec)-1 ? sum(vec, i+1) : 0);

module pillar2(d, h, angle=360) {

    rh = reverse(h);

    for(i = [0:len(d)-2]) {
        z = (i > 0) ? sum(rh, len(rh)-i) : 0;
        translate([0, 0, z])
        cone(d[i], d[i+1], h[i], angle);
    }
}

module part_base(h) {

    difference(){
        union() {
            difference(){
                hexagon(od, h);

                translate([-od/2, -od/2, 0])
                cube([od, od/2, h]);
            }

            translate([id/2+Joint_Diameter/2,0])
            rotate([0,0,180])
            pillar(Joint_Diameter, Joint_Diameter-2*Edge_Height, h, Edge_Height, angle=180);

            translate([-id/2-Joint_Diameter/2,0])
            rotate([0,0,180])
            pillar(Joint_Diameter, Joint_Diameter-2*Edge_Height, h, Edge_Height, angle=180);
        }
        union() {
            pillar(id, id+2*Edge_Height, h, Edge_Height, angle=alpha+0.01);

            rotate([0,0,180-alpha])
            pillar(id, id+2*Edge_Height, h, Edge_Height, angle=alpha+0.01);

            rotate([0,0,alpha-1])
            pillar(bar_d, id+2*Edge_Height, h, 2*Edge_Height, angle=Bumper_Angle+2);
        }
    }
}

// part_base(Height);

module top() {

    module cut() {
        cone(od+10, od+10, Height, 90);
    }

    module cut2() {
        rotate(120)
        cone(od+10, od+10, Height, 180);
    }

    difference(){
        part_base(Height);
    
        translate([-id/2-Joint_Diameter/2, 0, sub_h-t])
        cylinder(d=jd, h=sub_h+2*t);

        rotate(-30)
        cut();

        cut2();

        rotate(beta)
        translate([id/2+Joint_Diameter/2, 0, sub_h])
        cylinder(d=jd, h=sub_h);
    }

    difference(){
        union(){
            rotate(beta)
            translate([id/2+Joint_Diameter/2,0])
            rotate([0,0,180])
            pillar(Joint_Diameter, Joint_Diameter-2*Edge_Height, Height, Edge_Height);

            intersection() {
                part_base(Height);
                
                rotate(beta)
                cone(od+10, od+10, Height, 60-beta);
            }
        }

        rotate(beta)
        translate([id/2+Joint_Diameter/2, 0, sub_h])
        cylinder(d=jd, h=sub_h);
    }

    intersection(){
        union(){
            part_base(sub_h-t);

            translate([0,0,Height-sub_h+t])
            part_base(sub_h-t);
        }
        
        cut2();
    }

}

module top_part() {
    difference(){
        top();
        
        translate([-jr, 0])
        hinge_cut();

        rotate(beta)
        translate([+jr, 0])
        rotate(-beta)
        hinge_cut();

        if (Grooves) {
            translate([0, w/2+0.5, 0])
            groove_cuts();
        }

        if (Cut_in_Half) {
            translate([0,0, Second_Half ? 0 : Height/2])
            cylinder(d=od+10,h=Height/2);
        }
    }
}

module bottom() {

    lever_w = (w-id)/2;

    module cut() {
        rotate(120)
        cone(od+10, od+10, Height, 180);
    }

    difference(){
        part_base(Height);

        translate([jr, 0, 0])
        pillar2([jd+2*Edge_Height, jd, jd], [Edge_Height, sub_h-Edge_Height]);

        translate([jr, 0, Height-sub_h])
        pillar2([jd, jd, jd+2*Edge_Height], [sub_h-Edge_Height, Edge_Height]);

        rotate(60)
        translate([-od/4,w/2-lever_w/2+Edge_Height,sub_h/2])
        lever(Height-sub_h, e=0);

        cut();
    }

    intersection(){
        union(){
            part_base(sub_h/2);

            translate([0,0,Height-sub_h/2])
            part_base(sub_h/2);
        }
        
        cut();
    }
}

module bottom_part() {
    difference() {
        bottom();

        translate([+jr, 0])
        hinge_cut();

        translate([-jr, 0])
        union() {
            cylinder(d=bolt_head_d, h=bolt_head_h);

            hinge_base();

            translate([0,0,Height-bolt_head_h])
            cylinder(d=bolt_head_d, h=bolt_head_h);
        }

        if (Grooves) {
            translate([0, w/2+0.5, 0])
            groove_cuts();
        }

        if (Cut_in_Half) {
            translate([0,0, Second_Half ? 0 : Height/2])
            cylinder(d=od+10,h=Height/2);
        }
    }
}

module _latch_part1() {

    h = sub_h-2*t;

    intersection(){
        difference(){
            pillar(od, od-2*Edge_Height, h, Edge_Height);
            pillar(id, id+2*Edge_Height, sub_h, Edge_Height);
        }
        
        cone(od+10, od+10, sub_h, Latch_Angle);
    }

    translate([jr,0])
    pillar(Joint_Diameter, Joint_Diameter-2*Edge_Height, h, Edge_Height);

    rotate(Latch_Angle)
    translate([jr,0])
    pillar(Joint_Diameter, Joint_Diameter-2*Edge_Height, h, Edge_Height);
}

module latch_part1() {
    difference(){
        _latch_part1();
        
        translate([jr,0,0])
        hinge_base();

        rotate(Latch_Angle)
        translate([jr,0,0])
        hinge_base();
        
    }
}

module lever_base(h, width, l=od/2-1, e=Edge_Height, cut=3) {
    
    difference() {
        long_pillar(width, width-2*e, h, e, l-width);

        translate([-width/2, -width/2, 0])
        cube([width, width, h]);
    }

}

module lever(h, e=Edge_Height){
    lever_w = (w-id)/2;
    lever_l1 = od/2-1;
    lever_l2 = od/2+Lever_Overhang;

    difference() {
        union() {
            lever_base(h, lever_w, lever_l1, e=e);
            translate([0,lever_w/4])
            lever_base(h, lever_w/2, lever_l2, e=e);
        }
        
        translate([0,lever_w/2, (h-sub_h)/2])
        rotate([90,0,0])
        rcube([lever_l1-lever_w, sub_h, lever_w], e=Edge_Height, r=2);
    }
}

//lever(20);

module _latch_part2(h) {

    module bean(jd, h=sub_h/2-t) {
        hull(){
            translate([id/2+Joint_Diameter/2,0])
            pillar(jd, jd-2*Edge_Height, h, Edge_Height);

            rotate(beta-Latch_Angle)
            translate([id/2+Joint_Diameter/2,0])
            pillar(jd, jd-2*Edge_Height, h, Edge_Height);
        }
    }

    bean(Joint_Diameter);

    translate([0,0,h-sub_h/2+t])
    bean(Joint_Diameter);

    difference(){
        translate([od/2-(w-id)/4, 0])
        rotate(-120) {
            lever(h);
        }

        translate([0, 0, (h-sub_h)/2])
        bean(jd, sub_h);
    }
    
}

module latch_part2() {

    h = Height-sub_h-2*t;
    h2 = sub_h/2-t;
    echo("latch_part2_h", h);

    difference() {
        _latch_part2(h);
        
        translate([jr,0,0]){
            hinge_base();
            
            if (Hinge_Type == 0) {
                translate([0,0,h2-nut_h])
                nut(nut_w, nut_h);

                translate([0,0,h-h2])
                nut(nut_w, nut_h);
            }
        }
        

        rotate(beta-Latch_Angle)
        translate([jr,0,0])
        rotate(-beta+Latch_Angle+30)
        hinge_cut(h);
    }
}

module groove(w, h, l, p=0.8) {
    w2 = w*p;
    e = (w-w2)/2;

    translate([-w/2,-2*e,0])
    rotate([90,0,0])
    rcube([w, l, h-2*e], r=1, e=-e);

    translate([e-w/2,0,0])
    rotate([90,0,0])
    rcube([w-2*e, l, 3*e], r=1, e=e);
}

module groove_cuts() {
    dist = groove_dist + 2*Groove_Offset;
    dist2 = Height/(Groove_Count+1);

    translate([-dist/2, 0, -5])
    groove(Groove_Width, Groove_Height, Height+10);

    translate([dist/2, 0, -5])
    groove(Groove_Width, Groove_Height, Height+10);

    translate([dist/2, 0, dist2])
    rotate([0,-90,0]) {
        for(i = [0:Groove_Count-1]) {
            translate([dist2*i, 0, 0])
            groove(Groove_Width, Groove_Height, dist);
        }

        groove(Groove_Width, Groove_Height, dist);

        
    }
    
}

//groove_cuts();

module clamp() {
    top_part();
    rotate(180)
    bottom_part();
    translate([0,0,sub_h+t])
    rotate(beta-Latch_Angle)
    latch_part1();
    translate([0,0,sub_h/2])
    translate([0,0,t])
    latch_part2();
}

module part() {
    if (Part_Selection == 0) {
        clamp();
    } 
    if (Part_Selection == 1) {
        if (Cut_in_Half && Second_Half) {
            rotate([0,180,0])
            translate([0,0,-Height])
            top_part();
        } else {
            top_part();
        }
    }
    if (Part_Selection == 2) {
        if (Cut_in_Half && Second_Half) {
            rotate([0,180,0])
            translate([0,0,-Height])
            bottom_part();
        } else {
            bottom_part();
        }
    }
    if (Part_Selection == 3) {
        latch_part1();
    }
    if (Part_Selection == 4) {
        latch_part2();
    }
}

part();