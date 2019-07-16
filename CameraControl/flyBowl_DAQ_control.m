function daqC = flyBowl_DAQ_control(daqC, token)

switch token    
    
    case 'config'
        daqC.Rate = 10000;
        daqC.NotifyWhenDataAvailableExceeds = 10000;
        daqC.IsContinuous = true;
        
    case 'start'
        daqC.startBackground();
        
    case 'stop'
        daqC.stop;
        
    case 'disconnect'
        %delete flea3;
        
    otherwise
        disp('Unknown command for the camera control.')        

end