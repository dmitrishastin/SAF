function [tract, orig_sl_ind, xverts, xpoints] = crop_streamlines_outside_mesh_complete(V, F, tract, inside, outer_intersection)
  
    % crops streamlines at the mesh wall 
    %
    % inputs:
    %
    % inside is a boolean to indicate whether the start of the streamline
    % lies on the side of the mesh where streamlines are to be preserved
    % and is passed as a scalar (for all) or vector (per streamline)
    %
    % outer_intersection if a boolean that will preserve the streamline
    % between the two intersecting points closest to the streamline ends,
    % leaving all intersections in between untouched
    %
    % outputs:
    % 
    % tracts - cropped streamlines
    % orig_sl_ind - indices of cropped streamlines as they were in the original input
    % xverts - surface vertex closest to each cropped end
    % xpoints - points of the original streamlines at which intersection / cropping occurred

    % init
    nsl = length(tract); [rsl, rxf, osi, slp] = deal(cell(1, nsl));    
    
    % whether the first point of each streamline is inside the mesh    
    if nargin < 4 || isempty(inside)
        inside = false(nsl, 1);
    elseif length(inside) == 1 && length(tract) > 1
        inside = repmat(inside, [1 length(tract)]);        
    end
    
    % only crop at the exterior intersecting segments of each streamline (ignore intersetions in between)
    if nargin < 5
        outer_intersection = false;
    end

    % pre-calculate face bounding boxes
    F_VC = @(d) [V(F(:, 1), d) V(F(:, 2), d) V(F(:, 3), d)];
    FBB_max = [max(F_VC(1), [], 2) max(F_VC(2), [], 2) max(F_VC(3), [], 2)];
    FBB_min = [min(F_VC(1), [], 2) min(F_VC(2), [], 2) min(F_VC(3), [], 2)];  

    % at this point (following GG filter) assuming most if not all streamline BBs 
    % will be intersecting at least one face BB hence going through all
    parfor i = 1:nsl

        % prepare the streamline
        sl = tract{i}; [xS, xF] = deal([]); 

        % generate a streamline bounding box
        SBB_min = min(sl, [], 1);
        SBB_max = max(sl, [], 1);

        % find all streamline / face BB intersections
        xFBB = all(...
            bsxfun(@ge, FBB_max, SBB_min) & ...
            bsxfun(@le, FBB_min, SBB_max), 2);
        
        if any(xFBB)

            % get intersected FBB
            F_max = FBB_max(xFBB, :);
            F_min = FBB_min(xFBB, :);

            % define individual BB for every streamline segment
            SLE = [sl(1:end-1,:) sl(2:end,:)];
            SLE = SLE(:, [1 4 2 5 3 6]);                
            S_min = [min(SLE(:,1:2),[],2) min(SLE(:,3:4),[],2) min(SLE(:,5:6),[],2)];
            S_max = [max(SLE(:,1:2),[],2) max(SLE(:,3:4),[],2) max(SLE(:,5:6),[],2)];

            frm = [1 size(SLE, 1)];
            srm = [sum(xFBB) 1];

            % see if there is intersection of the face / streamline boxes
            X = repmat(F_max(:, 1), frm) >= repmat(S_min(:, 1)', srm) & ...
                repmat(F_min(:, 1), frm) <= repmat(S_max(:, 1)', srm);

            Y = repmat(F_max(:, 2), frm) >= repmat(S_min(:, 2)', srm) & ...
                repmat(F_min(:, 2), frm) <= repmat(S_max(:, 2)', srm);

            Z = repmat(F_max(:, 3), frm) >= repmat(S_min(:, 3)', srm) & ...
                repmat(F_min(:, 3), frm) <= repmat(S_max(:, 3)', srm);

            % FACE BB x STREAMLINE SEGMENT BB logical matrix
            BBFX = X & Y & Z;

            % do geometrical validation 
            TFX = zeros(size(BBFX)); % parfor wants explicit declaration, do not remove            
            if any(BBFX(:)) 

                xFBB = find(xFBB);
                [xF, xS] = find(BBFX);
                P = V(F(xFBB(xF), :), :);
                np = numel(xF);    
                
                TFX(BBFX) = trintersect_complete(...
                    P(1:np, :), ...             % triangle vertex 1
                    P(np+1:np*2, :), ...        % triangle vertex 2
                    P(2*np+1:end, :), ...       % triangle vertex 3
                    sl(xS, :), ...              % segment end 1
                    sl(xS+1, :), ...            % segment end 2
                    F(xFBB(xF), :), ...         % mesh vertex indices per face 
                    xF, ...                     % mesh face indices 
                    xS);                        % streamline vertex indices 

                % xF - intersecting face, xS - intersecting streamline segment            
                [xF, xS] = find(TFX);
                xF = xFBB(xF); % face indices in F 

            end
        end

        % define streamline chains "within" the mesh
        % xP refers to the first point (unlike xS which refers to segments) 
        % of each chain within the main streamline that is to be kept
        xP = xS' + 1; xF = xF';
        
        % include the head end of the streamline if it starts "inside" the mesh
        if inside(i) 
            xP = [1 xP];
            xF = [nan xF];
        end

       % include the tail end if there is an odd number of intersections
        if mod(numel(xP), 2) 
            xP = [xP size(sl, 1)];
            xF = [xF nan];
        end
        
        % optionally don't consider anything by the outer intersections at either end
        if outer_intersection && ~isempty(xF)         
            xP(2:end-1) = [];
            xF(2:end-1) = [];  
        end

        % xI is Nx2 where rows are chains and columns are starting and finishing points to keep
        xI = reshape(xP, 2, [])';
        xI(xI(:, 2) < size(sl, 1), 2) = xI(xI(:, 2) < size(sl, 1), 2) - 1;
        
        % xIF refers to the triangles crossed at either end of each chain
        xIF = reshape(xF, 2, []);

        % chains separately from the rest of the streamline
        tsl = arrayfun(@(j) sl(xI(j, 1):xI(j, 2), :), 1:size(xI, 1), 'un', 0);

        % if after truncating the chain length is < 2 pts, discard
        l = cellfun(@(x) size(x, 1) > 1, tsl);              
        
        rsl{i} = tsl(l);                    % truncated chains of sl
        slp{i} = xI(l, :)';                 % intersecting segments of sl
        rxf{i} = xIF(:, l);                 % triangles intersected by sl
        osi{i} = repmat(i, sum(l), 1);      % mapping between indices of chains and indices of original streamlines

    end
    
    % expand the outputs
    tract = cat(2, rsl{~cellfun(@isempty, rsl)})';
    orig_sl_ind = cell2mat(osi');
    end_faces = cell2mat(rxf);
    xpoints = cell2mat(slp);
    
    % find closest vertex for each termination
    if nargout > 2
        
        ef = end_faces';
        xf = ~isnan(ef);

        pts = cellfun(@(sl) sl([1 end], :)', tract, 'un', 0);
        pts = reshape(cell2mat(pts'), [3 length(tract) 2]);
        pts = [pts(:, :, 1) pts(:, :, 2)]';
        pts = pts(xf', :);
        
        v1 = sum((pts - V(F(ef(xf), 1), :)) .^ 2, 2);
        v2 = sum((pts - V(F(ef(xf), 2), :)) .^ 2, 2);
        v3 = sum((pts - V(F(ef(xf), 3), :)) .^ 2, 2);
        
        [~, cfv] = min([v1 v2 v3], [], 2);
        
        fi = F(ef(xf), :);
        fi = fi(sub2ind([sum(xf(:)) 3], 1:sum(xf(:)), cfv'));
        xverts = zeros(size(ef));
        xverts(xf) = fi;   
        xverts = xverts';
        
    end

end
