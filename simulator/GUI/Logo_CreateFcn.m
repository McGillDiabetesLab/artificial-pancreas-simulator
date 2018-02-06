function Logo_CreateFcn(hObject, eventdata, handles)

hObject.NextPlot = 'add';
[im, ~, alpha] = imread('McGillLogo.png');
h = imshow(im, 'Parent', hObject);
h.AlphaData = alpha;

end

