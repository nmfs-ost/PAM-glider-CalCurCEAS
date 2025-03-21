% WORKFLOW_DOWNLOADSCRIPT_SG680.M
%	Download basestation files and generate piloting/monitoring plots
%      ** SG680_CalCurCEAS_Sep2024 **
%
%	Description:
%		This script provides a workflow that may be useful during an active
%		mission to assist with piloting. The idea is that the entire script
%		can be run after a glider surfacing to automate the process of
%		checking on the glider status
%
%       It has the following sections:
%       (1) any new basestation files to the local computer, including .nc,
%       .log, .dat, cmdfiles, pdos any acoustic .eng or detection files
%       (2) extracts useful data from local basestation .nc and .log files
%       and compiles into a summary table, variable 'pp', and saves to a
%       .xlsx and .mat
%       (3) generates several piloting monitoring plots and saves as .pngs
%       (4) prints out calculated mission speeds and estimates of total
%       duration
%
%       It requires an agate configuration file during agate initialization
%
%	Notes
%
%	See also
%
%
%	Authors:
%		S. Fregosi <selene.fregosi@gmail.com> <https://github.com/sfregosi>
%	Created with MATLAB ver.: 9.13.0.2166757 (R2022b) Update 4
%
%	FirstVersion: 	01 June 2023
%	Updated:        13 September 2024
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% add agate to the path
addpath(genpath('C:\Users\Selene.Fregosi\Documents\MATLAB\agate'))

% initialize agate
cnfFile = ['C:\Users\Selene.Fregosi\Documents\GitHub\glider-CalCurCEAS\' ...
	'MATLAB\fregosi_config_files\agate_config_sg680_CalCurCEAS_Sep2024.cnf'];
CONFIG = agate(cnfFile);

% specify the local piloting folder for this trip in CONFIG.path.mission
% set up nested folders for basestation files and piloting outputs
path_status = fullfile(CONFIG.path.mission, 'flightStatus'); % where to store output plots/tables
% path_bsLocal = fullfile(CONFIG.path.mission, 'basestationFiles'); % local copy of basestation files

% make the dirs if they don't exist
mkdir(path_status);
mkdir(CONFIG.path.bsLocal);

%% (1) download files from the basestation
downloadBasestationFiles(CONFIG);

% various status pieces will print in Command Window

%% (2) extract piloting parameters

% create piloting parameters (pp) table from downloaded basestation files
pp = extractPilotingParams(CONFIG, fullfile(CONFIG.path.mission, 'basestationFiles'), ...
	fullfile(CONFIG.path.mission, 'flightStatus'), 1);
% change last argument from 0 to 1 to load existing data and append new dives/rows

% save it to the default location as .mat and .xlsx
save(fullfile(CONFIG.path.mission, 'flightStatus', ['diveTracking_' ...
	CONFIG.glider '.mat']), 'pp');
writetable(pp, fullfile(path_status, ['diveTracking_' CONFIG.glider '.xlsx']));

%% (3) generate and save plots

% print map **SLOWISH** - figNumList(1)
% loaded targets file (interpolated waypoints)
targetsLoaded = fullfile(CONFIG.path.mission, 'targets');
% simple targets file (waypoints only at 'turns')
targetsSimple = fullfile(CONFIG.path.mission, 'targets_B_Nearshore_2024-09-14');
plotGliderPath_etopo(CONFIG, pp, targetsSimple, CONFIG.map.bathyFile);

% add newport label
scatterm(44.64, -124.05, 200, 'white', 'p', 'filled', 'MarkerEdgeColor', 'black');
textm(44.48, -124.05, 'Newport, OR', 'FontSize', 10, 'Color', 'white');
% add Eureka label
scatterm(40.8, -124.16, 300, 'white', 'p', 'filled', 'MarkerEdgeColor', 'black');
textm(40.8, -124.02, 'Eureka, CA', 'FontSize', 10, 'Color', 'white');

% save it as a .fig (for zooming)
savefig(fullfile(path_status, [CONFIG.glider '_map.fig']))
% and as a .png (for quick/easy view)
exportgraphics(gca, fullfile(path_status, [CONFIG.glider '_map.png']), ...
    'Resolution', 300)

% % humidity and pressure - figNumList(2)
% plotHumidityPressure(CONFIG, pp)
% print(fullfile(path_status, [CONFIG.glider  '_humidityPressure.png']), '-dpng')
% 
% % battery usage/free space - figNumList(3)
% plotBattUseFreeSpace(CONFIG, pp, 310)
% print(fullfile(path_status, [CONFIG.glider '_battUseFreeSpace.png']), '-dpng')
% 
% % voltage pack use (power draw by device) - figNumList(4)
% plotVoltagePackUse(CONFIG, pp)
% print(fullfile(path_status, [CONFIG.glider '_usageByDevice.png']), '-dpng')
% 
% % voltage pack use (power draw by device, normalized by dive duration) - figNumList(5)
% plotVoltagePackUse_norm(CONFIG, pp)
% print(fullfile(path_status, [CONFIG.glider '_usageByDevice_normalized.png']), '-dpng')
% 
% % minimum reported voltages - figNumList(6)
% plotMinVolt(CONFIG, pp)
% print(fullfile(path_status, [CONFIG.glider '_minimumVoltage.png']), '-dpng')
% % close
% 
% % PMAR space used per minute and over time (IF PMAR IS ACTIVE)
% plotPmUsed(CONFIG, pp) 
% 
% % ERMA detection events from the most recent dive (IF WISPR/ERMA IS ACTIVE)
% plotErmaDetections(CONFIG, path_bsLocal, pp.diveNum(end))

%% (4) print mission summary

% print errors reported on most recent dive
printErrors(CONFIG, size(pp,1), pp)

% print avg speed and rough estimate of total mission duration
tm = printTravelMetrics(CONFIG, pp, fullfile(CONFIG.path.mission, 'targets'), 1);

% specify planned recovery date and time
recovery = '2024-10-25 09:00:00';
recTZ = 'America/Los_Angeles';
tm = printRecoveryMetrics(CONFIG, pp, fullfile(CONFIG.path.mission, 'targets'), ...
recovery, recTZ, 1);

