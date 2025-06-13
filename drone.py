#!/usr/bin/env python3

import re

from scapy.all import *

class Drone(Packet): #creates packet structure to send
    name = "drone"
    fields_desc = [ IntField("droneid", 0),
    				IntField("x", 0),
                    IntField("y", 0),
                    IntField("z", 0),
                    IntField("xact", 0),
                    IntField("yact", 0),
                    IntField("zact", 0),
                    IntField("coll", 0)]
     
bind_layers(Ether, Drone, type=0x1234) #binds the layers together



#Creates classes
class NumParseError(Exception):
    pass

class OpParseError(Exception):
    pass

class Token:
    def __init__(self,type,value = None):
        self.type = type
        self.value = value


#main loop
def main():
    iface = "enx0c37965f8a24" #defines interface of lab machine
    while True:
    
    	#asks for user to input the drone positions and then splits the string into a list
        s = input('Input drone id, x coordinate, y coordinate as "id x y z": ').split(' ') 
        
        if s[0] == "quit":
            break
            
        try:
            pkt = Ether(dst='e4:5f:01:84:ad:1a', type=0x1234) / Drone(droneid=int(s[0]), x=int(s[1]), y=int(s[2]), z=int(s[3])) #creates packet and adds the user inputs to the header
            
            
            pkt = pkt/' '
            pkt.show() #shows the packet
            
            resp = srp1(pkt, iface=iface,timeout=5, verbose=False) #the packet that got sent back
            
            if resp:
            	drone=resp[Drone]
            	if drone: #outputs the relevant information to the user from received packet 
                    print("x action:", resp.xact)
                    print("y action:", resp.yact)
                    print("z action:", resp.zact)
                    print("Collision:", resp.coll)
                    print("0: ok, 1: left, 2: right, 3: backward, 4: forward, 5: down, 6: up")
            	else:
                    print("Cannot find drone header in the packet") #error output for user
            else:
            	print("Didn't receive response") #error output for user
                

        except Exception as error:
            print(error)


if __name__ == '__main__':
    main()

