function I = trintersect_fast(P1, P2, P3, Q1, Q2)

    % detect intersection between a segment and a triangle face    
    % multiple rows representing individual triangle-segment pairs allowed
    %
    % P1, P2, P3    - triangle vertices
    % Q1, Q2        - segment end-points
    
    SignedVolume = @(a,b,d,c) (1/6) * dot(cross(b-a, c-a, 2), d-a, 2);
    repside = sign(SignedVolume(Q1,Q2,P2,P3));

    I = sign(SignedVolume(Q1,P1,P2,P3)) ~= sign(SignedVolume(Q2,P1,P2,P3));
    if any(I)
        I = I & (repside == sign(SignedVolume(Q1,Q2,P1,P2)));
    end
    if any(I)
        I = I & (repside == sign(SignedVolume(Q1,Q2,P3,P1)));
    end
    
end