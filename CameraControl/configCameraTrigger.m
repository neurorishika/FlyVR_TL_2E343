function configCameraTrigger(handles,camInd)
%camInd: 1, back camera; 2, side camera
if nargin < 2
    camInd = [1:length(handles.hComm.flea3)];
end

triggerMode = handles.triggerMode;
hComm=handles.hComm;
for camCounter = camInd
    if ~(hComm.flea3(camCounter)==0)
        
        
        rsp = hComm.flea3(camCounter).getConfiguration();
        config = rsp(1).value;
        
        %trigger mode is either internal or external
        if strncmpi(triggerMode, 'ex', 2)
            config.camera.triggerType = 'External';
        else
            config.camera.triggerType = 'Internal';
        end
        
        hComm.flea3(camCounter).stopCapture();%has to stop before configuration
        if config.logging.enabled == 0
        hComm.flea3(camCounter).enableLogging();%so as to disable the warning of "Logging is already disabled"
        end
        
        % Set new configuration
        rsp = hComm.flea3(camCounter).setConfiguration(config);
    end
end