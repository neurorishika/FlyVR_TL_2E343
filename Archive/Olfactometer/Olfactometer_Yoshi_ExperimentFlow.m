% Connect to the NIDAQ box and define the digital channels
valvedio = connectToUSB6525()
%s=FlipValveUSB6525({'Vial1','Vial2','Vial3','Vial4','Vial5','Final'},[1 0 0 0 0 1],valvedio);
%  s=FlipValveUSB6525({'Vial1','Vial2','Vial3','Vial4','Vial5','Final'},[0 1 0 0 0 0],valvedio);
%  pause(2)
%  s=FlipValveUSB6525({'Vial1','Vial2','Vial3','Vial4','Vial5','Final'},[0 0 1 0 0 0],valvedio);
%  pause(2)
%  s=FlipValveUSB6525({'Vial1','Vial2','Vial3','Vial4','Vial5','Final'},[0 0 0 1 0 0],valvedio);
%  pause(2)
s=FlipValveUSB6525({'Vial1','Vial2','Vial3','Vial4','Vial5','Final'},[0 0 0 1 0 0],valvedio);
fprintf('Ethanol On\n')
 pause(10)
fprintf('Ethanol Off\n')
s=FlipValveUSB6525({'Vial1','Vial2','Vial3','Vial4','Vial5','Final'},[1 0 0 0 0 0],valvedio);
% Send digital outputs to flip open the appropriate valves
%s=FlipValveUSB6525(lines,state,valvedio)

% For Final: 1 = close 0 = open

% Example usage:
%for n=1:5
%   state = zeros(1,6);
%   state(3)=1
% OPEN VALVE TO ODOR (VIAL 4)
%   s=FlipValveUSB6525({'Vial1','Vial2','Vial3','Vial4','Vial5','Final'},state,valvedio); 
%   pause(2)
% SWITCH BACK TO EMPTY VIAL OPEN (VIAL 1) & ODOR CLOSED
%   s=FlipValveUSB6525({'Vial1','Vial2','Vial3','Vial4','Vial5','Final'},[0 0 0 0 0 0],valvedio);  
%   pause(2)
%end
%   s=FlipValveUSB6525({'Vial1','Vial2','Vial3','Vial4','Vial5','Final'},[0 0 0 0 0 0],valvedio); % ALL VALVES CLOSED
  
release(valvedio)