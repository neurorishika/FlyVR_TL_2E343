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

% Get NIDAQ Device
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

% Setup Sampling
Session.Rate = 1000;

% Camera Channel
Session.addAnalogOutputChannel(NIdaq.dev,'ao1','Voltage');
% LED Channel
Session.addAnalogOutputChannel(NIdaq.dev,'ao0','Voltage');

%%%%%%%%%%%%%%%%%%%
%START CLOSED LOOP%
%%%%%%%%%%%%%%%%%%%

initDelay = 50; % in msec
trialLength = initDelay + (CSpWait + CSpLength + CSmWait + CSmLength + endWait)*sampleRate;

% Initialize Trigger Outputs
cameraTrigger = zeros(trialLength,1);
ledTrigger = zeros(trialLength,1);
odorTrigger = zeros(trialLength,1);

% Setup Camera Trigger
cameraTrigger(1:50) = 5*ones;

% Setup Odor Trigger
odorTrigger(initDelay+CSpWait*sampleRate : initDelay+(CSpWait+CSpLength)*sampleRate) = ones;
odorTrigger(initDelay+(CSpWait+CSpLength+CSmWait)*sampleRate : initDelay+(CSpWait+CSpLength+CSmWait+CSmLength)*sampleRate) = ones;

% Setup LED Trigger
totalLedPulses = floor((CSpLength-ledDelay)/(2*ledPulseWidth));
preLedDelay = initDelay + (CSpWait + ledDelay)*sampleRate;
for i = 0:totalLedPulses
   ledTrigger(preLedDelay+2*i*ledPulseWidth*sampleRate:preLedDelay+2*i*ledPulseWidth*sampleRate+ledPulseWidth*sampleRate) = ledIntensity*ones; 
end

plot(cameraTrigger);hold on;
plot(odorTrigger);hold on;
plot(ledTrigger);

queueOutputData(Session,[ledTrigger odorTrigger]);
startForeground(Session);





