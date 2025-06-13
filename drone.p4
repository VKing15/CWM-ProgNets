/* -*- P4_16 -*- */

/*
 * P4 Drone
 *
 * Please see the Exercise 6.pdf for detailed instructions of what the program does
 *
 */

#include <core.p4>
#include <v1model.p4>

/*
 * Define the headers the program will recognize
 */

/*
 * Standard Ethernet header
 */
header ethernet_t {
    bit<48> dstAddr;
    bit<48> srcAddr;
    bit<16> etherType;
}

/*
 * This is a custom protocol header for the drone. We'll use
 * etherType 0x1234 for it (see parser)
 */

const bit<16> DRONE_ETYPE = 0x1234;

header drone_t {
/* 
 * drone_t header with id, x, y, z, xact, yact and zact
 */
 	bit<32> droneid;
	bit<32>	x;
	bit<32>	y;
	bit<32>	z;
	bit<32>	xact;
	bit<32>	yact;
	bit<32>	zact;
	bit<32>	coll;
}


/* 
 * Structure of headers
 */
 
struct headers {
    ethernet_t   ethernet;
    drone_t     drone;
}
 
struct metadata { 
    bit<32>	xcoord;
	bit<32>	ycoord;
	bit<32>	zcoord;
	bit<32>	xclean;
	bit<32>	yclean;
	bit<32>	zclean;  
}

/*************************************************************************
 ***********************  P A R S E R  ***********************************
 *************************************************************************/
 
parser MyParser(packet_in packet,
                out headers hdr,
                inout metadata meta,
                inout standard_metadata_t standard_metadata) {
    state start {
        packet.extract(hdr.ethernet);
        transition select(hdr.ethernet.etherType) {
            DRONE_ETYPE : parse_drone;
            default      : accept;
        }
    }

    state parse_drone {
        packet.extract(hdr.drone);
        transition accept;
    }
}
 
/*************************************************************************
 ************   C H E C K S U M    V E R I F I C A T I O N   *************
 *************************************************************************/
control MyVerifyChecksum(inout headers hdr,
                         inout metadata meta) {
    apply { }
}

/*************************************************************************
 **************  I N G R E S S   P R O C E S S I N G   *******************
 *************************************************************************/


//3 registers to store the ids of the drones in the 20x20 grid
register<bit<32>>(20) xco;
register<bit<32>>(20) yco;
register<bit<32>>(20) zco;

///3 registers to store the old coordinates of the drone at the appropriate id
register<bit<32>>(100) xold;
register<bit<32>>(100) yold;
register<bit<32>>(100) zold;

control MyIngress(inout headers hdr,
                  inout metadata meta,
                  inout standard_metadata_t standard_metadata) {
                  
    //sends back the packet with swapped ids         
    action send_back() {
		//swap MAC addresses
		bit<48> tmp_mac;
		tmp_mac = hdr.ethernet.dstAddr;
		hdr.ethernet.dstAddr = hdr.ethernet.srcAddr;
		hdr.ethernet.srcAddr = tmp_mac;
		
		//send it back to the same port
		standard_metadata.egress_spec = standard_metadata.ingress_port;	
	}
	              
	//actions for the tables to tell the drone where to move 
 	action x_okay() {
 		hdr.drone.xact = 0;
    }
    
    action y_okay() {
 		hdr.drone.yact = 0;
    }
    
    action z_okay() {
 		hdr.drone.zact = 0;
    }

 	action left() {
 		hdr.drone.xact = 1;
    }
    
 	action right() {
        hdr.drone.xact = 2; 
    }
    
    action backward() {
        hdr.drone.yact = 3;
    }
    
    action forward() {
        hdr.drone.yact = 4; 
    }
    
    action down() {
        hdr.drone.zact = 5; 
    }
    
    action up() {
        hdr.drone.zact = 6;
    }
    
    action operation_drop() {
        mark_to_drop(standard_metadata);
    }
    

	//tables use range to see whether the drone is to close to the edge of the coordinate space
    table xact_table {
        key = {
            hdr.drone.x        : range;
        }
        actions = {
            x_okay();
            left();
            right();
            operation_drop();
        }
        const default_action = operation_drop();
        const entries = {
            3..17	:	x_okay();
            18..20	:	left();
            0..2	:	right();
        }
    }
    
    table yact_table {
        key = {
            hdr.drone.y        : range;
        }
        actions = {
            y_okay();
            backward();
            forward();
            operation_drop();
        }
        const default_action = operation_drop();
        const entries = {
            3..17	:	y_okay();
            18..20	:	backward();
            0..2	:	forward();
        }
    }
    

    
    table zact_table {
        key = {
            hdr.drone.z        : range;
        }
        actions = {
            z_okay();
            down();
            up();
            operation_drop();
        }
        const default_action = operation_drop();
        const entries = {
            3..17	:	z_okay();
            18..20	:	down();
            0..2	:	up();
        }
    }
    
    
    //used to remember the drone positions
    action registerwrite() {
    
    	//reads the old location of the drone
 		xold.read(meta.xclean,hdr.drone.droneid);
 		yold.read(meta.yclean,hdr.drone.droneid);
 		zold.read(meta.zclean,hdr.drone.droneid);
 		
 		//deletes the drones old positions 
 		xco.write(meta.xclean,0);
 		yco.write(meta.yclean,0);
 		zco.write(meta.zclean,0);
 		
 		//places the new location into the registers
 		xco.write(hdr.drone.x,hdr.drone.droneid);
 		yco.write(hdr.drone.y,hdr.drone.droneid);
 		zco.write(hdr.drone.z,hdr.drone.droneid);
 		
 		//updates the register so that this new position becomes the next iterations old position
 		xold.write(hdr.drone.droneid,hdr.drone.x);
 		yold.write(hdr.drone.droneid,hdr.drone.y);
 		zold.write(hdr.drone.droneid,hdr.drone.z);
    }
    
	action registerread() {
	
		//reads the location of the drone to see whether its occupied
 		xco.read(meta.xcoord,hdr.drone.x);
 		yco.read(meta.ycoord,hdr.drone.y);
 		zco.read(meta.zcoord,hdr.drone.z);
    }
    
    apply {
        if (hdr.drone.isValid()) { //uses the table to check whether it will drift
            xact_table.apply();
            yact_table.apply();
            zact_table.apply();
        
        
		    //checks if the drone is within the safety margin
		    if (hdr.drone.xact == 0 && hdr.drone.yact == 0 && hdr.drone.zact == 0){ 
		    
		    	//gets the locations
		    	registerread();
		    	
		    	//checks that at least one axis is different to confirm that its empty 
		    	if (meta.xcoord==0 || meta.ycoord==0 || meta.zcoord==0) { 
		    	
		    		//updates the loactions
	 				registerwrite();
	 				
	 				//adds to the header that there are no collisions 
		    		hdr.drone.coll=0; 
		    	}
		    	
		    	//checks whether the drone occupying this space is itself
		    	else if (meta.xcoord==hdr.drone.droneid && meta.ycoord==hdr.drone.droneid && meta.zcoord==hdr.drone.droneid) {
		    		hdr.drone.coll=0; //adds to the header that there are no collisions
		    	}
		    	else { //another drone must be occupying this space
		    		hdr.drone.coll=1; //adds to the header that there are no collisions
		    		}
		    	}
		    send_back(); //sends back the packet after everything has been dropped
        } else {
            operation_drop(); //drops packet is header invalid
        }
    }
   
}
 
/*************************************************************************
 ****************  E G R E S S   P R O C E S S I N G   *******************
 *************************************************************************/
control MyEgress(inout headers hdr,
                 inout metadata meta,
                 inout standard_metadata_t standard_metadata) {
    apply { }
}
 
/*************************************************************************
 *************   C H E C K S U M    C O M P U T A T I O N   **************
 *************************************************************************/

control MyComputeChecksum(inout headers hdr, inout metadata meta) {
    apply { }
}
 
/*************************************************************************
 ***********************  D E P A R S E R  *******************************
 *************************************************************************/
control MyDeparser(packet_out packet, in headers hdr) {
    apply {
        packet.emit(hdr.ethernet);
        packet.emit(hdr.drone);
    }
}

/*************************************************************************
 ***********************  S W I T T C H **********************************
 *************************************************************************/

V1Switch(
MyParser(),
MyVerifyChecksum(),
MyIngress(),
MyEgress(),
MyComputeChecksum(),
MyDeparser()
) main;
