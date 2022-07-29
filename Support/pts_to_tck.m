function pts_to_tck(pts, output_tck, varargin)

    % convert points (Mx3) to tck for diagnostic work 
    % (visualise points in mrview by setting geometry to 'points')

    % varargin allows to input additional matrices Mx3 
    % such that coordinates in those matrices will be appended to pts
    % sequentially, growing into M streamlines

    pts = process_coords(pts);
    o_s = size(pts, 1);

    if nargin > 2
        o_s = [o_s cellfun(@(x) size(x, 1), varargin)];        
    end
    
    o_m = max(o_s);
    if ~o_m
        return
    end
    
    assert(~any(o_s - o_m), 'matrix sizes are different');

    for q = 1:nargin - 2
        pts(:, :, q + 1) = process_coords(varargin{q});
    end
    
    if any(isnan(pts(:)))
        warning('values contain nans, this is known to cause errors')
    end 
    
    a.data = squeeze(num2cell(permute(pts, [3 2 1]), 1:2));

    write_mrtrix_tracks(a, output_tck);

end