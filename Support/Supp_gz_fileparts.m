% Function borrowed from Dr Greg Parker - many thanks!

function [pp, nn, ext] = Supp_gz_fileparts( fname )

    if strcmp( fname(end), 'z' )
        [pp, nn] = fileparts(fname(1:end-3));
        ext = '.nii.gz';
    else
        [pp, nn, ext] = fileparts(fname);
    end
    
end
