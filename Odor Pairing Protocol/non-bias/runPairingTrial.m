function run = runPairingTrial(CSpWait, CSpLength, ledDelay, CSmWait, CSmLength, endWait, ledPulseWidth, ledIntensity, nTrials, trialDelay, sampleRate)

if nargin < 1
    CSpWait = 20;
    CSpLength = 30;
    ledDelay = 15;
    CSmWait = 20; 
    CSmLength = 30; 
    endWait = 20;
    ledPulseWidth = 1;
    ledIntensity = 3;
    nTrials = 6;
    trialDelay = 0;
    sampleRate=1000;
end

close all ;

system('start "" call C:\FlyVR_TL_2E343\Experiment\cl_nozzlecontrol.py')

% Get NIDAQ-6001 Device
HWlist=daq.getDevices;
for i=1:length(HWlist)
    if strcmpi(HWlist(i).Model,'USB-6001')
        NIdaq.dev=HWlist(i).ID;
    end
end
if ~isfield(NIdaq,'dev')
    error('Cannot connect to USB-6001')
end

% Create NIDAQ Session
Session = daq.createSession('ni');

fprintf('USB-6001 Session Created.\n')

% Setup Sampling
Session.Rate = 1000;

% Camera Channel
Session.addAnalogOutputChannel(NIdaq.dev,'ao1','Voltage');
% LED Channel
Session.addAnalogOutputChannel(NIdaq.dev,'ao0','Voltage');

% Get NIDAQ-6525 device
valvedio = connectToUSB6525()
pause(2)

fprintf('USB-6525 Session Created.\n')

% NIDAQ Signals
stateOff=ones(1,length(valvedio.Channels));
stateOn=ones(1,length(valvedio.Channels));

lines = {'Vial1','Vial2','Vial3','Vial4','Vial5','Final'};
on = [0 0 1 0 0 1];
off = [1 0 0 0 0 1];

if iscell(lines)    
    channelNames={valvedio.Channels.Name};
    for i=1:length(lines)
        thisLine=find(strcmp(channelNames,lines(i)));
        if ~isempty(thisLine)
            stateOn(thisLine)=on(i);
            stateOff(thisLine)=off(i);
        else
            error('Some of the vial names cannot be found\n');
        end
    end
end

%%%%%%%%%%%%%%%%%%%
%START CLOSED LOOP%
%%%%%%%%%%%%%%%%%%%

initDelay = 50; % in msec
trialLength = initDelay + (CSpWait + CSpLength + CSmWait + CSmLength + endWait)*sampleRate;

% Initialize Trigger Outputs
cameraTrigger = zeros(trialLength,1);
ledTrigger = zeros(trialLength,1);
% odorTrigger = zeros(trialLength,1);

FrameRate = 50 ;
nFrames = (CSpWait + CSpLength + CSmWait + CSmLength + endWait)*FrameRate;

pulse_width = 1000/FrameRate;

% Setup Camera Trigger
for i = 1:nFrames
    cameraTrigger(initDelay+pulse_width*(i-1):initDelay+pulse_width*(i-1)+pulse_width/2) = 5*ones;
end
% Setup Odor Trigger
% odorTrigger(initDelay+CSpWait*sampleRate : initDelay+(CSpWait+CSpLength)*sampleRate) = ones;
% odorTrigger(initDelay+(CSpWait+CSpLength+CSmWait)*sampleRate : initDelay+(CSpWait+CSpLength+CSmWait+CSmLength)*sampleRate) = ones;

% Setup LED Trigger
totalLedPulses = floor((CSpLength-ledDelay)/(2*ledPulseWidth));
preLedDelay = initDelay + (CSpWait + ledDelay)*sampleRate;
for i = 0:totalLedPulses
   ledTrigger(preLedDelay+2*i*ledPulseWidth*sampleRate:preLedDelay+2*i*ledPulseWidth*sampleRate+ledPulseWidth*sampleRate) = ledIntensity*ones; 
end

% plot(cameraTrigger);hold on;
% plot(odorTrigger);hold on;
% plot(ledTrigger);

queueOutputData(Session,[ledTrigger cameraTrigger]);

system('start "" call C:\FlyVR_TL_2E343\FicTrac\FicTrac-PGR.bat')

%% Setup Camera %%

%vid1 = videoinput('pointgrey', 2, 'F7_Mono8_1040x776_Mode1');
 vid1 = videoinput('pointgrey', 1, 'F7_Mono8_640x512_Mode1');
% preview(vid1);

vid2 = videoinput('pointgrey', 2, 'F7_Mono8_1040x776_Mode1');
% preview(vid2);

vid1.TriggerRepeat = 0;
vid2.TriggerRepeat = 0;

src1 = getselectedsource(vid1);
src2 = getselectedsource(vid2);

src1.FrameRate = FrameRate;
src2.FrameRate = FrameRate;

DurationInFrames = ceil(FrameRate * trialLength/sampleRate) ;


vid1.LoggingMode = 'memory';
vid2.LoggingMode = 'memory';

logfile1 = VideoWriter('cam1.avi','Grayscale AVI');
logfile1.FrameRate = FrameRate ;
logfile2 = VideoWriter('cam2.avi','Grayscale AVI');
logfile2.FrameRate = FrameRate ;

vid1.DiskLogger = logfile1;
vid2.DiskLogger = logfile2;
triggerconfig(vid1, 'manual' ) ;
vid1.FramesPerTrigger = DurationInFrames ;
triggerconfig(vid2, 'manual' ) ;
vid2.FramesPerTrigger = DurationInFrames ;

start(vid1);
start(vid2);

%%  Start Trial %%
startBackground(Session);

trigger(vid1);
trigger(vid2);

tic;
pause(initDelay/sampleRate+CSpWait);
toc
diff =(toc- initDelay/sampleRate-CSpWait);
outputSingleScan(valvedio,stateOn);
fprintf('CS+ on\n');
pause(CSpLength-diff);
toc
diff =(toc- initDelay/sampleRate-CSpWait-CSpLength);
outputSingleScan(valvedio,stateOff);
fprintf('CS+ off\n');
pause(CSmWait-diff);
toc
diff =(toc- initDelay/sampleRate-CSpWait-CSpLength-CSmWait);
outputSingleScan(valvedio,stateOn);
fprintf('CS- on\n');
pause(CSmLength-diff);
toc
diff =(toc- initDelay/sampleRate-CSpWait-CSpLength-CSmWait-CSmLength);
outputSingleScan(valvedio,stateOff);
fprintf('CS- off\n');
pause(endWait-diff);
toc

stop(vid1);
stop(vid2);

while (vid1.FramesAcquired ~= vid1.DiskLoggerFrameCount) 
     pause(.1)
end
while (vid2.FramesAcquired ~= vid2.DiskLoggerFrameCount) 
     pause(.1)
end

fprintf('Trial Ended\n');

delete(vid1)
clear vid1
delete(vid2)
clear vid2

release(valvedio)
release(Session)

