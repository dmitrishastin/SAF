function [PS, SD] = filters_GG_HH(PS, SD)

    % get ready
    verb_msg(['Preparing for streamline-cortex filters. Current time: ' datestr(datetime('now'), 'HH:MM')], PS)  
     
    % reject streamlines that only have 1 or 2 points
    lvec = cellfun(@(x) size(x, 1) > 2, SD.DWI.sl_tracks);
    nsl = length(SD.DWI.sl_tracks(lvec));    
	
    % perform/load coordinate clustering
    if ~any(strcmp(fieldnames(SD.DWI), 'cvk')) || isempty(SD.DWI.cvk) || PS.force
        [SD.DWI.cvk, PS.logt(end+1, :)] = coordinate_clustering(SD.DWI.cv, nsl);
    end
    
    % get ready
    PS.logt(end+1,:) = {'' ''};
    PS.logt(end+1,:) = {'Extraction of SAF:' ''};
    verb_msg(['Starting streamline-cortex filters. Current time: ' datestr(datetime('now'), 'HH:MM')], PS) 
    PS.logt(end+1,:) = {'Number of streamlines before filtering:' nsl};  
    rept = [PS.logt{end, 1} ' ' num2str(PS.logt{end, 2})]; verb_msg(rept, PS) 
    verb_msg('Starting GG & HH filtering', PS)
    filtert = tic;

    % collect all streamline terminations
    pts = cell2mat(cellfun(@(sl) sl([1 end], :), SD.DWI.sl_tracks(lvec), 'un', 0)');
    odd = logical(mod(1:nsl * 2, 2));
    pts = [pts(odd, :); pts(~odd, :)];
    
    % find closest vertex and distance
    [gg_idx, dd_idx] = find_closest_vertex(SD.DWI.cv, pts, SD.DWI.cvk);
    
    % null those outside of target distance / LHCT
    ggdd = SD.DWI.cvt(gg_idx) - dd_idx(:);
    gg_idx((ggdd + PS.gg_margin) < 0) = 0;
    
    % restore within-hemisphere indexation
    hh_idx = false(size(gg_idx));
    hh_idx(gg_idx > 0) = SD.DWI.cvh(gg_idx(gg_idx > 0));    
    gg_idx(gg_idx > 0) = SD.DWI.cvi(gg_idx(gg_idx > 0));  
    
    % check position of "marginal" terminations relative to WSM
    % and find the closest WSM vertex
    % ray casting would be too heavy - relies on anatomical priors instead
    if PS.gg_margin > 0
        
        opp_ends = [nsl + 1:nsl * 2, 1:nsl]';
        
        % id the "marginal" ones 
        mm_idx = gg_idx > 0 & ggdd < 0;
        
        % check which ones survive GGHH
        valid_idx = gg_idx > 0 & gg_idx(opp_ends) > 0 & hh_idx == hh_idx(opp_ends);
        keep_mgn = mm_idx & valid_idx;
                        
        margin_in = false(size(mm_idx));      
        
        % check 1: vectors from WSM vertices to terminations should not be co-aligned
        % with respective WSM normals (quick and meant to thin the numbers)
        hemi = {'rh' 'lh'};
        for side = 1:2
            side_vec = keep_mgn & hh_idx == side - 1;
            from_WSM_vec = pts(side_vec, :) - SD.DWI.(hemi{side}).white(gg_idx(side_vec), :);
            N = get_normals(SD.DWI.(hemi{side}).white, SD.DWI.(hemi{side}).faces);
            surf_norm_vec = N(gg_idx(side_vec), :);
            inside_pts = dot(from_WSM_vec, surf_norm_vec, 2) < 0;         
            margin_in(side_vec) = inside_pts;  
        end
        
        % update the "keep" vector              
        keep_mgn = mm_idx & valid_idx & margin_in;  
        mm_idx = zeros(size(mm_idx));
                
        % establish the nearest WSM vertices        
        for side = 1:2
            side_vec = keep_mgn & hh_idx == side - 1;
            wsm_idx = establish_closest_wsm(...
                pts(side_vec, :), ...
                SD.DWI.(hemi{side}).ht(gg_idx(side_vec)), ...
                SD.DWI.(hemi{side}).white, ...
                SD.DWI.(hemi{side}).usedv, ...
                PS.gg_margin);
            
            % check 2: null those with no WSM within LCHT + margin
            % (the radius around the related MCC within which the 
            % termination had to reside to be included in the first place)
            % this one doesn't yield much but we're doing the search anyway            
            side_vec(side_vec) = wsm_idx > 0;
            wsm_idx(wsm_idx == 0) = [];
            
            % check 3: distance to WSM should be smaller than distance to mid-cortical mesh
%            inside_pts = sum((SD.DWI.(hemi{side}).white(wsm_idx, :) - pts(side_vec, :)) .^ 2, 2) ...
%                < sum((SD.DWI.(hemi{side}).mid(gg_idx(side_vec), :) - pts(side_vec, :)) .^ 2, 2);
            
            % store the WSM indices of surviving terminations
%            wsm_idx(inside_pts == 0) = 0;
            mm_idx(side_vec) = wsm_idx;
            
        end
        
        % update the main output vector
        % mid-cortical indices remain stored in gg_idx even when
        % out of range as long as an appropriate WSM idx was found
        gg_idx(mm_idx == 0 & ggdd < 0) = 0;
        
    else
        
        mm_idx = false(size(gg_idx));
        
    end    
    
    % diagnostics
    if PS.dgn
        pts_to_tck(pts(gg_idx == 0, :), [PS.work_dir filesep 'rej.tck']);
        pts_to_tck(pts(ggdd >= 0, :), [PS.work_dir filesep 'mcc.tck']);
        pts_to_tck(pts(mm_idx > 0, :), [PS.work_dir filesep 'mgn.tck']);
    end
    
    % produce indexation of cortical intersection for all streamlines  
    % the "extremely short" streamlines are already accounted for here so
    % not including separately
    
    SD.DWI.saf.t_gghh = reshape(gg_idx, [], 2)'; % record GG allocation as closest MCC if pass or 0 if fail
    SD.DWI.saf.m = reshape(mm_idx, [], 2)';      % record nearest WSM of the survived marginal ones
    SD.DWI.saf.h = reshape(hh_idx, [], 2)';      % record HH allocation as 0 if rh or 1 if lh
    
    t = toc(filtert);
    logl = length(PS.logt) + 1;    
    PS.logt(end + 1,:) = {'Time spent on GG & HH filtering:' datestr(seconds(t),'HH:MM:SS')}; 
    PS.logt(end + 1,:) = {'Number of streamlines rejected due to extremely short length:' sum(~lvec)};
    PS.logt(end + 1,:) = {'Number of streamlines rejected during GG filtering:' ...
        sum(lvec) - sum(all(SD.DWI.saf.t_gghh))};
    PS.logt(end + 1,:) = {'Number of streamlines rejected during HH filtering:' ...
        sum(all(SD.DWI.saf.t_gghh) .* abs(diff(SD.DWI.saf.h)))};
    
    for i = logl:length(PS.logt)
        verb_msg([PS.logt{i, 1} ' ' num2str(PS.logt{i, 2})], PS)    
    end    
end

function wsm_idx = establish_closest_wsm(pts, ht, V, usedv, mgn)
    
    % create search boxes around the pt within ht + mgn distance
    BB_min = pts - (repmat(ht, [1 3]) + mgn);
    BB_max = pts + (repmat(ht, [1 3]) + mgn);
    wsm_idx = zeros(size(pts, 1), 1);

    parfor i = 1:size(pts, 1)
        
        % find all available wsm vertices within the search box
        VBB = all(V - repmat(BB_min(i, :), [size(V, 1) 1]) >= 0, 2) & ...
            all(V - repmat(BB_max(i, :), [size(V, 1) 1]) <= 0, 2) & usedv;
        
        % find the closest one
        if any(VBB)
            cp = dsearchn(V(VBB, :), pts(i, :));
            vi = find(VBB, cp, 'first');
            wsm_idx(i) = vi(end);
        end
    end
end

function NV = get_normals(V, F)

    nf = size(F, 1);
    nv = size(V, 1);
  
    % 1-ring of faces for all vertices
    FR{nv} = [];
    for i = 1:nf
        for j = 1:3
            FR{F(i, j)}(end + 1) = i;
        end
    end   

    % face normals as cross product of the two edges 
    % (length = twice the face area)
    NF = cross(V(F(:, 2), :) - V(F(:, 1), :), V(F(:, 3), :) - V(F(:, 1), :));
        
    % vertex normals - average of face normals
    % within the 1-ring weighted by their area, set to unit length
    NV = cell2mat(cellfun(@(x) sum(NF(x, :)), FR, 'un', 0)');
    D = sqrt(sum(NV .^ 2, 2));
    D(D < eps) = 1;
    NV = bsxfun(@rdivide, NV, D);

end