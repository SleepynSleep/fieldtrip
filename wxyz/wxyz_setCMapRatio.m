function wxyz_setCMapRatio(varargin)
% @author:  wxyz
% @date:    2024/01/05
% Note: copy from slandarer (https://gitee.com/slandarer/slanColor/blob/master/%E4%B8%8D%E7%AD%89%E8%B7%9D%E9%A2%9C%E8%89%B2%E5%88%86%E5%89%B2/setCMapRatio.m).

if nargin==2
    ax=gca;
    oriRatio=sort(varargin{1});
    breakPnt=sort(varargin{2});
elseif nargin==3
    ax=varargin{1};
    oriRatio=sort(varargin{2});
    breakPnt=sort(varargin{3});
end

% process raw data
CLimit=get(ax,'CLim');
breakPnt=[CLimit(1),breakPnt,CLimit(2)];
newRatio=diff(breakPnt);
oriCMap=colormap(ax);
CLen=size(oriCMap,1);
newRatio=newRatio./diff([0,oriRatio,1]);
newRatio=round(newRatio./max(newRatio).*400);
oriRatio=[oriRatio,1];

% Construction of some color bars at the beginning
tempCMap=oriCMap(1:ceil(oriRatio(1).*CLen),:);
CInd2=kron((1:size(tempCMap,1)-1)',ones(newRatio(1),1));
newCMap=tempCMap(CInd2,:);
CInd3=oriRatio(1).*CLen-size(tempCMap,1)+1;
CInd3=round(CInd3.*newRatio(1));
newCMap=[newCMap;repmat(tempCMap(end,:),[CInd3,1])];

% Loop to add a new color
for i=2:length(oriRatio)
    CInd1=round(newRatio(i).*(ceil(oriRatio(i-1).*CLen)-oriRatio(i-1).*CLen));
    if abs(ceil(oriRatio(i).*CLen)-oriRatio(i).*CLen)>0
        CInd2=ceil(oriRatio(i-1).*CLen)+1:ceil(oriRatio(i).*CLen)-1;
    else
        CInd2=ceil(oriRatio(i-1).*CLen)+1:ceil(oriRatio(i).*CLen);
    end
    CInd2=kron(CInd2',ones(newRatio(i),1));
    CInd3=round(newRatio(i).*(oriRatio(i).*CLen-floor(oriRatio(i).*CLen)));
    if ceil(oriRatio(i).*CLen)==ceil(oriRatio(i-1).*CLen)
        CInd1=[];
        CInd3=round(newRatio(i).*(oriRatio(i).*CLen-oriRatio(i-1).*CLen));
    end
    newCMap=[newCMap;
        repmat(oriCMap(ceil(oriRatio(i-1).*CLen),:),[CInd1,1]);
        oriCMap(CInd2,:);
        repmat(oriCMap(ceil(oriRatio(i).*CLen),:),[CInd3,1])];
end
colormap(ax,newCMap);
end