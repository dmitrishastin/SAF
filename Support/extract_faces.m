function [F_v, F_e] = extract_faces(usedv,F)
    
    F_e = F;

    % find excluded vertices
    for i = 1:numel(F)

        F_e(i) = usedv(F(i));

    end

    % find faces with excluded vertices
    for i = 1:size(F_e,1);

        fe(i) = all(F_e(i,:));

    end

    % exclude faces
    [F_e, F_v] = deal(F(fe,:));

    % renumerate the vertices of faces
    V_r = 1:1:length(usedv);
    V_r(usedv==0) = [];

    for i = 1:numel(F_v)

        F_v(i) = find(V_r(:) == F_v(i));

    end
end