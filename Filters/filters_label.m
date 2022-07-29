function [lab_ind] = filters_label(vert,labs)

    %filtering vertices based on label values
    lab_id = fopen(labs);
    rubbish = fgetl(lab_id);
    rubbish = fgetl(lab_id);
    vert_ind = fscanf(lab_id,'%d  %f  %f  %f %f\n', [5 Inf])';
    fclose(lab_id);
    vert_ind = vert_ind(:, 1) + 1;
    lab_ind = false(size(vert, 1), 1);
    lab_ind(vert_ind) = true;
    
end