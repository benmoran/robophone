width = 80;
length = 150;
depth = 25;
thickness = 2;

lidheight=7;
gap = 0.5;

phonethick = 12;
backheight= 70;
frontheight = 10;


module chassis() { 
     difference() {
	  translate([-thickness,-thickness,-thickness])
	    cube([width+2*thickness,length+2*thickness,depth]);
     cube([width,length,depth+thickness]);
     }
}


module lid() {
//lid

	  union() {

	  translate([0,0,depth-lidheight])
	       difference() {
	       translate([-thickness*2,-thickness*2,0])
		    cube([width+4*thickness,
			  length+4*thickness,
			  lidheight+thickness]);
    
	       translate([-thickness-gap,-thickness-gap,-gap])
		    cube([width+2*(thickness+gap),
			  length+2*(thickness+gap),
			  lidheight+gap]);
	  }
     }
}


module phoneholder() {
    
     translate([2*thickness+width,
		length/2,depth])
	  rotate([20,0,180])
	  union() {
	  cube([width+4*thickness,thickness,backheight]);
	  translate([0,phonethick,0])
	       cube([width+4*thickness,thickness,thickness+phonethick]);
	  translate([0,0,0])
	       cube([width+4*thickness,phonethick,thickness]);

     
      }
  }
//lid()

module guts() {
    
	  union() {
	       wbatt = 67;
	       hbatt = 20;

//motor battery pack
	       translate([0,-3,0])
		    translate([(width - wbatt)/2, (length-wbatt)/2,0]) {
		    cube([wbatt,wbatt,hbatt]);
	       }

//small battery

	       wbatt1 = 52;
	       lbatt1 = 25;

	       translate([(width - wbatt1)/2,10,0]) {
		    cube([wbatt1,lbatt1,hbatt]);
	       }
           
           //microbit
           translate([(width - 51)/2, 8,0])
            cube([51,5,42]);

            // connectors
           translate([18,length - 25,0])
            cube([20,23,20]);
           
           translate([width-23-18,length - 25,0])
            cube([20,23,20]);
           
	       translate([17+thickness,length-40,0])
		    rotate([90,0,0])
		    import("Continous_servo_FS90R_v4.stl");

	       translate([width-19,length-35+24,0])
		    rotate([90,0,180])
		    import("Continous_servo_FS90R_v4.stl");
	  }
  }


  
//  chassis();
//  lid();
//  phoneholder()
  
module top() {
    lid();
    phoneholder();
}

 difference() {

	  union() {
	      // chassis();
 
          translate([0,0,0]) 
            top();
	  }
	  guts();

     }



