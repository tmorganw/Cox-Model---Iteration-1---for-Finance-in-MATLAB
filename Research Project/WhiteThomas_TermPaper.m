clearvars; close all; clc

%% Introduction

%Purpose:
    %ECON 525 - Spring 2020 -> Final Project: Predict trend-lengths and end-of-trend probability in the foreign exhange market.

%Note:
    %This m-file is dependent upon the following attached files:
        %'Currency Rates.xlsx'
        %'Federal Funds Rate.csv'
        %'Rate Volatility.csv'

%Author:
    %Thomas Morgan White - April 27, 2020
    %U.N.C. Honor Pledge: I certify that no unauthorized assistance has been received or given in the completion of this work.

%% Load and Clean the Data.

% Load the data into the environment.
CurrencyData = readtable('Currency Rates.xlsx', 'Sheet', 'px_close');
InterestRateData = readtable('Federal Funds Rate.csv');
RateVolatilityData = readtable('Rate Volatility.csv');

% Shrink to five most traded currencies except USD, since these are all USD cross-rates.
CurrencyData = CurrencyData(:, {'Date', 'EUR', 'JPY', 'GBP', 'AUD', 'CAD'});

% Fix dates.

% Obtain date arrays for each dataset.
CurrencyDates = datenum(table2array(CurrencyData(:, 1)));
RateDates = datenum(table2array(InterestRateData(:, 1)));
VolDates = datenum(table2array(RateVolatilityData(:, 1)));

% Figure out where they all align.
ComboDates = CurrencyDates(ismember(CurrencyDates, RateDates), 1);
Dates = ComboDates(ismember(ComboDates, VolDates), :);


% Create a variable for currencies.
Currencies = CurrencyData.Properties.VariableNames(2:end);

% Parse all of the data to ensure dates align, and create a dates variable.
CurrencyData = table2array(CurrencyData(find(Dates), 2:6));
InterestRateData = table2array(InterestRateData(find(Dates), 2));
RateVolatilityData = table2array(RateVolatilityData(find(Dates), 5)); %#ok<*FNDSB>

% Combine into a large dataset to remove NaN's.

% Combine.
BigData = [Dates, CurrencyData, InterestRateData, RateVolatilityData];

% Remove the NaN's.
BigData(~any(~isnan(BigData), 2), :) = [];

% Break the Data Back Apart
Dates = BigData(:, 1);
DateStrings = cellstr(datestr(Dates));
CurrencyData = BigData(:, 2:6);
InterestRateData = BigData(:, 7);
RateVolatilityData = BigData(:, 8);


%% Find Trends and Conduct Other Preliminary Analysis.

% Make line graphs for each currency to identify trends.
for i = 1:size(CurrencyData, 2)
    figure(i);
    plot(CurrencyData(:, i));
    set(gca, 'XtickLabel', DateStrings(1:856:end));
    title(Currencies(i))
end
clear i

% Plot the effective federal funds rate data overlayed with the currencies.

% Plot the federal funds rate data with dates and a title.
figure;
plot(InterestRateData);
set(gca, 'XtickLabel', DateStrings(1:1070:end));
title('Effective Federal Funds Rate and Currency Cross Rates');

% Overlay the currency data, and add a legend.
hold on
for i = 1:size(CurrencyData, 2)
    plot(CurrencyData(:, i));
end
legend({'EFFR', 'EUR', 'JPY', 'GBP', 'AUD', 'CAD'}, 'Location', 'southeast')
clear i
hold off


% Plot the interest rate volatility data overlayed with the currencies.

% Plot the interest rate volatility data with dates and a title.
figure;
plot(RateVolatilityData);
set(gca, 'XtickLabel', DateStrings(1:1070:end));
title('Treasury Note Volatility and Currency Cross Rates');

%overlay the currency data, and add a legend.
hold on
for i = 1:size(CurrencyData, 2)
    plot(CurrencyData(:, i));
end
legend({'Note Volatility', 'EUR', 'JPY', 'GBP', 'AUD', 'CAD'}, ...
    'Location', 'east')
clear i
hold off


%% Find Their Indices, and Their Lengths.

% List out the start datenums for those currency trends.
TrendEUR = [731600; 732000; 732200; 732600; 733200; 733700; 735700; 737300; 737600];
TrendJPY = [731600; 731700; 731900; 732100; 733600; 734900; 735400; 736200; 737300];
TrendGBP = [731600; 732000; 732200; 732600; 732800; 734300; 735900; 737300; 737600];
TrendAUD = [731600; 731800; 733000; 734200; 734900; 735100; 735900; 736900; 737100];
TrendCAD = [731600; 732300; 733500; 733800; 734900; 735400; 736200; 736900; 737000];

% Create indexing for trend start dates, and ensure that they are correct.
idxEUR = find(ismember(Dates, TrendEUR));
idxJPY = find(ismember(Dates, TrendJPY));
idxGBP = find(ismember(Dates, TrendGBP));
idxAUD = find(ismember(Dates, TrendAUD));
idxCAD = find(ismember(Dates, TrendCAD));

% Find trend lengths for each currency in number of days.
YEUR = [diff(idxEUR); (737800 - TrendEUR(end))];
YJPY = [diff(idxJPY); (737800 - TrendJPY(end))];
YGBP = [diff(idxGBP); (737800 - TrendGBP(end))];
YAUD = [diff(idxAUD); (737800 - TrendAUD(end))];
YCAD = [diff(idxCAD); (737800 - TrendCAD(end))];

%% Index to the Dates.

% EUR indexing.
X1EUR = InterestRateData(idxEUR);
X2EUR = RateVolatilityData(idxEUR);

% JPY indexing.
X1JPY = InterestRateData(idxJPY);
X2JPY = RateVolatilityData(idxJPY);

% GBP indexing.
X1GBP = InterestRateData(idxGBP);
X2GBP = RateVolatilityData(idxGBP);

% AUD indexing.
X1AUD = InterestRateData(idxAUD);
X2AUD = RateVolatilityData(idxAUD);

% CAD indexing.
X1CAD = InterestRateData(idxCAD);
X2CAD = RateVolatilityData(idxCAD);


%% Run the Test.

% Run the hazard model, and produce relevant statistics.

% Output for EUR.
[bEUR1, loglEUR1, HEUR1, statsEUR1] = coxphfit(X1EUR, YEUR);
[bEUR2, loglEUR2, HEUR2, statsEUR2] = coxphfit(X2EUR, YEUR);

% Output for JPY.
[bJPY1, loglJPY1, HJPY1, statsJPY1] = coxphfit(X1JPY, YJPY);
[bJPY2, loglJPY2, HJPY2, statsJPY2] = coxphfit(X2JPY, YJPY);

% Output for GBP.
[bGBP1, loglGBP1, HGBP1, statsGBP1] = coxphfit(X1GBP, YGBP);
[bGBP2, loglGBP2, HGBP2, statsGBP2] = coxphfit(X2GBP, YGBP);

% Output for AUD.
[bAUD1, loglAUD1, HAUD1, statsAUD1] = coxphfit(X1AUD, YAUD);
[bAUD2, loglAUD2, HAUD2, statsAUD2] = coxphfit(X2AUD, YAUD);

% Output for CAD.
[bCAD1, loglCAD1, HCAD1, statsCAD1] = coxphfit(X1CAD, YCAD);
[bCAD2, loglCAD2, HCAD2, statsCAD2] = coxphfit(X2CAD, YCAD);


%% Present Findings.

% Build an array of result descriptors.
ResultsDescription = {'Interest Rates: EUR'; 'Interest Rates: JPY'; ...
    'Interest Rates: GBP'; 'Interest Rates: AUD'; ...
    'Interest Rates: CAD'; 'Rate Volatility: EUR'; ...
    'Rate Volatility: JPY'; 'Rate Volatility: GBP'; ...
    'Rate Volatility: AUD'; 'Rate Volatility: CAD'};

% Build an array of the beta coefficients.
ResultsBeta = [bEUR1; bJPY1; bGBP1; bAUD1; bCAD1; bEUR2; bJPY2; bGBP2; ...
    bAUD2; bCAD2];

% Build an array of the p-values.
ResultsP = [statsEUR1.p; statsJPY1.p; statsGBP1.p; statsAUD1.p; ...
    statsCAD1.p; statsEUR2.p; statsJPY2.p; statsGBP2.p; statsAUD2.p; ...
    statsCAD2.p];

% Build an array of the log likelihood values.
ResultsLL = [loglEUR1; loglJPY1; loglGBP1; loglAUD1; loglCAD1; ...
    loglEUR2; loglJPY2; loglGBP2; loglAUD2; loglCAD2];

% Put it all together.
ResultsTable = array2table([ResultsBeta, ResultsP, ResultsLL]);
ResultsTable.Properties.VariableNames = {'Beta Coefficient', 'P-Value', ...
    'Log Likelihood Value'};
ResultsTable.Properties.RowNames = ResultsDescription;
disp(ResultsTable);

