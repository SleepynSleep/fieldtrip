function wxyz_setPivot(varargin)
% @author:  wxyz
% @date:    2024/01/05
% Note: copy from slandarer (https://gitee.com/slandarer/slanColor/blob/master/%E4%B8%8D%E7%AD%89%E8%B7%9D%E9%A2%9C%E8%89%B2%E5%88%86%E5%89%B2/setPivot.m).

if nargin==0
    ax=gca;pivot=0;
else
    if isa(varargin{1},'matlab.graphics.axis.Axes')
        ax=varargin{1};
        if nargin>1
            pivot=varargin{2};
        else
            pivot=0;
        end
    else
        ax=gca;pivot=varargin{1};
    end
end
CLimit=get(ax,'CLim');
% CMap=get(ax,'Colormap');
CMap=colormap(ax);

CLen=[pivot-CLimit(1),CLimit(2)-pivot];
if all(CLen>0)
    [CV,CInd]=sort(CLen);
    CRatio=round(CV(1)/CV(2).*300)./300;
    CRatioCell=split(rats(CRatio),'/');
    if length(CRatioCell)>1
        Ratio=[str2double(CRatioCell{1}),str2double(CRatioCell{2})];
        Ratio=Ratio(CInd);
        N=size(CMap,1);
        CList1=CMap(1:floor(N/2),:);
        CList2=CMap((floor(N/2)+1):end,:);
        if mod(N,2)~=0
            CList3=CList2(1,:);CList2(1,:)=[];
            CInd1=kron((1:size(CList1,1))',ones(Ratio(1)*2,1));
            CInd2=kron((1:size(CList2,1))',ones(Ratio(2)*2,1));
            CMap=[CList1(CInd1,:);repmat(CList3,[Ratio(1)+Ratio(2),1]);CList2(CInd2,:)];
        else
            CInd1=kron((1:size(CList1,1))',ones(Ratio(1),1));
            CInd2=kron((1:size(CList2,1))',ones(Ratio(2),1));
            CMap=[CList1(CInd1,:);CList2(CInd2,:)];
        end
        % set(ax,'Colormap',CMap)
        colormap(ax,CMap);
    end
end
end