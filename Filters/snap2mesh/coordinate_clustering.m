function [p_clustering, elapsed] = coordinate_clustering(p, nsl)
    
    % decide on the number of clusters - cut-off arbitrary
    if nsl > 5e5
        k = round(size(p, 1) ^ 0.5);
    else        
        k = deal(60); % arbitrary
    end

    % k-means based on euclidean distance        
    kmt = tic;       
    warning('off','all')
    p_clustering = kmeans(p, k);                
    warning('on','all')        
    t = toc(kmt);
    elapsed = {['Time spent on surface coordinate clustering (k=' num2str(k) '):'] datestr(seconds(t),'HH:MM:SS')};

end