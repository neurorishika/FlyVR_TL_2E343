function handles=initializeCamera()

%% == camera_user_setting ==
camera(1).ip = '127.0.0.1';
camera(1).port = 5010;

camera(1).ip = '127.0.0.1';
camera(1).port = 5010;

movieFormat = 'ufmf';
frameRate = 30;
ROI = [0 0 1024 1024];
triggerMode = 'internal';

expDataDir = 'F:\Data_YS';
biasFile = 'C:\Users\Glenn\Documents\MATLAB\thacq.ver4\CameraControl\bias_gui.bat';
% defaultJsonFile{1} = 'C:\Users\Glenn\Documents\MATLAB\thacq.ver4\CameraControl\bias_config_external.json';
defaultJsonFile{1} = 'C:\Users\Glenn\Documents\MATLAB\thacq.ver4\CameraControl\bias_config1_ufmf.json';%ufmf, 512x512, lowered compression

%% == initialize_camera; ==
try
    %Run the camera server program bias
    dos([biasFile, ' &']);
    %initialize the camera
    for camCounter = 1:length(camera)
        flea3(camCounter) = BiasControlV49(camera(camCounter).ip,camera(camCounter).port);
        %flea3.initializeCamera(frameRate, movieFormat, ROI, triggerMode);
        flea3(camCounter).connect();
        flea3(camCounter).loadConfiguration(defaultJsonFile{camCounter});
        flea3(camCounter).disableLogging();
        hComm.flea3(camCounter) = flea3(camCounter);
    end
    
catch ME
    disp('error\n');
    disp(ME.message);
    if camCounter == 1
        for i = 1:length(camera)
            flea3(i) = 0;
            hComm.flea3(i) = flea3(i);
        end
    elseif camCounter == 2
        flea3(2) = 0;
        hComm.flea3(2) = flea3(2);
    end
end

%save values in handles
handles.hComm = hComm;
handles.expDataDir = expDataDir;
handles.jsonFile = defaultJsonFile;
handles.movieFormat = movieFormat;
handles.frameRate=frameRate;
handles.ROI=ROI;
handles.triggerMode=triggerMode;
handles.intensityMode = 'LINEAR';

% camera preview
for i = 1:length(hComm.flea3)
    if ~(hComm.flea3(i) == 0)
        flyBowl_camera_control(handles.hComm.flea3(i),'preview');
    end
end
