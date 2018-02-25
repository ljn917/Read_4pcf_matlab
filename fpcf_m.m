classdef fpcf_m < handle
    %FPCF_M Four Point Correlation Function Mobile
    %   read 4pcf
    %   usage:
    %       a = fpcf_m(test_dir);
    %       a.parse_log(log_fn);
    %       a.read_chi4;
    %       a.read_g4ol;
    %       a.read_s4;
    %       a.read_q;
    
    properties
        output_dir = [];
        log_file = 'log_test.out';
%         s4_fn = {};
        g4ol_fn = [];
        g4ol_bin_fn = [];
        g4ol_r12_t_fn = [];
        g4ol_rcom_t_fn = [];
        output_prefix = '';
        output_deltat = [];
        output_len = [];
        rho = [];
        boxsize = [];
        volume = []
        temperature = [];
        N1 = [];
        N2 = [];
        
        distr_func_3d = [];
        g4ol = []; % (r, t)
        g4ol_t = [];
        g4ol_r12 = [];
        g4ol_rcom = [];
        
        g4ol_r12_t_data = [];
        g4ol_r12_t_data_t = [];
        g4ol_r12_t_data_r12 = [];
        
        g4ol_rcom_t_data = [];
        g4ol_rcom_t_data_t = [];
        g4ol_rcom_t_data_rcom = [];
        
%         s4 = [];
%         s4_q = [];
%         s4_t = [];
%         q1 = [];
%         q2 = [];
%         chi4 = [];
    end
    
    methods
        % output_dir is a char or saved struct
        function obj = fpcf_m(output_dir, log_fn)
            %FPCF_M Construct an instance of this class
            %   Detailed explanation goes here
            
            % default constructor
            if nargin == 0
                return
            end
            
            if ischar(output_dir) || isstring(output_dir)
                obj.output_dir = char(output_dir);
            else
                error('fpcf_m: constructor: unknown arg')
            end
            
            if exist('log_fn', 'var') && ~isempty(log_fn)
                obj.log_file = char(log_fn);
            end
            
            if nargin == 2
                obj.read_all;
            end
        end
        
        function read_all(obj)
            obj.parse_log;
            %obj.read_chi4;
            %obj.read_g4ol;
            obj.read_g4ol_bin;
            obj.read_g4ol_r12;
            obj.read_g4ol_rcom;
            %obj.read_s4;
            %obj.read_q;
        end
        
        function parse_log(obj, log_fn)
            %parse_log read var from log
            if exist('log_fn', 'var') && ~isempty(log_fn)
                obj.log_file = char(log_fn);
            end
            
            fn = [obj.output_dir,filesep,obj.log_file];
            fid = fopen(fn);
            
            if fid < 0
                error(['Failed to open log file: ', fn])
            end
            
            sampling_per_point = fpcf_m.log_read_var(fid, 'est sampling/point');
            if sampling_per_point < 2000
                disp(['WARNING: sampling_per_point is too few, ', ...
                    'sampling_per_point=', num2str(sampling_per_point)])
            end
            
            obj.output_deltat = fpcf_m.log_read_var(fid, 'output_deltat');
            obj.output_len = fpcf_m.log_read_var(fid, 'output_len');
            obj.boxsize = fpcf_m.log_read_var(fid, 'box', '%f %f %f %f %f %f %f %f %f');
            obj.boxsize = reshape(obj.boxsize, 3, 3);
            obj.volume = det(obj.boxsize);
            
            obj.rho = fpcf_m.log_read_var(fid, 'Density rho of group1');
            obj.temperature = fpcf_m.log_read_var(fid, 'temperature');
            if obj.temperature <= 0
                obj.temperature = [];
            end
            obj.output_prefix = fpcf_m.log_read_var(fid, 'output_prefix', 'string');
            
            obj.N1 = fpcf_m.log_read_var(fid, 'size of group1_index');
            obj.N2 = fpcf_m.log_read_var(fid, 'size of group2_index');
            
%             obj.s4_fn = obj.log_read_filelist(fid, ...
%                 ' S4_DIRECT filenames:', ...
%                 ' S4_DIRECT END filenames');
%             obj.s4_fn = obj.log_read_filelist(fid, ...
%                 ' S4 filenames:', ...
%                 ' S4 END filenames');
            
            obj.g4ol_fn = fpcf_m.log_read_var(fid, 'g4ol_filename', 'string');
            obj.g4ol_bin_fn = fpcf_m.log_read_var(fid, 'g4ol_binary_filename', 'string');
            obj.g4ol_r12_t_fn = fpcf_m.log_read_var(fid, 'g4ol_r12_t_filename', 'string');
            obj.g4ol_rcom_t_fn = fpcf_m.log_read_var(fid, 'g4ol_r_com_t_filename', 'string');
            
            fclose(fid);
        end
        
        function read_g4ol(obj)
            error('not implemented')
            %[obj.g4ol, obj.g4ol_r] = obj.read_files(obj.output_dir, obj.g4ol_fn, '%20.10f%20.10f');
        end
        
        function read_g4ol_bin(obj)
            fn = [obj.output_dir,filesep,obj.g4ol_bin_fn];
            obj.distr_func_3d = fpcf_m.read_distr_func_3d_bin(fn);
            
            obj.g4ol = obj.distr_func_3d.g;
            obj.g4ol_r12    = obj.distr_func_3d.interval(1)*(obj.distr_func_3d.imin(1):obj.distr_func_3d.imax(1));
            obj.g4ol_rcom   = obj.distr_func_3d.interval(2)*(obj.distr_func_3d.imin(2):obj.distr_func_3d.imax(2));
            obj.g4ol_t      = obj.distr_func_3d.interval(3)*(obj.distr_func_3d.imin(3):obj.distr_func_3d.imax(3));
        end
        
        function read_g4ol_r12(obj)
            fn = [obj.output_dir,filesep,obj.g4ol_r12_t_fn];
            
            fmt = repmat('%f ', [1,obj.output_len+1]);
            tmp = obj.read_data_column(fn, fmt);
            obj.g4ol_r12_t_data = tmp(2:end, 2:end);
            obj.g4ol_r12_t_data_t = tmp(1, 2:end);
            obj.g4ol_r12_t_data_r12 = tmp(2:end, 1);
        end
        
        function read_g4ol_rcom(obj)
            fn = [obj.output_dir,filesep,obj.g4ol_rcom_t_fn];
            
            fmt = repmat('%f ', [1,obj.output_len+1]);
            tmp = obj.read_data_column(fn, fmt);
            obj.g4ol_rcom_t_data = tmp(2:end, 2:end);
            obj.g4ol_rcom_t_data_t = tmp(1, 2:end);
            obj.g4ol_rcom_t_data_rcom = tmp(2:end, 1);
        end
        
%         function read_s4(obj)
%             % generate s4_t
%             % C0R-C0R_s4_direct_fine_t=1176.0000.out
%             obj.s4_t = cellfun(@(x)(sscanf(x(strfind(x,'_t='):end),'_t=%f.out')), obj.s4_fn);
%             [obj.s4, obj.s4_q] = obj.read_files(obj.output_dir, obj.s4_fn, '%f %f %f');
%         end
%         
%         function read_chi4(obj)
%             chi4_fn = [obj.output_dir, filesep, obj.output_prefix, '_chi4.out'];
%             obj.chi4 = obj.read_data_column(chi4_fn);
%         end
%         
%         function read_q(obj)
%             % C0R-C0RQ1.out
%             q1_fn = [obj.output_dir, filesep, obj.output_prefix, 'Q1.out'];
%             q2_fn = [obj.output_dir, filesep, obj.output_prefix, 'Q2.out'];
%             obj.q1 = obj.read_data_column(q1_fn);
%             obj.q2 = obj.read_data_column(q2_fn);
%         end
        
        function g4ol2csv(obj, fn)
            validateattributes(fn, {'char', 'string'}, {'nonempty'}, 'fpcf_m.g4ol2csv', 'fn');
            
            if isempty(obj.g4ol)
                error('obj.g4ol is empty')
            end
            
            g4 = zeros(size(obj.g4ol) + 1);
            
            g4(2:end, 2:end) = obj.g4ol; % (r, t)
            g4(2:end, 1) = obj.g4ol_r;
            g4(1, 2:end) = obj.g4ol_t;
            g4(1, 1) = NaN;
            
            dlmwrite(fn, g4, 'delimiter', ',', 'precision','%20.10f','newline','pc');
        end
    end % methods
    
    methods(Static)
        % return val (double): [prefix] 'var_name' = val [suffix]
        % only first occurrence
        function val = log_read_var(fid, var_name, var_type)
            frewind(fid);
            while ~feof(fid)
                line = fgetl(fid);
                pos = strfind(line, var_name);
                if ~isempty(pos)
                    if length(pos) ~= 1
                        disp(var_name)
                        disp(line)
                        error('wrong log format')
                    end
                    if exist('var_type', 'var') && ~isempty(var_type)
                        if strcmpi(var_type, 'string')
                            val = sscanf(line(pos:end), [var_name, ' %*[=:] %s']);
                        else
                            val = sscanf(line(pos:end), [var_name, ' %*[=:] ', var_type]);
                        end
                    else
                        val = sscanf(line(pos:end), [var_name, ' %*[=:] %f']);
                    end
                    return
                end
            end
            
            % not found
            val = [];
            return
        end
        
        % read file list in format:
        % startline
        % n filename{n}
        % endline
        function fnlist = log_read_filelist(fid, startline, endline)
            fnlist = {};
            
            foundregion = false;
            
            frewind(fid);
            while ~feof(fid)
                line = fgetl(fid);
                if foundregion
                    if strcmpi(line, endline)
                        return
                    else
                        tmp = textscan(line, '%d %s');
                        fnlist{end+1} = tmp{2}{1};
                    end
                else
                    if strcmpi(line, startline)
                        foundregion = true;
                    end
                end
            end
        end
        
        function [res, comment] = read_data_column(filename, format)
            fid = fopen(filename);
            if fid < 0
                error(['Failed to open data file: ', filename])
            end
            
            if ~exist('format', 'var') || isempty(format)
                format = '%f %f';
            end
            
            comment = textscan(fid, '# %s');
            
            frewind(fid);
            res_cell = textscan(fid, format, 'CommentStyle', '#');
            res = cell2mat(res_cell);
            
            fclose(fid);
        end
        
        function [data, data_x] = read_files(filedir, filelist, format)
            if ~exist('format', 'var') || isempty(format)
                format = '%f %f';
            end
            
            data = [];
            data_x = [];
            for i = 1:length(filelist)
                tmp = fpcf_m.read_data_column( ...
                    [filedir, filesep, filelist{i}], ...
                    format);
                if isempty(data)
                    data = zeros(size(tmp, 1), length(filelist));
                end
                data(:, i) = tmp(:, 2);
                if isempty(data_x)
                    data_x = tmp(:, 1);
                end
            end
        end
        
        function res = read_distr_func_3d_bin(fn)
            %Ndim=3
            %type distr_func_3d_t
            %    real(kind=4), dimension(Ndim)                       ::  min, max, interval !1=x, 2=y, 3=z
            %    integer(kind=4), dimension(Ndim)                    ::  imin, imax !imin=min/interval, imax=max/interval
            %    integer(kind=8), dimension(:, :, :), allocatable    ::  g !g(imin:imax)
            %    integer(kind=8)                                     ::  total_point
            %end type
            % write(unit=unitid) df%min, df%max, df%interval, df%imin, df%imax, df%total_point, df%g
            
            res = struct;
            
            kind_real4 = 'real*4';
            kind_integer4 = 'integer*4';
            kind_integer8 = 'integer*8';
            Ndim = 3;
            
            fid = fopen(fn);
            
            res.min = fread(fid, Ndim, kind_real4);
            res.max = fread(fid, Ndim, kind_real4);
            res.interval = fread(fid, Ndim, kind_real4);
            
            res.imin = fread(fid, Ndim, kind_integer4);
            res.imax = fread(fid, Ndim, kind_integer4);
            
            res.total_point = fread(fid, 1, kind_integer8);
            
            size_g = transpose(res.imax-res.imin+1);
            len_g = prod(size_g);
            res.g = fread(fid, len_g, kind_integer8);
            res.g = reshape(res.g, size_g);
            
            fclose(fid);
        end
    end % methods(static)
end

