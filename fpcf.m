classdef fpcf < handle
    %FPCF Four Point Correlation Function
    %   read 4pcf
    %   usage:
    %       a = fpcf(test_dir);
    %       a.parse_log(log_fn);
    %       a.read_chi4;
    %       a.read_g4ol;
    %       a.read_s4;
    %       a.read_q;
    
    properties
        output_dir = [];
        log_file = 'log_test.out';
        s4_fn = {};
        g4ol_fn = {};
        output_prefix = '';
        output_deltat = [];
        output_len = [];
        rho = [];
        boxsize = [];
        temperature = [];
        
        g4ol = []; % (r, t)
        g4ol_t = [];
        g4ol_r = [];
        s4 = [];
        s4_q = [];
        s4_t = [];
        q1 = [];
        q2 = [];
        chi4 = [];
    end
    
    methods
        function obj = fpcf(output_dir)
            %FPCF Construct an instance of this class
            %   Detailed explanation goes here
            obj.output_dir = output_dir;
        end
        
        function parse_log(obj, log_fn)
            %parse_log read var from log
            if exist('log_fn', 'var') && ~isempty(log_fn)
                obj.log_file = log_fn;
            end
            
            fn = [obj.output_dir,filesep,obj.log_file];
            fid = fopen(fn);
            
            if fid < 0
                error(['Failed to open log file: ', fn])
            end
            
            obj.output_deltat = fpcf.log_read_var(fid, 'output_deltat');
            obj.output_len = fpcf.log_read_var(fid, 'output_len');
            obj.boxsize = fpcf.log_read_var(fid, 'box');
            
            obj.rho = fpcf.log_read_var(fid, 'Density rho of group2');
            obj.temperature = fpcf.log_read_var(fid, 'temperature');
            if obj.temperature <= 0
                obj.temperature = [];
            end
            obj.output_prefix = fpcf.log_read_var(fid, 'output_prefix', 'string');
            
            obj.s4_fn = obj.log_read_filelist(fid, ...
                ' S4_DIRECT filenames:', ...
                ' S4_DIRECT END filenames');
            
            % generate g4ol filename
            % trim(adjustl(output_prefix))//'_g4ol' '_iframe=', trim(adjustl(iframe_str)), '.out'
            % C0R-C0R_g4ol_iframe=1.out
            g4ol_fn_prefix = [obj.output_prefix, '_g4ol', '_iframe='];
            g4ol_fn_suffix = '.out';
            obj.g4ol_t = [];
            obj.g4ol_fn = {};
            for i = 1:max(1, floor(obj.output_len/100)):obj.output_len
                obj.g4ol_t(end+1) = i*obj.output_deltat;
                obj.g4ol_fn{end+1} = [g4ol_fn_prefix, num2str(i), g4ol_fn_suffix];
            end
            
            fclose(fid);
        end
        
        function read_g4ol(obj)
            [obj.g4ol, obj.g4ol_r] = obj.read_files(obj.output_dir, obj.g4ol_fn, '%20.10f%20.10f');
        end
        
        function read_s4(obj)
            % generate s4_t
            % C0R-C0R_s4_direct_fine_t=1176.0000.out
            obj.s4_t = cellfun(@(x)(sscanf(x,[obj.output_prefix,'_s4_direct_fine_t=%f.out'])), obj.s4_fn);
            [obj.s4, obj.s4_q] = obj.read_files(obj.output_dir, obj.s4_fn, '%f %f %f');
        end
        
        function read_chi4(obj)
            chi4_fn = [obj.output_dir, filesep, obj.output_prefix, '_chi4.out'];
            obj.chi4 = obj.read_data_column(chi4_fn);
        end
        
        function read_q(obj)
            % C0R-C0RQ1.out
            q1_fn = [obj.output_dir, filesep, obj.output_prefix, 'Q1.out'];
            q2_fn = [obj.output_dir, filesep, obj.output_prefix, 'Q2.out'];
            obj.q1 = obj.read_data_column(q1_fn);
            obj.q2 = obj.read_data_column(q2_fn);
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
                            error('unknown var_type')
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
                        fnlist{tmp{1}} = tmp{2}{1};
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
                tmp = fpcf.read_data_column( ...
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
    end % methods(static)
end

