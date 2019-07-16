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
        dev.velocity_max('setValue',[1500]) # about 0.25 s per turn (1536/6000)
        dev.acceleration_max('setValue',[1500]) # 6/8 s to accerelate to max 
        dev.move_to(0,180-45)
        time.sleep(5)
        """i = 0
        start = time.time()
        try:
                while True:   
                        heading = 90*math.sin(2*math.pi*i/500) + 90
                        #hs = open('log_a_'+str(a)+"_p_"+str(p)+"_r_"+str(r)+'.csv','a')
                        dev.move_to(0,heading-45)
                        t = time.time()-start
                        print(t,i)
                        i+=1
                        i=i%500
                        #hs.write(str(t)+","+str(heading[i]-32)+","+str(dev.get_positions()[0]%360)+"\n")
        except KeyboardInterrupt:
                dev.move_to(0,90-45)
                dev.close()
                del dev
                #hs.close()"""

if __name__ == "__main__":
    main()


