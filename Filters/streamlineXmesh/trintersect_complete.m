function I = trintersect_complete(P1, P2, P3, Q1, Q2, V, F, S)

    % Detect intersection between a segment and a triangle including 
    % vertices, edges, face
    %
    % Multiple rows representing individual triangle-segment pairs allowed
    % 
    % Per triangle-segment pair:
    %
    % P1, P2, P3    - triangle vertices
    % Q1, Q2        - segment end-points
    % V             - triangle vertex indices (not coordinates)
    % F             - triangle face index
    % S             - streamline segment index
    %
    % Specific behaviour:
    %
    % - allow no more than one intersection 
    %   per triangle per streamline segment, adjacent half-edges included
    % - streamline segments parallel with face or edge not considered
    % - intersecting streamline vertices lying on the mesh counted once
    %   per adjacent segment pair
    
    nx = size(P1, 1);
    ex = false(nx * 3, 1); % edges and vertices to skip (triangles already flagged up)
    
    
    %% face intersection
    
    SignedVolume = @(a,b,d,c) (1/6) * dot(cross(b-a, c-a, 2), d-a, 2);    
    f = sign(SignedVolume(Q1,P1,P2,P3)) ~= sign(SignedVolume(Q2,P1,P2,P3));
    
    if any(f)          
        f(f) = sign(SignedVolume(Q1(f,:),Q2(f,:),P2(f,:),P3(f,:))) == ...
               sign(SignedVolume(Q1(f,:),Q2(f,:),P1(f,:),P2(f,:)));
        
        if any(f)
            f(f) = sign(SignedVolume(Q1(f,:),Q2(f,:),P2(f,:),P3(f,:))) == ...
                   sign(SignedVolume(Q1(f,:),Q2(f,:),P3(f,:),P1(f,:))); 
            
            % for each segment, for every face intersected (could be multiple)
            % do not search for edges or vertices        
            if any(f) 
                [~, la, lb] = unique([S F], 'rows');
                fx = false(nx, 1);
                fx(la(lb(f))) = true;
                ex = repmat(fx, [3 1]);
            end
        end
    end
    
   
    %% vertex intersection
    
    % plucker direction
    D = @(p1, p2) p2 - p1; 
    
    % plucker moment
    M = @(p1, p2) cross(p1, D(p1, p2), 2);
    
    % check that the vertex lies on the same line as the segment
    L = @(q1, q2, p) all(abs(cross(p, D(q1, q2), 2) - M(q1, q2)) < eps, 2);
    
    % check that it lies on the segment including the ends
    P = @(q1, q2, p) dot(q1 - q2, p - q2, 2) ./ dot(q1 - q2, q1 - q2, 2);   
    X = @(q1, q2, p) P(q1, q2, p) >= 0 & P(q1, q2, p) <= 1; 
    
    % for all three vertices
    q1 = repmat(Q1, [3 1]);
    q2 = repmat(Q2, [3 1]);
    p1 = [P1; P2; P3];
    
    % detect intersections excluding vertices of triangles already captured
    v = ~ex; 
    if any(v)
        v(v) = L(q1(v,:), q2(v,:), p1(v,:)); 
        
        if any(v)
            v(v) = X(q1(v,:), q2(v,:), p1(v,:));
            
            % for each segment, record every vertex intersected just once
            if any(v)
                [~, la, lb] = unique([repmat(S, [3 1]) V(:)], 'rows');
                v0 = false(nx * 3, 1);
                v0(la(lb(v))) = true;
                v = v0;
            end
        end
    end
    
    
    %% edge intersection
    
    % check if lines are nonparallel
    A = @(p1, p2, q1, q2) any(abs(cross(D(p1, p2), D(q1, q2), 2)) > eps, 2);
    
    % check if lines are coplanar (plucker reciprocal product)
    R = @(p1, p2, q1, q2) abs(dot(D(p1, p2), M(q1, q2), 2) + dot(D(q1, q2), M(p1, p2), 2)) < eps; 
    
    % retrieve intersection coordinates
    C = @(p1, p2, q1, q2) squeeze(sum(permute( ...
        repmat(dot(M(p1, p2), D(q1, q2), 2), [1 3 3]) .* ...
        permute(repmat(eye(3), [1 1 size(p1, 1)]), [3 1 2]) + ...
        repmat(D(p1, p2), [1 1 3]) .* permute(repmat(M(q1, q2), [1 1 3]), [1 3 2]) - ...
        repmat(D(q1, q2), [1 1 3]) .* permute(repmat(M(p1, p2), [1 1 3]), [1 3 2]), [1 3 2]) .* ...
        repmat(cross(D(p1, p2), D(q1, q2), 2), [1 1 3]), 2)) ./ ...
        repmat(sum(cross(D(p1, p2), D(q1, q2), 2) .^ 2, 2), [1 3]);
    
    % check that it lies between the ends of each segment / edge
    Z = @(q1, q2, p) P(q1, q2, p) > eps & P(q1, q2, p) < 1 - eps;        
    
    % for all three edges
    p2 = [P2; P3; P1];    
    
    % detect intersections excluding edges of triangles already captured
    e = ~ex;    
    if any(e)
        e(e) = A(p1(e,:), p2(e,:), q1(e,:), q2(e,:));
        
        if any(e)
            e(e) = R(p1(e,:), p2(e,:), q1(e,:), q2(e,:));
            
            if any(e)
                e2 = C(p1(e,:), p2(e,:), q1(e,:), q2(e,:));
                e(e) = Z(p1(e,:), p2(e,:), e2) & X(q1(e,:), q2(e,:), e2);

                % for each segment, record every half-edge 
                % and adjacent half-edge intersected just once
                if any(e)
                    fe = [V(:, [1 2]); V(:, [2 3]); V(:, [3 1])]; % all half-edges 
                    [~, la, lb] = unique([repmat(S, [3 1]) sort(fe, 2)], 'rows');
                    e0 = false(nx * 3, 1);
                    e0(la(lb(e))) = true;
                    e = e0;
                end
            end
        end   
    end
    
    
    %% put everything together

    v = false(nx * 3, 1);
    e = false(nx * 3, 1);
    
    v = reshape(v, nx, 3);
    e = reshape(e, nx, 3);    
    I = f | any(e | v, 2); 
    
    % detect streamline vertices on the mesh (get counted twice - once per
    % adjacent segment)
    us = unique(S(I));
   
    if any(I) && numel(us) > 1
        
        % detect consecutive intersecting segments
        cons = diff(us) == 1;
        
        % check if their shared vertex belongs to the mesh
        if any(cons)
            cons = find(cons);
            for i = 1:numel(cons)
                first_in_pair = us(cons(i));
                i_idx = I & S == first_in_pair;                
                coord = Q2(find(i_idx, 1),:);                
                
                % check that both segments have registered
                % intersection of the same type of element
                i_idx2 = I & S == first_in_pair + 1;                
                if ~(any(f(i_idx)) && any(f(i_idx2))) && ...
                   ~(any(e(i_idx, :)) && any(e(i_idx2, :))) && ...
                   ~(any(v(i_idx, :)) && any(v(i_idx2, :)))
                    continue
                end
                
                if any(any(v, 2) & i_idx) % if intersection is on a vertex
                    vertices = unique([P1(i_idx,:); P2(i_idx,:); P3(i_idx,:)], 'rows');
                    x = any(ismember(vertices, coord, 'rows'));
                elseif any(any(e, 2) & i_idx) % if intersection is on an edge
                    edges1 = [P1(i_idx,:); P2(i_idx,:); P3(i_idx,:)];
                    edges2 = [P2(i_idx,:); P3(i_idx,:); P1(i_idx,:)];
                    cc = repmat(coord, [size(edges1, 1) 1]);
                    x = any(...
                        L(edges1, edges2, cc) & ...
                        Z(edges1, edges2, cc));
                else % if intersection is on a face - dealing with multiple possible faces
                    nf = sum(i_idx);
                    edges1 = [P1(i_idx,:); P2(i_idx,:); P3(i_idx,:)];
                    edges2 = [P2(i_idx,:); P3(i_idx,:); P1(i_idx,:)];
                    c1 = [bsxfun(@minus, edges1, coord); edges1((1:nf)*3 - 1,:) - edges1((1:nf)*3 - 2,:)];
                    c2 = [bsxfun(@minus, edges2, coord); edges1((1:nf)*3,:) - edges1((1:nf)*3 - 2,:)];
                    cc = sqrt(sum(cross(c1, c2, 2) .^ 2, 2));
                    cc = reshape(cc(1:nf*3), [], 3) ./ repmat(cc(nf*3+1:end), [1 3]);                    
                    x = any(all(0 >= cc & cc <= 1, 2));
                    
                end
                
                % if so, remove one of them
                if x                    
                    I(i_idx) = false;
                end
            end
        end        
    end  
end