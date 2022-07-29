function [I, D] = find_closest_vertex(p1, p2, p1_clustering)

    % split p1 into clusters and record centroids
    k = max(p1_clustering);    
    p1_groups = arrayfun(@(x) [p1(p1_clustering == x, :) find(p1_clustering == x)], 1:k, 'un', 0)'; % 4th column - original index in p1
    p1g_centroids = cell2mat(cellfun(@mean, p1_groups, 'un', 0)); p1g_centroids(:, 4) = [];
    
    % check which cluster centroid each p2 lies closest to
	[~, centroid_i] = pdist2(p1g_centroids, p2, 'euclidean', 'sma', 1);
    
    % split p2 based on the nearest cluster
    p2_groups = arrayfun(@(x) p2(centroid_i == x, :), 1:k, 'un', 0);    
    
    % find the nearest p1 for each p2 within the nearest p1 cluster
    [i, d] = deal(cell(k, 1));
    parfor x = 1:k
        [p1p2_distance, cluster_idx] = pdist2(p1_groups{x}(:, 1:3), p2_groups{x}, 'euclidean', 'sma', 1);
        i{x} = p1_groups{x}(cluster_idx, 4);  % records original position of closest p1
        d{x} = p1p2_distance(:);              % distance from p2 to closest p1
    end
    
    % restore pointwise ordering
    ptsi = cell2mat(arrayfun(@(x) find(centroid_i == x), 1:k, 'un', 0));
    [I, D] = deal(zeros(size(i)));
    i = cell2mat(i); I(ptsi) = i;
    d = cell2mat(d); D(ptsi) = d;
    
end