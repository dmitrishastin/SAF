function FR = compute_vertex_fring(F)

    % find 1-ring of faces for all vertices

    FR{max(F(:))} = [];
    for i = 1:size(F, 1)
        for j = 1:3
            FR{F(i, j)}(end + 1) = i;
        end
    end    
end