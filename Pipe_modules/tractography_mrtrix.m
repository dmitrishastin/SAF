function [PS, SD] = tractography_mrtrix(PS, SD)

    SD.DWI.seed_coords_file_out = [PS.work_dir filesep 'DWI_seeds_out.txt']; % mrtrix seeds output

    if ~isempty(PS.noseed) && exist(PS.noseed, 'file')
        
        [SD.DWI.sl_init, PS.final_init] = deal(PS.noseed);
        
    elseif exist(SD.DWI.sl_init, 'file') && ~PS.force
        
        PS.final_init = SD.DWI.sl_init;        
        
    elseif ~exist(SD.DWI.sl_init, 'file') || PS.force
        
        verb_msg('Running mrtrix tckgen', PS)     
        tstart = tic;     
        
        seed_str = '';
        if PS.surfseed 
            seed_str = [' -seed_coordinates_global ' SD.DWI.seed_coords_file_in];
        end
        
        % generate the tractogram
        command1 = [PS.mrtrix_prefix ' tckgen ' seed_str ' -output_seeds ' SD.DWI.seed_coords_file_out ' ' PS.tckgen ' ' PS.fod ' ' SD.DWI.sl_init ' -force'];
        verb_msg('tckgen string:', PS);
        verb_msg(command1, PS);
        sys_exec(command1, PS);
        
        t = toc(tstart);
        PS.logt(end+1,:) = {'Time spent on initial tractogram generation:' datestr(seconds(t),'HH:MM:SS')};    
        
        if PS.dgn
            pts_to_tck(SD.DWI.seed_coords_file_out,[PS.work_dir filesep 'DWI_seeds_out.tck']);
        end
        
        PS.final_init = SD.DWI.sl_init;
        
    else
        
        error('tckgen input wrong')
        
    end
    
    [PS, SD] = read_prefilter_tracks(PS,SD);
    
end