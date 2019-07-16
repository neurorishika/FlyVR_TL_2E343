%camera setting can be changed in initializeCamera
handles = initializeCamera;

%these settings determine where to save the files, and the goal is to easily correlate behavioral video with ephys recording 
filepath='F:\';
filename='180210-7.mat';%fly#7; this is for saving of ephys recording, change accordingly
indexnum='2';%trial#2

handles.expDataDir=filepath;
handles.expDataSubdir=[handles.expDataDir,'\',strrep(filename,'.mat','')];
handles.trialMovieName = [handles.expDataSubdir, '\movie_',num2str(indexnum), '.', handles.movieFormat];

%%
startCamera(handles)
%%
pause(3)
stopCamera(handles)
%%
pause(5)
closeCamera(handles)
%% view the video
% showufmf function is in ctrax / matlab / filehandling
showufmf

