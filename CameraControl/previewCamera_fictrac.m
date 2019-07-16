function handles = previewCamera_fictrac(handles)


system([handles.biasFile, ' &']);
hComm = handles.hComm;

% camera preview
for i = 1:length(hComm.flea3)
    if ~(hComm.flea3(i) == 0)
        
        hComm.flea3(i).connect();
%         hComm.flea3(i).loadConfiguration(defaultJsonFile{i});
        hComm.flea3(i).disableLogging();
        
        flyBowl_camera_control(handles.hComm.flea3(i),'preview');
    end
end