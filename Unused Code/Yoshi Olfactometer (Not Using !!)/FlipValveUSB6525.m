function s=FlipValveUSB6525(lines,state,valvedio)
%Flips valves through USB6525
% see also function: connectToUSB6525
%Input
%   -lines: determines which line to flip.  You can determine with number
%   (Index number of USB6525 lines) or character of line names as explained below
%   'vial1', 'vial2',.. odor vials, 
%   'Empty'...open empty vial, 
%   'Shuttle','block'...flip the shuttle valve or the valve on the exhauster pathway  
%   'all'...flip all lines
%   -state: 0 or 1.  CAUTION: 0 is energized state
%   -valvedio: National instrument USB6525 object generated from connectToUSB6525  
%
% example
% 1) switch valves controlled by the 1st NI USB6525
% s=FlipValve_YS('all',1);
% s=FlipValve_YS(1,0);
% s=FlipValve_YS([2 3],0);
% s=FlipValve_YS('Vial1',0);
% s=FlipValve_YS({'Vial1','Vial2'},0);
%
% 2) switch off all valves controlled by the 2nd NI USB6525
% global valvedio2
% valvedio2 = connectToUSB6525_YS(2)
% s=FlipValve_YS('all',1,valvedio2); 

    
if nargin < 3
    global valvedio1
    if isempty(valvedio1) % ONLY CONNECT TO THE NIDAQ BOARD THE FIRST TIME THE FUNCTION IS CALLED
        USB6525_ID = 1;
        valvedio1 = connectToUSB6525(USB6525_ID);
    end
    valvedio = valvedio1;
end

% SET ALL LINES HIGH SO SWITCHES ARE OFF
stateNow=ones(1,length(valvedio.Channels));

if isnumeric(lines)
    stateNow(lines)=state;
end
if ischar(lines)
    if strcmpi(lines,'all')
        stateNow(:)=state;
    else
        lines={lines};
    end
end
if iscell(lines)
    if length(lines)~=length(state)
        if length(state)==1
            state=repmat(state,1,length(lines));
        else
            error('Number of valves and status values do not match');
        end
    end
    
    channelNames={valvedio.Channels.Name};
    for i=1:length(lines)
        thisLine=find(strcmp(channelNames,lines(i)));
        if ~isempty(thisLine)
            stateNow(thisLine)=state(i);
        else
            error('Some of the vial names cannot be found\n');
        end
    end
    
end

outputSingleScan(valvedio,stateNow);
s=valvedio;