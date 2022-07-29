classdef init_class
    
    properties % Pipeline settings with default values
                
        % Initiation:
        
        fod             
        fs_dir          
        work_dir
        logt            % hidden flag
        
        % Freesurfer related:
        
        slab            = 'cortex';
        
        % Tractography related:
        
		surfseed		= true;
        tckgen      	= '';
        noseed          = '';
        sl_weights      = '';
        maxlen          = 90;
        final_init      % hidden flag 
        
        % Pipeline options:
        
        remesh_seeds    = false;
        registration    = 'SAF_registration_default';
        noregister      = false;      
        notrunc         = false;        
        fa              = '';
        wrks            = '';
        optmodules      = '';
        scalar2surf     = '';
        
        % Filter settings:
        
		fastx			= true;
        pialfilter      = false;
        gwg_hard        = false;
        gg_margin       = 0;
        
        % General:
        
        mrtrix_prefix   = '';
        outf            = -1;
        force           = false;
        dgn             = false; 
        quiet           = false;
        version         = '1.0.0';
        
    end           

    methods 
        
    %% parse custom parameters
    function this = init_class(parsed_input)
        
        % values not required (set to true if not provided)
        arguments_bool = {'dgn', 'notrunc', 'noregister', 'force', 'quiet', ...
            'pialfilter', 'remesh_seeds', 'gwg_hard', 'surfseed', 'fastx'};

        % can take multiple arguments
        arguments_multi = {'optmodules','scalar2surf'};

        % arguments pointing to a file
        arguments_path = {'fod', 'fa', 'noseed', 'sl_weights'};
        
        while ~isempty(parsed_input)
            
            % if PS from a previous run is passed, accept its values and move on
            old_PS = cellfun(@(x) isa(x, 'init_class'), parsed_input);
            if any(old_PS)
                this = parsed_input{old_PS};
                this.logt = '';
                this.final_init = '';
                this.force = true;
                parsed_input(old_PS) = [];
                continue
            end
            
            % get the name-value combinations
            iname = parsed_input{1}; parsed_input(1) = [];
            assert(any(strcmp(iname, fieldnames(this))), 'wrong input provided');
            ival = {};            
            while ~isempty(parsed_input) && (~ischar(parsed_input{1}) || ~any(strcmp(parsed_input{1}, fieldnames(this))))
                if iscell(parsed_input{1})
                    ival(end + 1: end + numel(parsed_input(1))) = parsed_input(1);
                else
                    ival(end + 1) = parsed_input(1); 
                end
                parsed_input(1) = [];
            end
            
            % for input providing external files - make sure path not relative
            if any(strcmp(iname, arguments_path))
                ival = make_full_path(ival);
            end
            
            switch numel(ival)
                case 0
                    assert(any(strcmp(arguments_bool, iname)), [iname ' requires values to proceed'])
                    this.(iname) = true;
                case 1
                    if any(strcmp(arguments_bool, iname))
                        switch ival{1}
                            case {'on' 1}
                                ival{1} = true;
                            case {'off' 0}
                                ival{1} = false;
                        end
                    end
                    if any(strcmp(arguments_multi, iname))
                        this.(iname) = [this.(iname) ival{1}];
                    else
                        this.(iname) = ival{1};
                    end
                otherwise
                    assert(any(strcmp(arguments_multi, iname)), [iname ' does not take multiple values'])                    
                    this.(iname) = [this.(iname) ival];                    
            end                    
        end

        % if {''} is passed to multivalue inputs, the whole lot is purged
        for mvi = arguments_multi           
            if iscell(this.(mvi{1})) && any(cellfun(@isempty, this.(mvi{1})))
                this.(mvi{1}) = {};
            end
        end

        this = workdir(this);
        this = sortFS(this);    
        this = n_wrks(this);            
        this = start_log(this);

		% checks
        assert(~isempty(this.fod) && ~isempty(this.fs_dir), 'FOD file and FreeSurfer dir must be provided');
		assert(~isempty(this.fa) || this.noregister, 'Provide FA for registration or ensure "noregister" flag is on');
		assert(isempty(this.tckgen) || isempty(this.noseed), 'Either "tckgen" or "noseed" must be empty');

        if this.dgn
            this.quiet = false;
        end

        % switches off maxlen if streamlines already shorter via tckgen
        if ~isempty(this.maxlen) && ~isempty(this.tckgen)
            [~, tckgen_maxlen] = regexp(this.tckgen, '-maxlength ', 'once');
            if ~isempty(tckgen_maxlen)
                tckgen_maxlen = sscanf(this.tckgen(tckgen_maxlen + 1:end), '%d{1}');
                if tckgen_maxlen < this.maxlen
                    this.maxlen = [];
                end
            end
        end
    end
        
    %% sort out parallel workers
    function this = n_wrks(this)

        if isempty(this.wrks)

            this.wrks = parcluster(parallel.defaultClusterProfile); 
            this.wrks = this.wrks.NumWorkers;

        elseif ischar(this.wrks)

            this.wrks = str2double(this.wrks);

        end            
    end

    %% create work folder if needed
    function this = workdir(this)

        if this.outf == -1                              % set default unless specified otherwise
            this.work_dir = [Supp_gz_fileparts(this.fod) filesep 'SAF_output'];
        else                                            % ensure full path
            if strcmp(Supp_gz_fileparts(this.outf), '')
                this.work_dir = [Supp_gz_fileparts(this.fod) filesep this.outf];
            else
                this.work_dir = this.outf;
            end
        end 

        if ~exist(this.work_dir, 'dir')                 % create the folder if it doesn't exist
            mkdir(this.work_dir);            
        end

        cd(this.work_dir);                              % open the folder

    end

    %% initiate log    

    function this = start_log(this)

        if isempty(this.fa)
            fa = 'not provided';
        else
            fa = this.fa;
        end

        this.logt = { ...
            'Log for SAF_pipeline.m run on:' datestr(datetime('now')); ...
            'Version:' this.version; ...
            '' ''; ...
            'FreeSurfer directory:' this.fs_dir; ...
            'FOD file:' this.fod; ...
            'FA file:' fa; ...
            'Output directory:' this.work_dir; ...
            '' ''};

        if this.noregister
            this.logt(end+1,:) = {'Registration:' 'already co-aligned'};
        else
            this.logt(end+1,:) = {'Registration:' this.registration};
        end

        if isempty(this.noseed)
            this.logt(end+1:end+3,:) = { ...
                'Seed from surface mesh vertices for tractography:' this.surfseed; ...
                'Surface label for seeding:' this.slab; ...
                'Additional tckgen options:' this.tckgen};
        else
            this.logt(end+1,:) = {'Tractography file:' this.noseed};
        end

        if isempty(this.sl_weights)
            this.logt(end+1,:) = {'Streamline weights:' 'not provided'};
        else
            this.logt(end+1,:) = {'Streamline weights:' this.sl_weights};
        end

        this.logt(end+1:end+10,:) = { ...
            'MRtrix command prefix: ' this.mrtrix_prefix; ...
			'Fast mesh-streamline intersection detection: ' this.fastx; ...
            'Extra margin during GG: ' this.gg_margin; ...
            'Hard 2-point intersection during GWG:' this.gwg_hard; ...
            'Do not truncate streamline at the WSM:' this.notrunc; ...
            'Apply pial filtering:' this.pialfilter; ...            
            'Diagnostics:' this.dgn; ...
            'Force overwrite:' this.force; ...
            'Quiet:' this.quiet; ...
            '' ''};

        if isempty(this.scalar2surf)
            this.logt(end+1,:) = {'Scalars provided for projection on the surface:' 'none'};
        else
            this.logt(end+1,:) = {'Scalars provided for projection on the surface:' strjoin(this.scalar2surf, ', ')};
        end

        if isempty(this.optmodules)
            this.logt(end+1,:) = {'Optional modules:' 'none'};
        else
            this.logt(end+1,:) = {'Optional modules:' strjoin(this.optmodules, ', ')};
        end

        this.logt(end+1, :) = {'' ''};

    end

    %% ensure fs_dir is not in fact a file (in which case run recon-all)       
    function this = sortFS(this)

        def_dir = [Supp_gz_fileparts(this.fod) filesep 'FS_reconall'];

        if ~exist(this.fs_dir) && ~exist(def_dir, 'dir')

            error('fs_dir not provided correctly')

        elseif ~exist(this.fs_dir)

            warning(['fs_dir not provided correctly but a default freesurfer directory found. Use the default directory? ' def_dir])
            if strcmp(input('y/n? ', 's'), 'y')
                this.fs_dir = def_dir;
            else
                error('fs_dir not provided correctly')
            end                

        elseif ~isdir(this.fs_dir) && exist(def_dir, 'dir')

            warning('fs_dir points to a file but a default freesurfer directory found. Use the default directory instead of re-running recon-all? ')
            if strcmp(input('y/n? ', 's'), 'y')
                this.fs_dir = def_dir;
            else
                verb_msg(['Running Freesurfer recon-all on ' this.fs_dir '... will take a while ;)'], this)
                sys_exec(['recon-all -subject FS_reconall -sd ' Supp_gz_fileparts(this.fod) filesep ' -i ' this.fs_dir ' -all'], this);
                this.fs_dir = def_dir;
            end   

        elseif isdir(this.fs_dir) && exist(def_dir, 'dir')

            warning('A default freesurfer directory was found but fs_dir points to a different directory. Using the provided directory')
            this.fs_dir = make_full_path(this.fs_dir);

        elseif ~isdir(this.fs_dir) && ~exist(def_dir, 'dir')

            verb_msg(['Running Freesurfer recon-all on ' this.fs_dir '... will take a while ;)'], this)
            sys_exec(['recon-all -subject FS_reconall -sd ' Supp_gz_fileparts(this.fod) filesep ' -i ' this.fs_dir ' -all'], this);
            this.fs_dir = def_dir;

        end
    end
end    
end

