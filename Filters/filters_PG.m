function [PS, DWI] = filters_PG(PS, DWI)

    if ~isempty(DWI.saf.pg) && any(any(DWI.saf.pg)) && ~PS.force
        return
    end

    % create a blank PG output array - true means intersection / discard
    [DWI.saf.pg, pial_sl_wb] = deal(false(1, size(DWI.saf.t_gghh, 2)));

    % abandon if not desired
    if ~PS.pialfilter; return; end 

    % get ready
    verb_msg('Starting PG filtering', PS)
    pialt = tic;   
	if PS.fastx
		precision = 'fast';
	else
		precision = 'complete';
	end
    
    % constrain to hemispheres to limit search
    for hemi = {'rh', 'lh'}
        
        % prepare the surface data - get the pial surface
        V = DWI.(hemi{1}).pial;
        F = DWI.(hemi{1}).faces;
        F(any(ismember(F, find(~DWI.(hemi{1}).usedv)), 2), :) = [];
        
        % find the hemispheric streamlines
        if strcmp(hemi{1}, 'rh')
            hemi_tracks = all(DWI.saf.t_gghh) & ~any(DWI.saf.h);
        else
            hemi_tracks = all(DWI.saf.t_gghh) & all(DWI.saf.h);
        end
        
        % do the filtering 
        [~, osi, ~, xp] = feval(['crop_streamlines_outside_mesh_' precision], ...
            V, F, DWI.sl_tracks(hemi_tracks), true, true);        
        
        % detect escapes (see GWG for explanation)
        temp_idx = find(hemi_tracks);
        osi = temp_idx(osi); 
        xx = xp(1, :) > 1 | xp(2, :) ~= cellfun(@(x) size(x, 1), DWI.sl_tracks(osi));
        
        % convert back to whole-brain indexation
        pial_sl_wb(osi(xx)) = true;
        
    end
       
    % store the indices   
    DWI.saf.pg = pial_sl_wb;
    
    % update
    t = toc(pialt);
    PS.logt(end + 1, :) = {'Time spent on pial streamlines removal:' datestr(seconds(t),'HH:MM:SS')}; 
    rept = [PS.logt{end, 1} ' ' num2str(PS.logt{end, 2})]; verb_msg(rept, PS)
    PS.logt(end + 1, :) = {'Number of streamlines rejected due to intersection with the pia:' sum(pial_sl_wb)};
    rept = [PS.logt{end, 1} ' ' num2str(PS.logt{end, 2})]; verb_msg(rept, PS)
    
end