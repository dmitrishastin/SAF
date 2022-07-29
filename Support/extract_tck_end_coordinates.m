function [pts, se] = extract_tck_end_coordinates(tck)

    if isstruct(tck)
        fn = fieldnames(tck);
        assert(any(strcmp(fn, 'data')), 'wrong input provided');
        tck = tck.data;
    end
    
    empty_streamlines = cellfun(@isempty, tck);
    
    pts = cellfun(@(sl) sl([1 end], :)', tck(~empty_streamlines), 'un', 0);
    pts = reshape(cell2mat(pts'), [3 sum(~empty_streamlines) 2]);
    pts = [pts(:, :, 1) pts(:, :, 2)]';
    
    % flag for whether the coordinate belongs to the streamline end (as opposed to start)
    if nargout > 1        
        se = false(size(pts, 1), 1);
        se(size(pts, 1) / 2 + 1:end) = true;
    end
    
end