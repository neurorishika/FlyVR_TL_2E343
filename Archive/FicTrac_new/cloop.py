#!/usr/bin/env python3

import socket
import math
import time
from modular_client import ModularClient

HOST = '127.0.0.1'  # The server's hostname or IP address
PORT = 5050        # The port used by the server

def transform_angle(fictrac_heading):    
    nozzle_home_angle = -32 # angle between nozzle home and the orientation of fly, clockwise as positive
    nozzle_position = 360 - fictrac_heading*180/math.pi + nozzle_home_angle # transform to degree and compensate 
    if nozzle_position > 360:
        nozzle_position = nozzle_position - 360
    return nozzle_position

def move_to_nearest(dev,current,end):
    current = current%360
    end = end%360
    if (max(end,current)-min(end,current))<360-(max(end,current)-min(end,current)):
        dev.move_by(0,(end-current))
    else:
        dev.move_by(0,math.copysign(360-(max(end,current)-min(end,current)),-end+current))
        

dev = ModularClient(port='COM10') # Windows specific port

dev.velocity_max('setValue',[1500])
dev.acceleration_max('setValue',[1500])
    
dev.move_to(0,-32)
time.sleep(2)

# Open the connection (FicTrac must be waiting for socket connection)
with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as sock:
    sock.connect((HOST, PORT))
    
    data = ""
    try:
        # Keep receiving data until FicTrac closes
        while True:
            # Receive one data frame
            new_data = sock.recv(1024)
            if not new_data:
                break
            
            # Decode received data
            data += new_data.decode('UTF-8')
            
            # Find the first frame of data
            endline = data.find("\n")
            line = data[:endline]       # copy first frame
            data = data[endline+1:]     # delete first frame
            
            # Tokenise
            toks = line.split(", ")
            
            # Fixme: sometimes we read more than one line at a time,
            # should handle that rather than just dropping extra data...
            if ((len(toks) < 24) | (toks[0] != "FT")):
                print('Bad read')
                continue
            
            # Extract FicTrac variables
            # (see https://github.com/rjdmoore/fictrac/blob/master/doc/data_header.txt for descriptions)
            cnt = int(toks[1])
            dr_cam = [float(toks[2]), float(toks[3]), float(toks[4])]
            err = float(toks[5])
            dr_lab = [float(toks[6]), float(toks[7]), float(toks[8])]
            r_cam = [float(toks[9]), float(toks[10]), float(toks[11])]
            r_lab = [float(toks[12]), float(toks[13]), float(toks[14])]
            posx = float(toks[15])
            posy = float(toks[16])
            heading = float(toks[17])
            step_dir = float(toks[18])
            step_mag = float(toks[19])
            intx = float(toks[20])
            inty = float(toks[21])
            ts = float(toks[22])
            seq = int(toks[23])
            
            # Do something ...
            print(heading)
            
            new_nozzle_position =  transform_angle(heading)
            
            move_to_nearest(dev,dev.get_positions()[0],new_nozzle_position)
        
    except KeyboardInterrupt:
        dev.move_to(0,-32)
        time.sleep(0.5)
        dev.close()
        del dev
