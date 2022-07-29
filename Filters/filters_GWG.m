function [PS, DWI] = filters_GWG(PS, DWI)

    % get ready
    verb_msg('Starting GWG filtering', PS)
	
	if PS.fastx
		precision = 'fast';
	else
		precision = 'complete';
	end
	
    GWGt = tic;	
    
    % find the streamlines to feed into GWG
    valid_sl = all(DWI.saf.t_gghh) & ~DWI.saf.pg & ~DWI.saf.ml;   
    
    % output arrays
    if ~PS.gwg_hard || PS.gwg_hard && PS.notrunc	% remains aligned with all previous indexation
        new_streamlines = cell(1, size(DWI.saf.t_gghh, 2));
        DWI.saf.t_gwg = zeros(size(DWI.saf.m));
    else                                            % alignment completely undone
        new_streamlines = {};
        DWI.saf.t_gwg = [];        
    end
    
    % constrain to hemispheres to limit search
    for hemi = {'rh', 'lh'}
        
        % prepare the surface data - get the white surface
        V = DWI.(hemi{1}).white;
        F = DWI.(hemi{1}).faces;
        F(any(ismember(F, find(~DWI.(hemi{1}).usedv)), 2), :) = [];
        
        % find the hemispheric streamlines
        if strcmp(hemi{1}, 'rh')
            hemi_tracks = valid_sl & ~any(DWI.saf.h);
        else
            hemi_tracks = valid_sl & all(DWI.saf.h);
        end 
        
        % do the filtering
        % two identical algorithms calling different subcommands depending
        % on precision choice. may be excessive but probably slightly faster
        % than querying precision for each streamline
        [tcn, osi, xv, xp] = feval(['crop_streamlines_outside_mesh_' precision], ...
            V, F, DWI.sl_tracks(hemi_tracks), DWI.saf.m(1, hemi_tracks), ~PS.gwg_hard);
        
        % record outcomes        
        if ~PS.gwg_hard || PS.gwg_hard && PS.notrunc
                
            % only leave those that make exactly two crossings
            if PS.gwg_hard && PS.notrunc
                [~, uidx, oidx] = unique(osi);
                oidx = accumarray(oidx, 1);
                osi = osi(uidx(oidx == 1));
                xv = xv(:, uidx(oidx == 1));
            end

            % surviving hemispheric tracks
            temp_idx = find(hemi_tracks);
            osi = temp_idx(osi); 
            
            % remove those that start or end "inside"
            % without having been "approved" at the GG stage
            % this occurs because crop_streamlines_outside_mesh
            % allows streamlines to terminate anywhere inside the mesh
            % however, in SAF context this is only allowed when GG_margin
            % is enabled and of course anything not detected in GG is invalid
            r_idx = ~all(DWI.saf.m(:, osi) | xv);
            osi(r_idx) = [];
            xv(:, r_idx) = [];            
            
            % clear wsm indices from GWG if GG indices (with margin flag)
            % exist as the latter should be more accurate
            xv(DWI.saf.m(:, osi) > 0) = 0;
            
            % allocate the rest 
            DWI.saf.t_gwg(:, osi) = logical(DWI.saf.t_gghh(:, osi)) .* DWI.saf.m(:, osi) + xv;

            % allocate truncated streamlines
            if ~PS.notrunc
                new_streamlines(osi) = tcn(~r_idx);                    
            end
            
        else
            
            % surviving hemispheric tracks
            temp_idx = find(hemi_tracks);
            osi = temp_idx(osi); 
            
            % create some indices
            [s_idx, e_idx] = deal(false(1, length(osi)));
            u_idx = false(1, length(DWI.saf.m(1, :)));
            [~, ss] = unique(osi);           
            [~, ee] = unique(flip(osi));     
            ee = numel(osi) + 1 - ee;
            u_idx(osi) = true;                  % "unique" set with original streamline indices
            s_idx(ss) = true;                   % indices of "starting" segments (per original streamline)
            e_idx(ee) = true;                   % indices of "ending" segments (per original streamline)
            r_idx = ~all(DWI.saf.m(:, osi) | xv) & any(xv == 0); % those that end "inside" without being "approved" at the GG stage

            % overwrite wsm indices from GWG with GG indices that exist
            % from margin flag as the latter should be more accurate
            ss = s_idx & DWI.saf.m(1, osi);     % streamline starts that already have WSM allocated 
            ee = e_idx & DWI.saf.m(2, osi);     % streamline ends that already have WSM allocated
            xv(1, ss) = DWI.saf.t_gghh(1, u_idx & DWI.saf.m(1, :));
            xv(2, ee) = DWI.saf.t_gghh(2, u_idx & DWI.saf.m(2, :));

            % record which points of those streamlines got intersected
            % (if any) from white matter got accepted through GG_margin,
            % make sure the very terminal streamline point gets recorded             
            xp(1, ss) = xp(1, ss) - 1;
            xp(2, ee) = xp(2, ee) + 1;

            % record the updates
            osi(r_idx) = []; xv(:, r_idx) = [];  xp(:, r_idx) = [];
            DWI.saf.pre_c(end+1:end+numel(osi)) = osi;
            DWI.saf.pre_xp(:, end+1:end+numel(osi)) = xp;            
            DWI.saf.t_gwg(:, end+1:end+size(xv, 2)) = xv;
            
            % allocate truncated streamlines
            new_streamlines(end+1:end+sum(~r_idx)) = tcn(~r_idx); 
            
        end
    end
    
    % update hemispheric indices
    if PS.gwg_hard && ~PS.notrunc
        DWI.saf.pre_h = DWI.saf.h;
        DWI.saf.h = false(size(DWI.saf.t_gwg));
        DWI.saf.h(:, end-sum(~r_idx)+1:end) = true;
    end

    % replace native streamlines with truncated ones
    if ~PS.notrunc
        DWI.sl_tracks = new_streamlines;
    end

    % report
    t = toc(GWGt); 
    PS.logt(end + 1, :) = {'Time spent on GWG filtering:' datestr(seconds(t),'HH:MM:SS')};
    logl = length(PS.logt);    
    if ~PS.gwg_hard || PS.gwg_hard && PS.notrunc
        rejn = sum(valid_sl) - sum(all(DWI.saf.t_gwg));          
        PS.logt(end + 1, :) = {'Number of streamlines rejected during GWG filtering:' rejn};    
    else            
        PS.logt(end + 1, :) = {'Number of streamlines after GWG filtering:' numel(new_streamlines)};    
    end
    for i = logl:length(PS.logt)
        rept = [PS.logt{i, 1} ' ' num2str(PS.logt{i, 2})]; 
        verb_msg(rept, PS)    
    end
    
end
