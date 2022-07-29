function [ind, bin_area, bin_edges] = discretise_surface_function(vert_area, func, varargin)

    % define the number of bins (default: 5)
    nbins = 5;
    if nargin > 2
        nbins = varargin{1};
    end

    % define area of each bin
    bin_area = sum(vert_area) / nbins;
    
    % order func entries
    [~, sort_ind] = sort(func);
    
    % apply ordering to vertex areas
    area_sort = vert_area(sort_ind);
    
    [nverts, bin_edges] = deal(zeros(nbins, 1));
    ind = ones(size(vert_area)) * nbins;
    
    % cumsum of areas sorted by func values
    y = cumsum(area_sort);
    
    % go through all bins
    for i = 1:nbins
        
        % subtract single bin area from the cumsum vector
        y = y - bin_area;
        
        % find it absolute values' minimum (signifies boundary between bins)
        [~, nverts(i)] = min(abs(y));
        
        % define bin edge in terms of func value        
        bin_edges(i) = func(sort_ind(sum(nverts)));
        
        % index vertices
        shift = sum(nverts(1:i - 1));
        ind(sort_ind(shift + 1:shift + nverts(i))) = i;
        
        % update y
        y(1:nverts(i)) = [];
        
    end
    
    % get rid of the last bin edge
    bin_edges(end) = [];

end