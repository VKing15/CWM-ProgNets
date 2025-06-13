/* -*- P4_16 -*- */

/*
 * P4 Drone
 *
 * This program implements a simple protocol. It can be carried over Ethernet
 * (Ethertype 0x1234).
 *
 *
 * If an unknown operation is specified or the header is not valid, the packet
 * is dropped
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
const bit<8>  DRONE_D     = 0x44;   // 'D'

header drone_t {
/* 
 * drone_t header with x, y, z, xact, yact and zact
 */
	bit<32>	x;
	bit<32>	y;
	bit<32>	z;
	bit<32>	xact;
	bit<32>	yact;
	bit<32>	zact;
}


/* 
 * Structure of headers
 */
 
struct headers {
    ethernet_t   ethernet;
    drone_t     drone;
}
 
 /*
 * No metadata
 */

struct metadata {
    /* Empty */
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
control MyIngress(inout headers hdr,
                  inout metadata meta,
                  inout standard_metadata_t standard_metadata) {
                  
                  
    action send_back() {
		//swap MAC addresses
		bit<48> tmp_mac;
		tmp_mac = hdr.ethernet.dstAddr;
		hdr.ethernet.dstAddr = hdr.ethernet.srcAddr;
		hdr.ethernet.srcAddr = tmp_mac;
		
		//send it back to the same port
		standard_metadata.egress_spec = standard_metadata.ingress_port;
		
	}
	              
	
 	action x_okay() {
 		hdr.drone.xact = 0;
        send_back(); 
    }
    action y_okay() {
 		hdr.drone.yact = 0;
        send_back(); 
    }
    action z_okay() {
 		hdr.drone.zact = 0;
        send_back(); 
    }
    
 	action left() {
 		hdr.drone.xact = 1;
        send_back(); 
    }
 	action right() {
        hdr.drone.xact = 2;
        send_back(); 
    }
    action backward() {
        hdr.drone.yact = 3;
        send_back(); 
    }
    action forward() {
        hdr.drone.yact = 4;
        send_back(); 
    }
    action up() {
        hdr.drone.zact = 5;
        send_back();  
    }
    action down() {
        hdr.drone.zact = 6;
        send_back(); 
    }
    
    action operation_drop() {
        mark_to_drop(standard_metadata);
    }
    
    
    
    
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
    
    
    
    
    apply {
        if (hdr.drone.isValid()) {
            xact_table.apply();
            yact_table.apply();
            zact_table.apply();
        } else {
            operation_drop();
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

 
 
 
