%% MODEL INSTANTIATION
dudc = duc_ddc_compiler_v1_0_bitacc;

%% CORE CONFIGURATION
% See C header file for list of parameters to set
config = get_configuration(dudc);   % get default config

config.core_type       = 0;   % DUC
config.ch_bandwidth    = 10;
config.n_carriers      = 2;
config.if_passband     = 20;
config.digital_if      = 0;
config.rf_rate         = 122.88 * 1e6;
config.clock_rate      = config.rf_rate * 3;
config.din_width       = 16;
config.dout_width      = 17;
FCarriers              = [ -5000000 +5000000 ];

%% MODEL CREATION
[dudc] = create(dudc,config);

%% CARRIER SETUP
if config.n_carriers>1
  for ccc = 1:length(FCarriers)
    carr = get_carrier(dudc,ccc-1);
    carr.f = FCarriers(ccc);
    set_carrier(dudc,ccc-1,carr);
  end
end

%% Create test data
clear x
for carr = 1:config.n_carriers
  scale  = (2^(config.din_width-1)-1)/2^(config.din_width-1);
  x_real = scale*(-1+2*rand(100,1));
  x_imag = scale*(-1+2*rand(100,1));
  x_real = round(x_real*2^(config.din_width-1))/2^(config.din_width-1);
  x_imag = round(x_imag*2^(config.din_width-1))/2^(config.din_width-1);
  x(:,carr) = x_real + j*x_imag;
end

% Prep 3-D input array to C model
% Normally 3-D array but could be 2-D array if only single carrier, due to MEX array handling
clear xx
if config.n_carriers>1
  xx = zeros( size(x,1), 1, size(x,2) );
  for carr = 1:size(x,2)
    xx(:,1,carr) = x(:,carr);
  end
  figure; plot(real(xx(:,1,1)));
else
  xx = x;
  figure; plot(real(xx(:,1)));
end
  

% Simulation 
[dudc, out] = simulate(dudc, 'din', xx);
y = out.dout; clear out

% Extract wanted signal from C model output array
% Normally 3-D array but could be 2-D array if only single carrier, due to MEX array handling
if size(size(y),2)==3
  for carr = 1:size(y,3)
    yy(:,carr) = y(:,1,carr);
  end
else
  yy = y;
end

% Plot the output for the first carrier and antenna only
figure; plot(real(yy(:,1,1)));

%% MODEL DESTRUCTION
[dudc] = destroy(dudc);

