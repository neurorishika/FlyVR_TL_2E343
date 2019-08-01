# -*- coding: utf-8 -*-
"""
Created on Tue Jun  4 16:35:53 2019

@author: technosap
"""
import time
import math
from modular_client import ModularClient # for nozzle control

def main():

    dev = ModularClient(port='COM10') # Windows specific port

    dev.velocity_max('setValue',[500]) # about 0.25 s per turn (1536/6000)
    dev.acceleration_max('setValue',[500]) # 6/8 s to accerelate to max 
    
    f = open("C:\FlyVR_TL_2E343\Protocols\Scripts\home_position.config", "r")
    position = int(f.read())
    print("Current Home Position:",position)
    f.close()
    
    dev.move_to(0,position)
    
    
    leave = False
    while not leave:
        correct_home = input("Is the Home Position Correct? (Y/N) : ")
        if correct_home == "Y":
            f = open("C:\FlyVR_TL_2E343\Protocols\Scripts\home_position.config", "w")
            f.write(str(position))
            f.close()
            leave = True
        else:
            position = int(input("Enter New Home Position (Integer Degrees Only) : "))
            dev.move_to(0,position)
    dev.close()
    del dev

if __name__ == "__main__":
    main()