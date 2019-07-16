function BW = generateMaskFromAVI(fname)

%% Read the .avi 
fname = uigetfile('.avi','Choose an .avi file to generate mask');
v=VideoReader(fname);
v.CurrentTime = 1;


f_mask = figure;
currAxes = subplot(1,3,1);
title('Snippet of video')
for k=1:10  % Find Average of 10 Frames
    vidFrame = readFrame(v);
    image(vidFrame, 'Parent', currAxes);
    axis equal off
    currAxes.Visible = 'off';
    video(:,:,k)=vidFrame(:,:,1);
end

%% Draw a an ROI polygon
subplot(1,3,2)
Mask = max(video,[],3); 
imagesc(Mask)
axis equal off
colormap(gray)
title('draw a mask');
BW=roipoly;

subplot(1,3,3)
imagesc(BW);
axis equal off
colormap(gray)

%% Save the mask
dname = uigetdir('C:\');
cd(dname);
imwrite(BW,'mask.png');

pause(1)
close(f_mask);

