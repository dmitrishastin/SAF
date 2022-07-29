function [PS, sl_lenfilt] = filters_length(PS)

     sl_lenfilt = [];

     if ~isempty(PS.maxlen)        

        verb_msg('Filtering lengths', PS) 
        
        command = [PS.mrtrix_prefix ' tckstats -dump ' PS.work_dir filesep 'lengths.txt ' PS.final_init ' -force'];
        
        sys_exec(command, PS);        
        lengths = read_tsf([PS.work_dir filesep 'lengths.txt']);
        
        if strcmp(class(PS.maxlen), 'char')
            PS.maxlen = str2double(PS.maxlen);
        end
        
        sl_lenfilt = lengths > PS.maxlen;
        
        PS.logt(end+1,:) = {'Number of streamlines rejected due to maxlen:' sum(sl_lenfilt)};
        rept = [PS.logt{end,1} ' ' num2str(PS.logt{end,2})]; verb_msg(rept, PS)
        
     end
end
