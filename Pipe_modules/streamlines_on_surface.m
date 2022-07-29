function [PS, DWI] = streamlines_on_surface(PS, DWI)

    out_dir = [PS.work_dir filesep 'surf_data'];
    if ~exist(out_dir,'dir')
        mkdir(out_dir);
    end
    
    % create symbolic links to surface files for convenience
    command1 = ['ln -s ' PS.fs_dir filesep 'surf' filesep 'rh.inflated ' out_dir filesep 'rh.inflated; '];
    command2 = ['ln -s ' PS.fs_dir filesep 'surf' filesep 'lh.inflated ' out_dir filesep 'lh.inflated'];
    sys_exec([command1 command2], PS);

    % start collating data, recording as curvatures and updating log
    PS.logt(end+1,:) = {'' ''};

    % density maps
    if PS.dgn
	    PS.logt(end+1,:) = {'Results for all streamlines (based on midcortical surface):' ''};
	    lt = data_to_curv('t_gghh', 't_gghh', DWI, out_dir);
	    PS.logt(end+1,:) = {'Cortical coverage (% of all vertices) - MCC:' lt{1}};
	    PS.logt(end+1,:) = {'Termination density - streamlines per vertex (AVG) - MCC:' lt{2}};
	    PS.logt(end+1,:) = {'Termination density - streamlines per vertex (SD) - MCC:' lt{3}};

	    PS.logt(end+1,:) = {'' ''};
    end

    PS.logt(end+1,:) = {'Results for subcortical streamlines (based on white matter surface):' ''};
    lt = data_to_curv('t', 't', DWI, out_dir);
    PS.logt(end+1,:) = {'Cortical coverage (% of all vertices):' lt{1}};
    PS.logt(end+1,:) = {'Termination density - streamlines per vertex (AVG):' lt{2}};
    PS.logt(end+1,:) = {'Termination density - streamlines per vertex (SD):' lt{3}};  

    % intrinsic streamline-wise measurements
    lt = data_to_curv('l', 't', DWI, out_dir);
    PS.logt(end+1,:) = {'Streamline length per vertex, mm (AVG):' lt{2}};
    PS.logt(end+1,:) = {'Streamline length per vertex, mm (SD):' lt{3}};

    if ~isempty(PS.fa)
        sl_data = apply_tck_sample(DWI.saf.saf_file, PS.fa, out_dir, PS);
        lt = data_to_curv(sl_data, 't', DWI, out_dir, 'FA');
        PS.logt(end+1,:) = {'Mean streamline FA per vertex (AVG):' lt{2}};
        PS.logt(end+1,:) = {'Mean streamline FA per vertex (SD):' lt{3}};
    end
    
    if ~isempty(DWI.sl_weights)
        lt = data_to_curv([PS.work_dir filesep 'SAF.wts'], 't', DWI, out_dir, 'wts');
        PS.logt(end+1,:) = {'Mean streamline weights per vertex (AVG):' lt{2}};
        PS.logt(end+1,:) = {'Mean streamline weights per vertex (SD):' lt{3}};
    end
    
    if ~isempty(PS.scalar2surf)
        for i = 1:numel(PS.scalar2surf)
            [sl_data, sc_name] = apply_tck_sample(DWI.saf.saf_file, PS.scalar2surf{i}, out_dir, PS);
            lt = data_to_curv(sl_data, 't', DWI, out_dir, sc_name);
            PS.logt(end+1,:) = {'Mean streamline ' sc_name ' per vertex (AVG):' lt{2}};
            PS.logt(end+1,:) = {'Mean streamline ' sc_name ' per vertex (SD):' lt{3}};
        end
    end
    
    PS.logt(end+1,:) = {'' ''};

end

% generate a freesurfer curvature file
function logt = data_to_curv(indata, inverts, DWI, out_dir, varargin)

    % if external file is provided
    if ~isempty(varargin)
        fname = varargin{1};
    elseif isprop(DWI.saf, indata)                
        fname = indata;                
    elseif ischar(indata)               
        [~,fname] = Supp_gz_fileparts(indata);  
    else
        disp('wrong data_to_curv input type')
        return
    end

    cv_num = numel(DWI.cvh);

    % prepare for output
    rh_outfile = [out_dir filesep 'rh.' fname '.' inverts];
    lh_outfile = [out_dir filesep 'lh.' fname '.' inverts]; 
    logt = cell(3,1);

    % convert to actual vertex indices
    invs = double(DWI.saf.(inverts));
    
    % this marks vertices from the left hemisphere with negative indices
    invs(DWI.saf.h(:) == 1) = -invs(DWI.saf.h(:) == 1);                

    % find all vertices of interest, removing the non-saf vertices (takes HH filter into account too)
    unique_verts = double(unique(invs(:))');
    unique_verts(:, unique_verts(1, :) == 0) = [];                

    % decide if looking at termination counts at a vertex...
    if isprop(DWI.saf, indata) && strcmp(indata, inverts)

        unique_verts(2, :) = hist(invs(invs(:) ~= 0), unique_verts(1, :));

    % ...or mean streamline-related data per vertex
    else

        if isprop(DWI.saf, indata)

            indt = DWI.saf.(indata); 

        else

            if ischar(indata)

                % read the file
                indt_raw = read_tsf(indata);
                
                % sort NaNs and restore indexing
                indt_raw(isnan(indt_raw)) = 0;
                sl_ind = find(invs(1, :));
                indt = invs(1, :) * 0;
                indt(sl_ind) = indt_raw; 

            elseif ismatrix(indata)

                indt = indata;

            end    
        end

        [~,ind1] = ismember(invs(1, :), unique_verts);
        [~,ind2] = ismember(invs(2, :), unique_verts);

%         idx = arrayfun(@(x)[find(ind1 == x) find(ind2 == x)], 1:length(unique_verts), 'un', 0);
%         unique_verts(2,:) = cellfun(@(x) mean(indt(x)), idx);

        vals = cell(size(unique_verts));
        parfor x = 1 : length(vals)                
            vals{x} = [find(ind1 == x) find(ind2 == x)]; 
        end
        unique_verts(2,:) = cellfun(@(x) mean(indt(x)), vals);

%         unique_verts(2,:) = vals;                

    end

    % split into hemispheres
    [rverts_out, lverts_out] = deal(unique_verts);                
    rverts_out(:, rverts_out(1, :) < 0) = [];
    lverts_out(:, lverts_out(1, :) > 0) = [];
    lverts_out(1, :) = -lverts_out(1, :);

    % distribute in recordable form and save
    rc_list = zeros(1, length(DWI.rh.seeds));                  
    rc_list(rverts_out(1, :)) = rverts_out(2, :);
    write_curv(rh_outfile, rc_list, DWI.rh.nfaces);

    lc_list = zeros(1, length(DWI.lh.seeds));
    lc_list(lverts_out(1, :)) = lverts_out(2, :);
    write_curv(lh_outfile, lc_list, DWI.lh.nfaces);

    % generate stats            
    l_mean = sum(unique_verts(2,:)) / cv_num; % mean value per vertex, only the vertices within the original label (e.g., cortex) counted

    l_std = sum((unique_verts(2,:) - l_mean) .^ 2); % deal with the "connected" vertices
    l_std = l_std +  (0 - l_mean) ^ 2 * (cv_num - numel(unique_verts(2,:))); % account for the "unconnected" vertices (whose value is 0)  
    l_std = (l_std / (cv_num - 1)) ^ 0.5; % resulting standard deviation

    % report            
    if isprop(DWI.saf, indata) && strcmp(indata, inverts)
        logt{1} = round(numel(unique_verts(1, :)) / cv_num * 100, 2); % termination count density
    end

    logt{2} = round(l_mean, 2); 
    logt{3} = round(l_std, 2); 

end
