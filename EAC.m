
% For controlling the electrical appliances in home
% Dated 2nd March 2016
% Initialization
redthresh = 0.20;
greenthresh = 0.07;
bluethresh = 0.16;
% s = serial('COM21','BaudRate',9600);
% fopen(s);
% blob analysis initializations
blob = vision.BlobAnalysis;
blob.AreaOutputPort = true;
blob.CentroidOutputPort = true;
blob.BoundingBoxOutputPort = true;
blob.OrientationOutputPort = true;
blob.MaximumBlobArea = 3000;
blob.MinimumBlobArea = 600;
% Insert switch box
switchbox = vision.ShapeInserter;
switchbox.BorderColorSource = 'Input port';
% insert track box
trackbox = vision.ShapeInserter;
trackbox.BorderColorSource = 'Input port';
% text insert for no of red objects
redtext = vision.TextInserter('No of red objects = %4d');
redtext.Location = [1 2];
redtext.ColorSource = 'property';
redtext.Color = [1 0 0];
redtext.FontSize = 14;
% text insert for no of green objects
greentext = vision.TextInserter('No of green objects = %4d');
greentext.Location = [1 18];
greentext.ColorSource = 'property';
greentext.Color = [0 1 0];
greentext.FontSize = 14;
% text insert for no of blue objects
bluetext = vision.TextInserter('No of blue objects = %4d');
bluetext.Location = [1 34];
bluetext.ColorSource = 'property';
bluetext.Color = [0 0 1];
bluetext.FontSize = 14;
% text insert for center of blue and red objects
text = vision.TextInserter('+  X:%4d,Y:%4d');
text.Color = [255 255 0];
text.FontSize = 12;
text.LocationSource = 'Input port';
% video
vid = imaq.VideoDevice('winvideo',1,'YUY2_640x480','ReturnedColorSpace','rgb');
vidInfo = imaqhwinfo(vid);
video = vision.VideoPlayer('Name','Final Video');
% while loop for processing
while(1)
    % centroid, area,orientation and bounding box extraction
    pic = step(vid);
    [y x c] = size(pic);
    x1 = x-595;
    x2 = x-455;
    x3 = x-395;
    x4 = x-255;
    x5 = x-195;
    x6 = x-55;
    y1 = y-365;
    y2 = y-225;
    red = imsubtract(pic(:,:,1),rgb2gray(pic));
    redfilt = medfilt2(red,[3,3]);
    binred = im2bw(redfilt, redthresh);
    binred = bwareaopen(binred,300);
    [redarea, redcentroid, redbbox, redorientation] = step(blob,binred);
    redcentroid = uint16(redcentroid);
    green = imsubtract(pic(:,:,2),rgb2gray(pic));
    greenfilt = medfilt2(green,[3,3]);
    bingreen = im2bw(greenfilt,greenthresh);
    [greenarea, greencentroid, greenbbox, greenorientation] = step(blob,bingreen);
    greencentroid = uint16(greencentroid);
    blue = imsubtract(pic(:,:,3),rgb2gray(pic));
    bluefilt = medfilt2(blue,[3,3]);
    binblue = im2bw(bluefilt,bluethresh);
    [bluearea, bluecentroid, bluebbox, blueorientation] = step(blob,binblue);
    bluecentroid = uint16(bluecentroid);
    % trackbox insertion in screen
    % insert red box
    box =  step(trackbox, pic, redbbox, single([1 0 0]));
    % insert green box
    box = step(trackbox, box, greenbbox, single([0 1 0]));
    % insert blue box
    box = step(trackbox, box, bluebbox, single([0 0 1]));
    % retangle draw on vid
    % insert box 1
    swbox = step(switchbox, im2double(pic),[45 115 140 140], [0 1 0]);
    % insert box 2
    swbox = step(switchbox, swbox,[245 115 140 140], [0 1 0]);
    % insert box 3
    swbox = step(switchbox, swbox,[445 115 140 140], [0 1 0]);
    % count no of red blue and green objects
    for object = 1:1:length(redbbox(:,1))
        xred = redcentroid(object,1);
        yred = redcentroid(object,2);
        rarea = redarea(object,1);
        rorientation = redorientation(object,1);
        rorientation = double(rorientation);
        disp('red area =');
        disp(rarea);
        disp('red orientation =');
        disp(rorientation);
        box = step(text, box, [xred yred],[xred-6 yred-9]);
    end
    
    for object = 1:1:length(greenbbox(:,1))
        xgreen = greencentroid(object,1);
        ygreen = greencentroid(object,2);
        garea = greenarea(object,1);
        gorientation = greenorientation(object,1);
        gorientation = double(gorientation);
        disp('green area =');
        disp(garea);
        disp('green orientation');
        disp(gorientation);
        box = step(text, box, [xgreen ygreen], [xgreen-6 ygreen-9]);
    end
    
    for object = 1:1:length(bluebbox(:,1))
        xblue = bluecentroid(object,1);
        yblue = bluecentroid(object,2);
        barea = bluearea(object,1);
        borientation = blueorientation(object,1);
        borientation = double(borientation);
        disp('blue area =');
        disp(barea);
        disp('blue orientation = ');
        disp(borientation);
        box = step(text, box, [xblue yblue], [xblue-6 yblue-9]);
    end
    % insert no of objects text in track box
    box = step(redtext, box, uint8(length(redbbox(:,1))));
    box = step(greentext, box, uint8(length(greenbbox(:,1))));
    box = step(bluetext, box, uint8(length(bluebbox(:,1))));
    % insert switch box in video stream
%      step(video, swbox);
     imshow(binred);
     imshow(binblue);
     imshow(bingreen);
    % insert track box in video stream
    step(video, box);
    % check if red or blue is inside
    if (length(redbbox(:,1))>=1)
    if ((xred(1)>x1)&&(xred(1)<x2)&&(yred(1)>y1)&&(yred(1)<y2))
        disp('box 1');
%         fwrite(s,'q');
        if (length(bluebbox(:,1))>=1)
            if((xblue(1)>x1)&&(xblue(1)<x2)&&(yblue(1)>y1)&&(yblue(1)<y2))
%                 fwrite(s,'w');
            end
        end
    else if((xred(1)>x3)&&(xred(1)<x4)&&(yred(1)>y1)&&(yred(1)<y2))
            disp('box 2');
%             fwrite(s,'e');
            if(length(bluebbox(:,1))>=1)
                if((xblue(1)>x3)&&(xblue(1)<x4)&&(yblue(1)>y1)&&(yblue(1)<y2))
%                     fwrite(s,'r');
                end
            end
            else if((xred(1)>x5)&&(xred(1)<x6)&&(yred(1)>y1)&&(yred(1)<y2))
                disp('box 3');
%                 fwrite(s,'t');
                if(length(bluebbox(:,1))>=1)
                    if((xblue(1)>x5)&&(xblue(1)<x6)&&(yblue(1)>y1)&&(yblue(1)<y2))
%                         fwrite(s,'y');
                    end
                end
%                 else fwrite(s,'u');
                end
         end
    end
    % talk with arduino
    end
end
 
 

 % end
