function stack = cropStack( stack, margins )

%Scalar value for symmetric margins
if numel(margins)==1
    margins = repmat(margins,1,4); %[top, bottom, left, right]
end

%Crop image stack to within specified margins
[nY,nX] = size(stack,[1,2]);
tblr = [1,nY,1,nX] + margins.*[1,-1,1,-1];
stack = stack(tblr(1):tblr(2),tblr(3):tblr(4),:);


