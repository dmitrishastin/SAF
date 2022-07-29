function sc = process_coords (ic)

    % takes MRtrix -output_seeds file, aNTS output file, a plain 
    % space-separated three-column matrix file or just a three-column MATLAB array

    if ischar(ic) 

        try
            
        % if the input a file (e.g., output of antsApplyTransformsToPoints or output of mrtrix -output_seeds), convert to matrix

            cds_id = fopen(ic);
            column_names = fgetl(cds_id);
            
            if strcmp(column_names, 'x,y,z,t') 
                
                %assume ants output
                %disp('Assuming the coordinate input is from ANTS');
                
                sc = fscanf(cds_id,'%f,%f,%f,%f\n',[4 Inf])';
                sc = [-sc(:,1) -sc(:,2) sc(:,3)];
                
            elseif strcmp(column_names(1), '#')                
                
                %assume mrtrix output
                %disp('Assuming the coordinate input is from MRTRIX');
                
                while strcmp(column_names(1), '#') %can have more than one string
                    pos = ftell(cds_id);
                    column_names = fgetl(cds_id);
                end
                
                fseek(cds_id, pos, -1); %return to the beginning of the previous string
                
                sc = fscanf(cds_id,'%d,%d,%f,%f,%f,\n',[5 Inf])';
                sc = [sc(:,3) sc(:,4) sc(:,5)];
                
            else        
            
                % if the input is any other file
                %disp('Assuming the coordinate input is a three-column matrix with RAS coordinates separated by spaces');

                frewind(cds_id);
                sc = fscanf(cds_id,'%f %f %f\n',[3 Inf])';

            end 
            
            fclose(cds_id);
            
        catch
            error('Error processing input')            
        end
        
    % otherwise if already a matrix, proceed
    elseif ismatrix(ic)        
        sc = ic;
    else
        error('Wrong coordinate input')
    end
    
end