function instr = make_full_path(instr, varargin)

    % sort out work_dir
    work_dir = pwd;    
    if nargin > 1
        work_dir = varargin{1}; 
        ff = fileparts(work_dir);
        if isempty(ff)
            work_dir = [pwd filesep work_dir];
        end
    end
    
    % sort out input
    if ischar(instr)
        instr = process_each(instr, work_dir);
    elseif iscell(instr)
        instr = cellfun(@(x) process_each(x, work_dir), instr, 'un', 0);
    end
   
end

function instr = process_each(instr, work_dir)

    ff = fileparts(instr);
    if isempty(ff)
        instr = [work_dir filesep instr];
    end

end