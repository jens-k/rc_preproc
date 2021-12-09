function [s, n, rec] = idparts(id)
% Takes a recording ID file name and gives back the subject, night, and
% recording IDs. This is done with regular expressions. Not sure if this is
% better than just looking for the '_' characters, but its cooler for sure.
%
% s12_n2_rs3_23-42Hz.mat -> s12 2 rs3
% Note: Then first and third output will be strings while the second one
% will be a number.
%
% This is not the most stable function and should be tested for every new
% recording id and type of input
%
% AUTHOR:
% Jens Klinzing, jens.klinzing@uni-tuebingen.de
%
% TODO: Build in more double-checks to make the function more reliable
if ~ischar(id), error('Wrong input.'), end

[~, id, ~] = fileparts(id);

disp(['Extracting ID parts from string ''' id ''':'])
s_start     = 1;
s_end       = regexp(id, '(?<=s\d*)_(?=n)')-1;
s = id(s_start:s_end);

n_start     = s_end+2;
if length(id) > n_start
	n_end			= n_start + regexp(id(n_start:end), '(?<=n)\d(?=$|_|.)')-1;
	n				= id(n_start:n_end);
	n				= str2double(n(2:end));

	rec_start		= n_end+2;
	if length(id) > rec_start
		rec_end		= rec_start + regexp(id(rec_start:end), '$|_|\.')-2;
		if isempty(rec_end) %|| rec_end(1)-rec_start == 1
			rec 	= [];
		else
			rec     = id(rec_start:rec_end);
		end
	else
		rec			= [];
	end
else
	n				= [];
	rec				= [];
end
disp([s ', ' num2str(n) ', ' rec])

