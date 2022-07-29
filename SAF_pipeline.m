function [SD, PS] = SAF_pipeline(varargin)   
    
    pstart = tic; % start the timer
  
    %% parse input and initiate    
    
    parsed_input = varargin;
    PS = init_class(parsed_input);          % custom class - parse parameters & initiate
    if PS.dgn
        save_progress([], PS);
    end
    update_log(PS);
    
    old_SD = exist([PS.work_dir filesep 'SD.mat'], 'file');
    if ~old_SD || PS.force
        SD = storage_class(PS);             % custom class - create data storage structure    
    else
        load([PS.work_dir filesep 'SD.mat'], 'SD');
        SD.DWI.cvi          = double(SD.DWI.cvi);
        SD.DWI.cv           = double(SD.DWI.cv);
        SD.DWI.cvt          = double(SD.DWI.cvt);
        SD.DWI.cvk          = double(SD.DWI.cvk);
        SD.DWI.saf.l        = double(SD.DWI.saf.l);

        for hemi = {'rh', 'lh'}
            SD.DWI.(hemi{1}).faces  = double(SD.DWI.(hemi{1}).faces);
            SD.DWI.(hemi{1}).white  = double(SD.DWI.(hemi{1}).white);
            SD.DWI.(hemi{1}).mid    = double(SD.DWI.(hemi{1}).mid);
            SD.DWI.(hemi{1}).pial   = double(SD.DWI.(hemi{1}).pial);
            SD.DWI.(hemi{1}).ht     = double(SD.DWI.(hemi{1}).ht);
        end
    end

    %% registration step    

    SD = feval(PS.registration, PS, SD);  

    %% parse cortical surfaces

    if ~old_SD || PS.force
        verb_msg('Processing surfaces', PS) 
        [SD.T1.rh.white, SD.T1.lh.white, SD.T1.rh.faces, SD.T1.lh.faces, ...
            SD.T1.rh.usedv, SD.T1.lh.usedv] = process_FS_surfaces(SD.T1.rh.white_file,SD.T1.lh.white_file,PS);   

        for side = {'rh', 'lh'}
            SD.DWI.(side{1}).usedv = SD.T1.(side{1}).usedv;
            SD.DWI.(side{1}).faces = SD.T1.(side{1}).faces;
            SD.T1.(side{1}).usedv = [];
            SD.T1.(side{1}).faces = [];
        end 
    end
    
    %% prepare the seeds array
    
    SD = tx_coords('white', SD, PS);            % transform to DWI space - storage class function
    SD.DWI = combine_verts('white', SD.DWI);    % combine both hemispheres - modality class function
    SD.DWI = calc_vandf(SD.DWI);                % record stats for quick access - modality class function       
    SD = prepare_seeds(PS, SD);                 % generate surface seeds and store in a file

    %% do the seeding (or employ the tractogram provided instead) and read tck in
    
    [PS, SD] = tractography_mrtrix(PS, SD);
    
    %% write successful streamline seed counts / vertex as curvature files (diagnostic only)
    
    [PS, SD] = seed_curv(PS, SD);
    
    %% calculate mid-cortical coordinates    
    
    [SD.T1.rh.pial, SD.T1.lh.pial] = process_FS_surfaces(SD.T1.rh.pial_file,SD.T1.lh.pial_file,PS);
    SD = tx_coords('pial', SD, PS);             % transform to DWI space - storage class function
    SD.DWI = mid_surf(SD.DWI);                  % calculate MCC and LHCT - modality class function
    SD.DWI = combine_verts('mid', SD.DWI);      % combine MCCs for both hemispheres - modality class function
    
    %% pre-initialise parpool
    
    PP = gcp('nocreate');
    if isempty(PP) || PP.NumWorkers ~= PS.wrks
        delete(PP);
        parpool(PS.wrks, 'IdleTimeout', 300);
    end
    clear PP
      
    %% run the GG-HH filtering

    [PS, SD] = filters_GG_HH(PS, SD);
    update_log(PS);
    
    %% apply the PG filter
    
    [PS, SD.DWI] = filters_PG(PS,SD.DWI);     
    if PS.dgn && (~old_SD || PS.force)
        save_progress(SD,PS);  
    end
    update_log(PS);

    %% apply additional filters
    
    [PS, SD] = wholebrain_operations(PS, SD);
    update_log(PS);

    %% run the GWG filter and truncate at WSM if needed
    [PS, SD.DWI] = filters_GWG(PS, SD.DWI);  
    if PS.dgn
        save_progress(SD,PS);
    end
    update_log(PS);

    %% extract SAF
    [PS, SD.DWI] = filters_saf(PS, SD.DWI);
    PS.logt(end+1,:) = {'Final SAF tractogram:' SD.DWI.saf.saf_file};
    verb_msg([PS.logt{end,1} ' ' PS.logt{end,2}], PS)
    
    %% record streamline data on the surface as curvature files
    
    [PS, SD.DWI] = streamlines_on_surface(PS, SD.DWI);
    
    %% go through the optional modules
    
    if ~isempty(PS.optmodules)
        for i = 1:numel(PS.optmodules)
            o = tic;
            PS = feval(PS.optmodules{i}, PS, SD);
            ot = toc(o);
            PS.logt(end + 1,:) = {['Module ' PS.optmodules{i} ' time: '] datestr(seconds(ot),'HH:MM:SS')};
            disp([PS.logt{end,1} ' ' PS.logt{end,2}])
        end
    end
    
    %% produce the log file
    
    t = toc(pstart);    
    PS.logt(end + 1,:) = {'Total time taken:' datestr(seconds(t),'HH:MM:SS')};
    disp([PS.logt{end,1} ' ' PS.logt{end,2}])
    update_log(PS);
    
    %% final bits   
    
    SD.DWI.sl_tracks = {};
    
    save_progress(SD, PS, 1)

    if ~PS.dgn        
        delete([PS.work_dir filesep 'surf_tracks.tck']);        
        if exist([PS.work_dir filesep 'GG_tracks.tck'], 'file')
                delete([PS.work_dir filesep 'GG_tracks.tck']);
        end
    end
    
end

function save_progress(SD, PS, varargin)
         
    save([PS.work_dir filesep 'PS.mat'], 'PS');
    
    if ~isempty(SD)

        if ~isempty(varargin)
            disp('Saving final matlab files')
            SD.DWI.saf.t_gghh   = uint32(SD.DWI.saf.t_gghh);
            SD.DWI.saf.t_gwg    = uint32(SD.DWI.saf.t_gghh);
            SD.DWI.saf.m        = uint32(SD.DWI.saf.m);
            SD.DWI.saf.pre_c    = uint32(SD.DWI.saf.pre_c);
            SD.DWI.saf.pre_h    = uint32(SD.DWI.saf.pre_h);
            SD.DWI.saf.pre_xp   = uint32(SD.DWI.saf.pre_xp);
            SD.DWI.cvi          = uint32(SD.DWI.cvi);
            SD.DWI.cv           = single(SD.DWI.cv);
            SD.DWI.cvt          = single(SD.DWI.cvt);
            SD.DWI.cvk          = uint32(SD.DWI.cvk);
            SD.DWI.saf.l        = single(SD.DWI.saf.l);
            
            for hemi = {'rh', 'lh'}
                SD.DWI.(hemi{1}).faces  = uint32(SD.DWI.(hemi{1}).faces);
                SD.DWI.(hemi{1}).white  = single(SD.DWI.(hemi{1}).white);
                SD.DWI.(hemi{1}).mid    = single(SD.DWI.(hemi{1}).mid);
                SD.DWI.(hemi{1}).pial   = single(SD.DWI.(hemi{1}).pial);
                SD.DWI.(hemi{1}).ht     = single(SD.DWI.(hemi{1}).ht);
            end
        else
            disp('Saving progress')
        end
        
        save([PS.work_dir filesep 'SD.mat'], 'SD', '-v7.3');
        
    end             
end

function update_log(PS)

    logf = fopen([PS.work_dir filesep 'log.txt'], 'w');
    logt = cellfun(@num2str, PS.logt, 'un', 0); % convert integers to strings
    clog = @(i) [logt{i, 1} ' ' logt{i,2}]; % concatenate name-value pairs into single lines
    for i = 1:length(logt) % write every line
        fprintf(logf, '%s\n', clog(i));
    end
    fclose(logf);

end
