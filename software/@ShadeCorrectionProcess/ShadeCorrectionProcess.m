classdef ShadeCorrectionProcess < ImageCorrectionProcess
    
    %A class for performing shade correction (illumination non-uniformity
    %correction) on images.
    %
    %Hunter Elliott, 5/2010
    %
%
% Copyright (C) 2020, Danuser Lab - UTSouthwestern 
%
% This file is part of BiosensorsPackage.
% 
% BiosensorsPackage is free software: you can redistribute it and/or modify
% it under the terms of the GNU General Public License as published by
% the Free Software Foundation, either version 3 of the License, or
% (at your option) any later version.
% 
% BiosensorsPackage is distributed in the hope that it will be useful,
% but WITHOUT ANY WARRANTY; without even the implied warranty of
% MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
% GNU General Public License for more details.
% 
% You should have received a copy of the GNU General Public License
% along with BiosensorsPackage.  If not, see <http://www.gnu.org/licenses/>.
% 
% 
    
    methods (Access = public)
        
        function obj = ShadeCorrectionProcess(owner,outputDir,funParams,shadeImagePaths,...
                inImagePaths,outImagePaths)
            if nargin == 0
                super_args = {};
            else
                nChan = numel(owner.channels_);
                
                super_args{1} = owner;
                super_args{2} = ShadeCorrectionProcess.getName;
                super_args{3} = @shadeCorrectMovie;
                
                if nargin < 3 || isempty(funParams)
                    if nargin <2, outputDir = owner.outputDirectory_; end
                    funParams=ShadeCorrectionProcess.getDefaultParams(owner,outputDir);
                end
                
                super_args{4} = funParams;
                
                if nargin > 3
                    %Set the correction image paths to the shadeImage paths
                    %input.
                    super_args{7} = shadeImagePaths;
                end
                
                if nargin > 4
                    super_args{5} = inImagePaths;
                end
                
                if nargin > 5
                    super_args{6} = outImagePaths;
                end
                
            end
            
            obj = obj@ImageCorrectionProcess(super_args{:});
        end
        
        function sanityCheck(obj)
            sanityCheck@ImageCorrectionProcess(obj)
            % Sanity check will check the correction images
            for i = obj.funParams_.ChannelIndex
                if ~isempty(obj.inFilePaths_{2,i})
                    
                    if ~exist(obj.inFilePaths_{2,i}, 'dir')
                        error('lccb:set:fatal', ...
                            ['The specified shade image channel:\n\n ',obj.inFilePaths_{2,i}, ...
                            '\n\ndoes not exist. Please double check your channel path.'])
                    end
                    fileNames = imDir(obj.inFilePaths_{2,i},true);
                    
                    if isempty(fileNames)
                        error('lccb:set:fatal', ...
                            ['No proper image files are detected in:\n\n ',obj.inFilePaths_{2,i}, ...
                            '\n\nPlease double check your channel path.'])
                    end
                    
                    
                    for j = 1:length(fileNames)
                        imInfo = imfinfo([obj.inFilePaths_{2,i} filesep fileNames(j).name]);
                        if imInfo.Width ~= obj.owner_.imSize_(2) || imInfo.Height ~= obj.owner_.imSize_(1)
                            error('lccb:set:fatal', ...
                                ['Shade correction image - \n\n',...
                                obj.inFilePaths_{2,i},filesep,fileNames(j).name,...
                                '\n\nmust have the same size as input images. Please double check your correction image data.'])
                        end
                    end
                end
            end
        end
        
    end
    methods(Static)
        function name =getName()
            name = 'Shade Correction';
        end
        function h = GUI()
            h= @shadeCorrectionProcessGUI;
        end
        function funParams = getDefaultParams(owner,varargin)
            % Input check
            ip=inputParser;
            ip.addRequired('owner',@(x) isa(x,'MovieData'));
            ip.addOptional('outputDir',owner.outputDirectory_,@ischar);
            ip.parse(owner, varargin{:})
            outputDir=ip.Results.outputDir;
            
            % Set default parameters
            funParams.OutputDirectory = [outputDir  filesep 'shade_corrected_images'];
            funParams.ShadeImageDirectories = []; %No default for this! It will be handled differently...
            funParams.ChannelIndex = 1:numel(owner.channels_);
            funParams.MedianFilter = true;
            funParams.GaussFilterSigma = 0;
            funParams.Normalize = 1;
            funParams.BatchMode = false;
        end
    end
end