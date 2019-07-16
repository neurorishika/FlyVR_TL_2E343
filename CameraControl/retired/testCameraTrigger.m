%% 
%{
1) BIAS can be synchronized with clocked output from NI
2) however, at the extennally-triggerred state, stop-capturing function is
not working. The videoed recorded in multiple sessions will be dumped into
a single file and make it unreadable
%}

%%
handles=initializeCamera();

%%
flea3=handles.hComm.flea3(1);
handles.expDataSubdir='C:\Users\Glenn\Documents\MATLAB\thacq.ver4\CameraControl';
handles.trialMovieName = [handles.expDataSubdir, '\movie_1','.', handles.movieFormat];
param=handles.trialMovieName;
flea3.setVideoFile(param);
        flea3.enableLogging();
flea3.startCapture();
%%
flea3.disableLogging();

%%
startCamera(handles);

%%
pause(2)
defaultJsonFile{1} = 'C:\Users\Glenn\Documents\MATLAB\thacq.ver4\CameraControl\bias_config1.json';
handles.hComm.flea3(1).loadConfiguration(defaultJsonFile{1})
%%
flyBowl_camera_control(handles.hComm.flea3(i),'stop');
%%
pause(1);
stopCamera(handles);
%%
s = daq.createSession('ni')
addAnalogInputChannel(s,'Dev1',{'ai0','ai4'},'Voltage');
addAnalogOutputChannel(s,'Dev1',{'ao1'},'Voltage');
s.Rate=2*10^2;
s.TriggersPerRun=1;
% addDigitalChannel(s,'dev1','Port1/Line7','InputOnly')
% tc=addTriggerConnection(s,'Dev1/PFI7','external','StartTrigger')
addTriggerConnection(s,'Dev1/PFI7','external','StartTrigger')
d=[zeros(1,500),5*ones(1,1),zeros(1,500)];
queueOutputData(s,d'); 


sClk=daq.createSession('ni');
clockFreq = 60;
ch1 = addCounterOutputChannel(sClk,'Dev1',0,'PulseGeneration');
clkTerminal = ch1.Terminal;
ch1.Frequency = clockFreq;
sClk.IsContinuous = false;
addTriggerConnection(sClk,'external','Dev1/PFI7','StartTrigger')
sClk.DurationInSeconds=s.DurationInSeconds;



startBackground(sClk);
for i = 1:10 
    if sClk.IsRunning
        break;
    else
        pause(0.1);
    end
end
%the trigger signal is 5V and spanning 100ns (10M scanning rate)
%too short to trigger the camera (10^5 HZ will work for the camera)

% s.NumberOfScans = 1000;
data = startForeground(s);
plot (data)

%%
addClockConnection(s,'External',['Dev1/' clkTerminal],'ScanClock');
%%