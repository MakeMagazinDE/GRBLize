include <./forms.inc>;

$fn=50;

x = 25   + 1;  // Länge des Deckels
y = 30.5 + 2;  // Breite des Deckels
z = 6;         // Höhe des Deckels
d = 2;         // Wandstärke
e = 0.001;     // epsilon

translate([0,0,6])
rotate(180,[1,0,0])
difference() {
   translate([-1,-1,0]) cube([x, y, z],false);

   translate([0,0,-e]) cube([x, y-d, 1.5],false);       // Leiterplatte
            
   translate([ 4.1275, 19.05,0]) {             // Befestigungsschrauben
      cylinder(d=2.5,h=20);
      translate([0,0,4/2 + 4]) HexaHole(4.8,4);
   }
   
   translate([ 4.1275, 11.43,0]) {
      cylinder(d=2.5,h=20);
      translate([0,0,4/2 + 4]) HexaHole(4.8,4);
   }
   
   translate([20.0025, 3.175,0]) {
      cylinder(d=2.5,h=20);
      translate([0,0,4/2 + 4]) HexaHole(4.8,4);
   }
   
   translate([20.0025,27.305,0]) {
      cylinder(d=2.5,h=20);
      translate([0,0,4/2 + 4]) HexaHole(4.8,4);
   }
                                                         // Bauelemente
   translate([7, (y-2-18)/2, -e]) cube([ 23-7, 18, 1.5+2.5],false);
   translate([1,          1, -e]) cube([ 15.5,  7, 1.5+2.5],false);
   translate([1,    y-2-7-1, -e]) cube([ 15.5,  7, 1.5+2.5],false);
   
                                                               // Kabel
   translate([ -5,(y-2-4.5)/2,-e]) cube([  8.5,4.5, 1.5+1.8],false);
   translate([ -5,(y-2-4.5)/2,-e]) cube([   20,4.5, 1.5+1.0],false);
   translate([4.5,(y-2-4.5)/2,-e]) cube([  8.5,4.5, 1.5+1.8],false);
}
