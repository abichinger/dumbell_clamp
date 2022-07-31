
Part_Selection = 0; // [0:Clamp, 1:Top, 2:Bottom, 3:Latch_Part1, 4:Latch_Part2]
Bar_Diameter = 25;
Compression = 1;
Joint_Diameter = 16;
Bumper_Height = 1.5;
Bumper_Angle = 80;
Latch_Angle = 60;
Latch_Overhang = 7;

Height = 33;

Edge_Height = 1;
Edge_Radius = 7;

Bolt_Size = 0; // [0:M3, 1:M4, 2:M5]
Hinge_Type = 0; // [0:Bolt, 1:Peg]

/* [Hidden] */

od = Bar_Diameter+2*Joint_Diameter+2*Bumper_Height;
id = Bar_Diameter+2*Bumper_Height;
bar_d = Bar_Diameter - Compression;
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

$fn=30;

// Gewindedurchmesser, Schraubenkopfdurchmesser, Schraubenkopfhöhe
bolt_specs = [
    [3, 5.5, 3],
    [4, 7, 4],
    [5, 8.5, 5]
];
bolt_spec_t = [0.4, 0.6, 0.2];

// width across flats, thickness
nut_specs = [
    [5.5, 2.4],
    [7, 3.2],
    [8, 4.7]
];
nut_spec_t = [0.3, 0.3];

bolt_spec = bolt_specs[Bolt_Size];
nut_spec = nut_specs[Bolt_Size];

hinge_d = (Hinge_Type == 0) ? bolt_spec[0] + bolt_spec_t[0] : bolt_spec[0] + 0.1;
bolt_head_d = bolt_spec[1] + bolt_spec_t[1];
bolt_head_h = bolt_spec[2] + bolt_spec_t[2];
nut_w = nut_spec[0] + nut_spec_t[0];
nut_h = nut_spec[1] + nut_spec_t[1];

module hinge_base(Height=Height) {
    cylinder(d=hinge_d, h=Height);
}

//hinge_cut();

module hinge_cut(Height=Height) {
    hinge_base();
    if(Hinge_Type == 0) { //Bolt
        translate([0,0,Height-bolt_head_h])
        cylinder(d=bolt_head_d, h=bolt_head_h);

        rotate(30)
        nut(nut_w, nut_h);
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

            rotate([0,0,alpha])
            pillar(bar_d, id+2*Edge_Height, h, 2*Edge_Height, angle=Bumper_Angle);
        }
    }
}

module top() {

    module cut() {
        cone(od+10, od+10, Height, 90);
    }

    difference(){
        part_base(Height);
    
        translate([-id/2-Joint_Diameter/2, 0, sub_h-t])
        cylinder(d=jd, h=sub_h+2*t);

        rotate(-30)
        cut();
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

    

}

module top_part() {
    difference(){
        top();
        
        translate([-jr, 0])
        hinge_cut();

        rotate(beta)
        translate([+jr, 0])
        hinge_cut();
    }
}

module bottom() {

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

        rotate(180)
        translate([0,0,sub_h/2])
        latch_base(Height-sub_h,(w-id)/4, od/2+Latch_Overhang, e=0);

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

        translate([-jr, 0])
        hinge_cut();

        translate([+jr, 0])
        hinge_cut();
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

module latch_base(h, width, l=od/2-1, e=Edge_Height) {
    
    difference() {
        translate([od/2-(w-id)/4, 0])
        rotate(-120)
        translate([0, (w-id)/4-width/2])
        long_pillar(width, width-2*e, h, e, l-width);

        translate([od/2-5, -width, 0])
        cube([width*2, width*2, h]);
    }

}

//latch_base(10, 5);

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
        union(){
            latch_base(h,(w-id)/2);
            latch_base(h,(w-id)/4, od/2+Latch_Overhang);
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
        //rotate(-beta+Latch_Angle)
        hinge_cut(h);
    }
}

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

module part(rotate=false) {
    if (Part_Selection == 0) {
        clamp();
    } 
    if (Part_Selection == 1) {
        rotate([rotate ? -90 : 0,0,0])
        top_part();
    }
    if (Part_Selection == 2) {
        rotate([rotate ? -90 : 0,0,0])
        bottom_part();
    }
    if (Part_Selection == 3) {
        latch_part1();
    }
    if (Part_Selection == 4) {
        latch_part2();
    }
}

part();