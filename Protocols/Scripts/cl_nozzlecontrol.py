# -*- coding: utf-8 -*-
"""
Created on Tue Jun  4 16:35:53 2019

@author: technosap
"""

import ctypes
import mmap
import time
import math
from modular_client import ModularClient # for nozzle control


class SHMEMFicTracState(ctypes.Structure):
    """
    This class represents the FicTrac tracking state. These are the exact same values written to the output log file
    when FicTrac is run. Please consult the FicTrac user documentation for their meaning.
    """
    _fields_ = [
        ('frame_cnt', ctypes.c_int),
        ('del_rot_cam_vec', ctypes.c_double * 3),
        ('del_rot_error', ctypes.c_double),
        ('del_rot_lab_vec', ctypes.c_double * 3),
        ('abs_ori_cam_vec', ctypes.c_double * 3),
        ('abs_ori_lab_vec', ctypes.c_double * 3),
        ('posx', ctypes.c_double), # integrated x/y position incorporating heading 
        ('posy', ctypes.c_double), # integrated x/y position incorporating heading 
        ('heading', ctypes.c_double),
        ('direction', ctypes.c_double),
        ('speed', ctypes.c_double),
        ('intx', ctypes.c_double), # integrated forward/side motion ignoring heading
        ('inty', ctypes.c_double), # integrated forward/side motion ignoring heading
        ('timestamp', ctypes.c_double),
        ('seq_num', ctypes.c_int),
    ]

class SHMEMFicTracSignals(ctypes.Structure):
    """
    This class gives a set of variables used to send signals to the FicTrac program.
    """
    _fields_ = [
        ('close_signal_var', ctypes.c_int)
    ]

    def send_close(self):
        self.close_signal_var = 1

def print_fictrac_state(data):
    """
    This function prints the current FicTrac state retrieved from shared memory to the console.
    """
    state_string = ""

    for field_name, field_type in data._fields_:
        field = getattr(data, field_name)
        if(isinstance(field, float) | isinstance(field, int)):
            state_string = state_string + str(field) + "\t"
        else:
            state_string = state_string + str(field[0]) + "\t" + str(field[1]) + "\t" + str(field[2]) + "\t"
            
    print(state_string)
    
def transform_angle(fictrac_heading,nozzle_home_angle):    
    nozzle_position = 360 - fictrac_heading*180/math.pi + nozzle_home_angle # transform to degree and compensate 
    while nozzle_position > 360:
        nozzle_position = nozzle_position - 360
    return nozzle_position

def get_corridor(fictrac_posy):
    ball_dia = 9 #mm
    corridor_width = 60 # mm
    t = (fictrac_posy*ball_dia/2) % (corridor_width*2)
    if t < corridor_width:
        corridor_id = 1 # input to shuttle valve control 
    else:
        corridor_id = 0 # input to shuttle valve control
    return corridor_id

def move_to_nearest(dev,current,end):
    current = current%360
    end = end%360
    if (max(end,current)-min(end,current))<360-(max(end,current)-min(end,current)):
        dev.move_by(0,(end-current))
    else:
        dev.move_by(0,math.copysign(360-(max(end,current)-min(end,current)),-end+current))
        
        
def main():

    dev = ModularClient(port='COM10') # Windows specific port
    # dev.get_device_id()
    # dev.get_methods()
    dev.velocity_max('setValue',[500]) # about 0.25 s per turn (1536/6000)
    dev.acceleration_max('setValue',[500]) # 6/8 s to accerelate to max 

    f = open("C:\FlyVR_TL_2E343\Protocols\Scripts\home_position.config", "r")
    nozzle_home_angle = int(f.read())
    print("Current Home Position:",nozzle_home_angle)
    f.close()
    
    dev.move_to(0,nozzle_home_angle)
    time.sleep(2)
    
    # Open the shared memory region for accessing FicTrac's state
    shmem = mmap.mmap(-1, ctypes.sizeof(SHMEMFicTracState), "FicTracStateSHMEM")
    fictrac_state = SHMEMFicTracState.from_buffer(shmem)

    # Open another shared memory region, this one lets us signal to fic trac to shutdown.
    shmem_signals = mmap.mmap(-1, ctypes.sizeof(ctypes.c_int32), "FicTracStateSHMEM_SIGNALS")
    fictrac_signals = SHMEMFicTracSignals.from_buffer(shmem_signals)
    
    # initial reading
    first_frame_count = fictrac_state.frame_cnt
    old_frame_count = fictrac_state.frame_cnt
    old_heading = fictrac_state.heading
    old_corridor_id = 1
    switch_posy = fictrac_state.posy
    
    print("Waiting for FicTrac updates in shared memory. Press Ctrl-C to stop reading and send close signal to FicTrac process.")
    
    try:
        while True:

            # continuous reading
            position_value = dev.get_positions()
            old_nozzle_position = position_value[0]
            new_frame_count = fictrac_state.frame_cnt
            new_heading = fictrac_state.heading
            print(new_heading)
            
            new_nozzle_position = transform_angle(new_heading,nozzle_home_angle)#regular script
            new_posy = fictrac_state.posy
            new_corridor_id = get_corridor(new_posy)           
                
            # move the nozzle
            move_to_nearest(dev,dev.get_positions()[0],new_nozzle_position)
            
            
            # update the status
            old_heading = new_heading
            old_nozzle_position = new_nozzle_position
            old_frame_count = new_frame_count
            state_string = str(new_nozzle_position) + "\t" + str(new_posy*4.5) + "\t" + str(new_corridor_id) + "\t" + str(switch_posy*4.5) + "\t"
            

            
    except KeyboardInterrupt:
            print("Sending stop signal (over shared memory) to FicTrac process ... ")
            fictrac_signals.send_close()
            # close the odor nozzle controller
            dev.move_to(0,nozzle_home_angle)
            time.sleep(0.5)
            dev.close()
            del dev
            

if __name__ == "__main__":
    main()


