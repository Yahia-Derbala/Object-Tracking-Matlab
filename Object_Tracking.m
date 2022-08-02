close all
clear all
clc
Video=VideoReader('Sample Video.mp4');
Frames=Video.NumberOfFrames;
v = VideoWriter('Output.avi');
%%Initizalizing Blob Objects for each color 
blob_R = vision.BlobAnalysis('BoundingBoxOutputPort', true,'MinimumBlobAreaSource', 'Property','MinimumBlobArea', 150);
blob_G = vision.BlobAnalysis('BoundingBoxOutputPort', true,'MinimumBlobAreaSource', 'Property','MinimumBlobArea', 150);
blob_B = vision.BlobAnalysis('BoundingBoxOutputPort', true,'MinimumBlobAreaSource', 'Property','MinimumBlobArea', 150);

open(v)
for Frame = 1:1: Frames
    %%Extracting a frame
    CurrentFrame = read(Video,Frame);
    %% imshow(CurrentFrame)
    Size = size(CurrentFrame);
    %%GrayScale conversion, GS_CF = GrayScale Current Frame
    GS_CF=zeros(Size(1),Size(2));
    for row = 1:Size(1)
        for column=1:Size(2)
            GS_CF(row,column)=(CurrentFrame(row,column,1)*0.2989) + (CurrentFrame(row,column,2)*0.5870) + (CurrentFrame(row,column,3)*0.1140);
        end
    end
    GS_CF=uint8(GS_CF);
    %%imshow(GS_CF);
    %%Histogram of grayscale frame
    freq=zeros(256,1);
    CDF=zeros(256,1);
    CDC=zeros(256,1);
    cum=zeros(256,1);
    output=zeros(256,1);
    Pixels = Size(1)*Size(2);
    %%Extract Histogram and calculate CDF
    for i=1:Size(1)
        for j=1:Size(2)
            value=GS_CF(i,j);
            freq(value+1)=freq(value+1)+1;
            CDF(value+1)=freq(value+1)/Pixels;
        end
    end
    sum=0;
    res=255;
    %Calculate CDC
    for i=1:size(CDF)
        sum=sum+freq(i);
        cum(i)=sum;
        CDC(i)=cum(i)/Pixels;
        output(i)=round(CDC(i)*res);
    end
    
    %%Applying new histogram to the image
    HE_CF=uint8(GS_CF);
    for i=1:Size(1)
        for j=1:Size(2)
            HE_CF(i,j)=output(GS_CF(i,j)+1);
        end
    end
    %%imshow(HE_CF)
    %% figure,plot(output); title('Histogram');
    
    
    %%Difference Frame to extract red component, DF_CF = Difference Frame Current Frame
    DF_CF_R=zeros(Size(1),Size(2));
    DF_CF_G=zeros(Size(1),Size(2));
    DF_CF_B=zeros(Size(1),Size(2));
    DF_CF_R = CurrentFrame(:,:,1)-HE_CF;
    DF_CF_G = CurrentFrame(:,:,2)-HE_CF;
    DF_CF_B = CurrentFrame(:,:,3)-HE_CF;
    DF_CF_R = uint8(DF_CF_R);
    DF_CF_G = uint8(DF_CF_G);
    DF_CF_B = uint8(DF_CF_B);

    %%Binarization using thresholding, f=50, BI_CF = Binarized Current Frame
    BI_CF_R=zeros(Size(1),Size(2));
    BI_CF_G=zeros(Size(1),Size(2));
    BI_CF_B=zeros(Size(1),Size(2));
    BI_CF_R=uint8(HE_CF);
    BI_CF_G=uint8(HE_CF);
    BI_CF_B=uint8(HE_CF);
    for row = 1:Size(1)
        for column=1:Size(2)
            %%Red frame Binarization
            if DF_CF_R(row,column)> 68
                BI_CF_R(row,column)= 256;
            else
                BI_CF_R(row,column)= 0;
            end
            %%Green Frame BinarizatioN
            if DF_CF_G(row,column)> 58
                BI_CF_G(row,column)= 256;
            else
                BI_CF_G(row,column)= 0;
            end
            %%Blue Frame Binarization
            if DF_CF_B(row,column)> 67
                BI_CF_B(row,column)= 256;
            else
                BI_CF_B(row,column)= 0;
            end
        end
    end  
    BI_CF_R=medfilt2(BI_CF_R,[3 3]);
    BI_CF_G=medfilt2(BI_CF_G,[7 7]);
    BI_CF_B=medfilt2(BI_CF_B,[3 3]);
    [area_R,centroid_R, bbox_R] = step(blob_R, logical(BI_CF_R));
    [area_G,centroid_G, bbox_G] = step(blob_G, logical(BI_CF_G));
    [area_B,centroid_B, bbox_B] = step(blob_B, logical(BI_CF_B));
    %%Converting BBox into uint16
    bbox_R=uint16(bbox_R);
    bbox_G=uint16(bbox_G);
    bbox_B=uint16(bbox_B);
    vidout=insertShape(CurrentFrame,'rectangle',bbox_R,'LineWidth',3,'Color','red');
    vidout=insertShape(vidout,'rectangle',bbox_G,'LineWidth',3,'Color','green');
    vidout=insertShape(vidout,'rectangle',bbox_B,'LineWidth',3,'Color','blue');
    writeVideo(v,vidout)
end
close(v)
