# -*- coding: utf-8 -*-
"""
Created on Tue Jun  4 16:35:53 2019

@author: technosap
"""

import ctypes
import time
import math
from modular_client import ModularClient # for nozzle control

def main():
    dev = ModularClient(port='COM10') # Windows specific port
    # dev.get_device_id()
    # dev.get_methods()
    dev.velocity_max('setValue',[500]) # about 0.25 s per turn (1536/6000)
    dev.acceleration_max('setValue',[500]) # 6/8 s to accerelate to max 
    dev.move_to(0,180-32)
    time.sleep(5)
    
    a_s = [15,30,60,120,240]
    p_s = [20,50,100,200,500]
    n_rep = 5
    
    for a in a_s:
        for p in p_s:
            for r in range(n_rep):    
                start = time.time()
                heading = [2*a/p*abs((i%p)-(p/2)) - a/2 + 180 for i in range(0,int(10000))]
                hs = open('log_a_'+str(a)+"_p_"+str(p)+"_r_"+str(r)+'.csv','a')
                i = 0
                try:
                        while time.time()-start < 40:
                                dev.move_to(0,heading[i]-32)
                                t = time.time()-start
                                print(a,p,r,t,i)
                                i+=1
                                hs.write(str(t)+","+str(heading[i]-32)+","+str(dev.get_positions()[0]%360)+"\n")
                except KeyboardInterrupt:
                        dev.close()
                        del dev
                hs.close()

if __name__ == "__main__":
    main()


