function [per_F, per_V, F_centroids] = calculate_normals(V, F, varargin)

    nf = size(F, 1);
    nv = size(V, 1);
    per_V = zeros(nv, 3);
    d = @(v) sqrt(sum(v .^ 2, 2));
    
    % centroids
    if nargout > 2
        VF = @(x) [V(F(:, 1), x) V(F(:, 2), x) V(F(:, 3), x)];
        F_centroids = [mean(VF(1), 2) mean(VF(2), 2) mean(VF(3), 2)];
    end
    
    % face normals
    per_F = cross(V(F(:, 2), :) - V(F(:, 1), :), V(F(:, 3), :) - V(F(:, 1), :));    
    D = d(per_F); 
    D (D < eps) = 1;
    per_F = bsxfun(@rdivide, per_F, D);

    if nargout > 1   
        
        % per-face weigths
        if nargin > 2
            W = varargin{1};
            assert(isa(W, 'double') && length(W) == nf, 'wrong weights provided')
        else
            [~, W] = calculate_mesh_area(V, F);
        end
        
        % apply weights
        per_F = bsxfun(@times, per_F, W);        
        
        % vertex normals
        per_V = cell2mat(cellfun(@(x) sum(per_F(x, :), 1), compute_vertex_fring(F), 'un', 0)');
        D = d(per_V);
        D(D < eps) = 1;
        per_V = bsxfun(@rdivide, per_V, D);
        
    end    
end