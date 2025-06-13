#!/usr/bin/env python3

import re

from scapy.all import *

class Drone(Packet):
    name = "drone"
    fields_desc = [ IntField("x", 0),
                    IntField("y", 0),
                    IntField("z", 0),
                    IntField("xact", 0),
                    IntField("yact", 0),
                    IntField("zact", 0)]
     

bind_layers(Ether, Drone, type=0x1234)

class NumParseError(Exception):
    pass

class OpParseError(Exception):
    pass

class Token:
    def __init__(self,type,value = None):
        self.type = type
        self.value = value
'''
def num_parser(s, i, ts):
    pattern = "^\s*([0-9]+)\s*"
    match = re.match(pattern,s[i:])
    if match:
        ts.append(Token('num', match.group(1)))
        return i + match.end(), ts
    raise NumParseError('Expected number literal.')


def op_parser(s, i, ts):
    pattern = "^\s*([-+&|^])\s*"
    match = re.match(pattern,s[i:])
    if match:
        ts.append(Token('num', match.group(1)))
        return i + match.end(), ts
    raise NumParseError("Expected binary operator '-', '+', '&', '|', or '^'.")


def make_seq(p1, p2):
    def parse(s, i, ts):
        i,ts2 = p1(s,i,ts)
        return p2(s,i,ts2)
    return parse
'''
def get_if():
    ifs=get_if_list()
    iface= "veth0-1" # "h1-eth0"
    #for i in get_if_list():
    #    if "eth0" in i:
    #        iface=i
    #        break;
    #if not iface:
    #    print("Cannot find eth0 interface")
    #    exit(1)
    #print(iface)
    return iface

def main():

    #p = make_seq(num_parser, make_seq(op_parser,num_parser))
    s = ''
    #iface = get_if()
    iface = "enx0c37965f8a24"

    while True:
        s = input('> ')
        if s == "quit":
            break
        print(s)
        try:
            #i,ts = p(s,0,[])
            pkt = Ether(dst='e4:5f:01:84:ad:1a', type=0x1234) / Drone(x=random.randint(1,20),
                                              y=random.randint(1,20),
                                              z=random.randint(1,20))

            pkt = pkt/' '

            pkt.show()
            
            resp = srp1(pkt, iface=iface,timeout=5, verbose=False)
            if resp:
                drone=resp[Drone]
                if drone:
                    #resp.show()
                    print("x action:", resp.xact)
                    print("y action:", resp.yact)
                    print("z action:", resp.zact)
                    print("0: ok, 1: left, 2: right, 3: backward, 4: forward, 5: up, 6: down")
                else:
                    print("cannot find P4calc header in the packet")
            else:
                print("Didn't receive response")
                
        except Exception as error:
            print(error)


if __name__ == '__main__':
    main()

