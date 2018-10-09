///// Senkloch ////////////////////////////////////////////////////////////////
module ScrewHole(d,l) {
   r = d / 2;
   h = l;
   union() {
      // Schraubenloch
      translate([0,0,l/2])  cylinder(h=h, r1=r,   r2=r, center=true);
      // Senkung
      translate([0,0,0.45*r])  cylinder(h=1.1*r, r1=2.2*r, r2=r, center=true);
      // Loch um die Schraube triefer zu versenken
      translate([0,0,-l-0.1*r+0.01]) cylinder(h=2*l, r=2.2*r, center=true);
   }
}

///// Schraubloch für metrische Schrauben /////////////////////////////////////
module DrillHole(d,l) {
   d0 = d * 0.8;
   translate([0,0,l/2]) cube([d0,d0,l], true);
}

///// Sechskantloch für Mutten ////////////////////////////////////////////////
module HexaHole(w,h) {
//   intersection() {
   
   union() {
      cube([w,0.5773*w,h],true);
      rotate( 120,[0,0,1]) cube([w,0.5773*w,h],true);
      rotate(-120,[0,0,1]) cube([w,0.5773*w,h],true);
   }
}

///// Sechskantloch für Schrauben /////////////////////////////////////////////
module HexaScrewHole(d,w,h) {
   union() {
      translate([0,0,-h/2]) HexaHole(w+0.4,h);
      translate([0,0,-h]) cylinder(d=d, h=2*h);
   }
}

///// Quader mit angerundeten Kanten //////////////////////////////////////////
// size is a vector [w, h, d]
module RoundBox(size, radius, center=true)
{
   rot = [ [0,0,0], [90,0,90], [90,90,0] ];
   ttt = center ?  [0,0,0]: [ size[0]/2, size[1]/2, size[2]/2 ];
   
   translate(ttt) {
      cube([size[0], size[1]-radius*2, size[2]-radius*2], center=true);
      cube([size[0]-radius*2, size[1], size[2]-radius*2], center=true);
      cube([size[0]-radius*2, size[1]-radius*2, size[2]], center=true);

      for (axis = [0:2]) {
         for (x = [radius-size[axis]/2, -radius+size[axis]/2],
              y = [radius-size[(axis+1)%3]/2, -radius+size[(axis+1)%3]/2]) {
            rotate(rot[axis])
            translate([x,y,0])
            cylinder(h=size[(axis+2)%3]-2*radius, r=radius, center=true);
         }
      }
      for (x = [radius-size[0]/2, -radius+size[0]/2],
           y = [radius-size[1]/2, -radius+size[1]/2],
           z = [radius-size[2]/2, -radius+size[2]/2]) {
         translate([x,y,z]) sphere(radius);
      }
   }
}

///// Paltte mit angerundeten Kanten //////////////////////////////////////////
module RoundPlate(dim, r, center = true) {
   xw = dim[0] - 2*r;
   yw = dim[1] - 2*r;
   zw = dim[2];

   if ( center == true ) 
   {
      cube([xw,dim[1],zw],true);
      cube([dim[0],yw,zw],true);
      translate([ xw/2, yw/2,0]) cylinder(r=r,h=zw,center=true);
      translate([-xw/2, yw/2,0]) cylinder(r=r,h=zw,center=true);
      translate([ xw/2,-yw/2,0]) cylinder(r=r,h=zw,center=true);
      translate([-xw/2,-yw/2,0]) cylinder(r=r,h=zw,center=true);
   } else {   
      minkowski() {
         translate ([r,r,0]) cube([xw,yw,zw],center);
         cylinder(h=0.00001,r1=r,r2=r,center);
      }
   }
}

