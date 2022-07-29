function onum = number_parser(istr)

    assert(~isempty(istr), 'number parsing error: input empty')
    assert(ischar(istr), 'number parsing error: input must be a string')

    mpos = regexp(istr, 'M');
    kpos = regexp(istr, 'K');
    
    [mval, kval, nval] = deal(0);
    
    if ~isempty(mpos) && ~isempty(kpos) && mpos > kpos
        error('number parsing error: M comes before K')
    end
    
    ocalc = @(mval, kval, nval) mval * 10 ^ 6 + kval * 10 ^ 3 + nval;
    
    if ~isempty(mpos) && mpos > 1
        mval = str2double(istr(1:mpos - 1));
        if numel(istr) == mpos; onum = ocalc(mval, kval, nval); return; end
    elseif ~isempty(mpos)
        error('number parsing error: number of millions required')
    else
        mpos = 0;
    end
        
    if ~isempty(kpos) && kpos > 1
        kval = str2double(istr(mpos + 1:kpos - 1));
        if numel(istr) == kpos; onum = ocalc(mval, kval, nval); return; end
    elseif ~isempty(kpos)
        error('number parsing error: number of thousands required')
    else
        kpos = 0;
    end
    
    nval = str2double(istr(kpos + 1: end));   
    onum = ocalc(mval, kval, nval);
    
%     switch istr(end)
%         case 'M'
%             onum = str2double(istr(1:end-1)) * 10^6;
%         case 'K'
%             onum = str2double(istr(1:end-1)) * 10^3;
%         otherwise
%             onum = str2double(istr);
%     end    

end