%% Task performance probability for whale blows imaged with IR camera
function [distance2whale,Pseq,RDR,MDR,FOVdegreeX] = IRwhaleDetect(Tb,visibility,f,fN,cameraElevation,cameraType,taskType)

% ==============================
% LICENSE INFO
% ==============================
%{
   Copyright 2025 The MITRE Corporation

   Licensed under the Apache License, Version 2.0 (the "License");
   you may not use this file except in compliance with the License.
   You may obtain a copy of the License at

     http://www.apache.org/licenses/LICENSE-2.0

   Unless required by applicable law or agreed to in writing, software
   distributed under the License is distributed on an "AS IS" BASIS,
   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
   See the License for the specific language governing permissions and
   limitations under the License.
%}

% ==============================
% Check user inputs and set default values if no input
% ==============================
if ~exist('Tb', 'var')
    Tb = 307.15; % temperature of background in K
end
if ~exist('visibility', 'var')
    visibility = 30; % visibility in kilometers
end
if ~exist('f', 'var')
    f = 100*10^-3; % focal length of lens in m
end
if ~exist('fN', 'var')
    fN = 1.6; % f-number of lens
end
if ~exist('cameraElevation', 'var')
    cameraElevation = 28.1; % camera height relative to sea level in meters
end
if ~exist('cameraType', 'var')
    cameraType = 1; % select sensor type from list. Default 1 - FLIR F-606 ID: Uncooled VOx Microbolometer 640x480 sensor with 17um pixel size
end
if ~exist('taskType', 'var')
    taskType = 0; % Task type. 0 for detection |  1 for identification 
end

% ==============================
% Load constants
% ==============================
[emis,~,hPlank,k,electron,c,Rearth] = loadConstants(); % load constants used in the model

% ==============================
% Setup task type for TTP metric
% ==============================
if taskType ==0 % DETECTION
    V50 = 2; % 2.0 is for detection, 7.5 is for recognition, and identification is 13.0
else % RECOGNITION
    V50 = 7.5; % 2.0 is for detection, 7.5 is for recognition, and identification is 13.0
end

% ==============================
% Whale blow parameters
% ==============================
T = 309.15; % temperature of whale blow
blowHeight = 2.84; % blow height in meters
blowRadius = 1.61; % blow radius in meters
blowType = 1; % blow geometry type: cone = 0 | ellipsoid = 1
eventDuration = 1.1; % duration of whale blow
whaleDensity = 6568; % density of whales over the sea surface to match experimental data
if blowType == 0
    CD = sqrt(blowHeight*blowRadius); % cone - characteristic dimension of whale blow in meters
else
    CD = sqrt(pi*blowHeight/2*blowRadius); % ellipsoid - characteristic dimension of whale blow in meters
end

% ==============================
% Target and background radiance
% ==============================
spectralSamples = 500; % number of samples for the spectrum used
lambdaArr = linspace(8*10^-6, 12*10^-6,spectralSamples); % wavelength of emission
Ep = hPlank*c./lambdaArr; % energy of a photon
L = emis*2*hPlank*c^2./lambdaArr.^5./(exp(hPlank*c./(k*T*lambdaArr))-1);   % radiance: units of W/(m2 * m * sr)
Lb = emis*2*hPlank*c^2./lambdaArr.^5./(exp(hPlank*c./(k*Tb*lambdaArr))-1);   % radiance: units of W/(m2 * m * sr)

% ==============================
% Atmospheric transmission parameters
% ==============================
attenuationCoefficient = -log(0.05)/(visibility*10^3); % attenuation coefficient in 1/m using Koschmieder’s Law
quantumEfficiency = ones(1,spectralSamples)*0.8; % quantum efficiency of sensor, can be function of wavelength
opticsTransmission = 0.8; % optical component transmission
effLambda = getLambda(L,lambdaArr,quantumEfficiency); % effective wavelength used in some calculations

% ==============================
% Optics specifications
% ==============================
Dp = f/fN; % diameter of pupil
Ap = pi*(Dp/2)^2; % area of the camera pupil

% ==============================
% Sensor type selection
% ==============================
switch cameraType
    case 1 % FLIR F-606 ID: Uncooled VOx Microbolometer 640x480 sensor with 17um pixel size
        pixelSize = 17*10^-6; % pixel size in m
        frameRate = 30; % frame rate of camera
        Ny = 480; % number of pixels in y direction
        Nx = 640;

        sensorY = pixelSize*Ny; % sensor size in y-direction
        sensorX = pixelSize*Nx; % sensor size in x-direction

        sensorType = 0; % 0 for uncooled | 1 for cooled
        downStreamNoise = 500; % electrons/pixel/frame

    case 2 % Cooled equivalent
        pixelSize = 17*10^-6; % pixel size in m
        frameRate = 30; % frame rate of camera
        Ny = 480; % number of pixels in y direction
        Nx = 640;

        sensorY = pixelSize*Ny; % sensor size in y-direction
        sensorX = pixelSize*Nx; % sensor size in x-direction

        sensorType = 1; % 0 for uncooled | 1 for cooled
        downStreamNoise = 50; % electrons/pixel/frame

    case 3 % Uncooled- FLIR FH-313 R 320x256 sensor with 17um pixel size

        pixelSize = 17*10^-6; % pixel size in m
        frameRate = 30; % frame rate of camera
        Ny = 256; % number of pixels in y direction
        Nx = 320;

        sensorY = pixelSize*Ny; % sensor size in y-direction
        sensorX = pixelSize*Nx; % sensor size in x-direction

        sensorType = 0; % 0 for uncooled | 1 for cooled
        downStreamNoise = 500; % electrons/pixel/frame

    case 4 % FLIR A6301 640x512 sensor with 15um pixel size

        pixelSize = 15*10^-6; % pixel size in m
        frameRate = 30; % frame rate of camera
        Ny = 512; % number of pixels in y direction
        Nx = 640;

        sensorY = pixelSize*Ny; % sensor size in y-direction
        sensorX = pixelSize*Nx; % sensor size in x-direction

        sensorType = 1; % 0 for uncooled | 1 for cooled
        downStreamNoise = 50; % electrons/pixel/frame
end

% ==============================
% Sensor calcuations
% ==============================
if sensorType == 0 % uncooled option
    darkCurrentDensity = 10^-7; % A/cm2
else % cooled option
    darkCurrentDensity = 10^-12; % A/cm2
end

texp = 1/frameRate*0.8; % exposure time estimate in seconds
FOVdegreeY = rad2deg(sensorY/f); % angular FOV in y direction in deg
FOVdegreeX = rad2deg(sensorX/f); % angular FOV in x direction in deg
pixelArea = pixelSize^2; % area of pixel in m2

darkCurrent = darkCurrentDensity*100^2*pixelArea/electron; % electrons/sec/pixel
darkCurrentElectrons = darkCurrent*texp; % darkCurrent in units of electrons

if texp>1/frameRate
    disp('WARNING: Exposure time is longer than allowed given the camera frame rate.')
end


% ==============================
% Localization and spatial sampling
% ==============================
cameraAngleHorizon = acosd(Rearth/(cameraElevation+Rearth)); % Camera angle to center horizon on sensor
theta = linspace(0,FOVdegreeY,Ny+1); % angle array for camera
beta = 90-cameraAngleHorizon-theta; % angle from marine mammal to platform
distance2whale = (Rearth+cameraElevation)*cosd(beta)-sqrt((Rearth+cameraElevation)^2*cosd(beta).^2-(2*cameraElevation*Rearth+cameraElevation^2));  % line-of-sight distance
surfaceSampling = sqrt(distance2whale.^2-cameraElevation^2); % distance along sea as a function of sensor position (i.e. distance from ship to whale in meters)
distance2whale(imag(distance2whale)~=0) = NaN; % check for empty object distances
surfaceSampling(imag(surfaceSampling)~=0) = NaN; % check for empty object distances

for p=1:Ny
    pixelSizeOnSurface(p)=surfaceSampling(p)-surfaceSampling(p+1); % size of pixel projected on surface
end
distance2whale = distance2whale(2:end); distance2whale = fliplr(distance2whale); % rearrange object distance for clarity
surfaceSampling = surfaceSampling(2:end); surfaceSampling = fliplr(surfaceSampling); % rearrange object distance for clarity

pixelSizeOnSurface = fliplr(pixelSizeOnSurface); % rearrange pixel size on surface for clarity
pixelPerObject = CD./pixelSizeOnSurface; % Number of pixels sampling the object if it were on the surface
pixelScaler = pixelPerObject; % define scaling factor for adjusting effective image size on sensor
pixelScaler(pixelScaler>0.5)=1; % find distances for which the object is sampled sufficiently
indz = find(pixelScaler<=0.5);  % indices of distances for which the object is sampled insufficiently
temp = pixelScaler(indz); % temporary array for normalizing scaling factor
temp = temp./max(temp); % normalize temporary array
pixelScaler(indz)=temp; % adjust scaling factor so that whale image effectively gets smaller when not sampled sufficiently
pixelScaler = smooth(pixelScaler,21,'moving'); % clean up scale factor


% ==============================
% Imaging equations
% ==============================
s2 = -distance2whale.*f./(f-distance2whale); % image distance
m = -s2./distance2whale; % magnification between object and camera sensor
solidAngle2 = Ap./s2.^2; % solid angle image space
h2effective = m.*CD;
h2effective = h2effective.*pixelScaler'; % effective size of target image on sensor adjusted for camera height
ActualTargetAngle = -h2effective/f*10^3; % mrad


% ==============================
% Display parameters for typical human viewing task
% ==============================
displayPixel = 0.2*10^-3; % size of display pixel in meters
distance2display = 600*10^-3; % distance between observer and display
Lum = 34.26; % average display luminance - cd/m2
Msys = displayPixel/distance2display*f/pixelSize; % The total calculated system magnification. This value is defined as the ratio of displayed angle to target angle.


% ==============================
% Calculate signal and noise on sensor
% ==============================
for p=1:length(distance2whale)
    t = opticsTransmission*exp(-attenuationCoefficient.*distance2whale(p)); % optical transmittance
    electronsPerPixel(p) = solidAngle2(end)*pixelArea*texp*t*trapz(lambdaArr,L.*quantumEfficiency./Ep); % electrons/pixel/frame
    electronsPerPixelBackground(p) = solidAngle2(end)*pixelArea*texp*t*trapz(lambdaArr,Lb.*quantumEfficiency./Ep); % background signal in electrons/pixel/frame
    shotNoise(p) = sqrt(electronsPerPixelBackground(p)); % electrons/pixel/frame
end

% ==============================
% MTF of optics, CTF of EYE, and system CTF
% ==============================
samplesMTF = 1024; % number of samples in MTF
maxSpatialFreqSensor = 2; % cycles/mrad

w = rad2deg(ActualTargetAngle*10^-3); % actual target angle in degrees
spatialFreq_mrad = linspace(1E-4,maxSpatialFreqSensor,samplesMTF); % cycles/mrad
spatialFreqDeg = spatialFreq_mrad/rad2deg(1*10^-3); % cycles/degree

spatialFreqMM = spatialFreq_mrad/f; % cylces/mm
MTFdetector = sinc(pixelSize*10^3*spatialFreqMM); % MTF of the detector
MTFdisplay = sinc(displayPixel*10^3*spatialFreqMM/Msys); % MTF of the display
MTFoptics = getSystemMTF(fN,effLambda,spatialFreqMM*Msys); % MTF of the optical system
MTFresult = MTFdetector.*MTFoptics; % effective MTF

% ==============================
% Calculate noise factor
% ==============================
[Heye,Dpup] = getEyeMTF(spatialFreq_mrad/Msys); % get the eye MTF
[NF,~] = getNF(spatialFreq_mrad,Heye,electronsPerPixel-electronsPerPixelBackground,shotNoise,darkCurrentElectrons,downStreamNoise,MTFdisplay,Dpup); % calculate the noise factor

% ==============================
% Calculate system CTF and image quality factor V
% ==============================
cdes = 0.2;  % desired contrast - Desired contrast determines the contrast that should be produced by the target and background signals at the output of this component. The value of desired contrast must be between zero and one.
Lmin = (cdes*(electronsPerPixel+electronsPerPixelBackground)-sqrt((electronsPerPixel-electronsPerPixelBackground).^2))/(2*cdes);
utgt = electronsPerPixel-Lmin; % RSS Contrast Level Target
ugb = electronsPerPixelBackground-Lmin; % RSS Contrast Level Background
ctgt = sqrt((utgt-ugb).^2)./(utgt+ugb); % should be the same as cdes

clear V temp
for p=1:length(w)
    CTFeye(:,p) = getEyeCTF(spatialFreqDeg,Lum,w(p),Msys); % Contrast threshold function for the eye
    CTFsys(:,p) = CTFeye(:,p)'./MTFresult.*NF(:,p)'; % system contrast threshold function, includes image system performance and object SNR (noise factor)

    CTFsysTemp = CTFsys(:,p); % set temporary variable tor computing CTF
    indTemp = find(CTFsysTemp<0); % find where CTF crosses axis
    if isempty(indTemp)~=1
        CTFsysTemp = CTFsysTemp(1:indTemp(1)-20); % adjust CTF to only include region before function ever crosses axis
    end

    [~,indStartCTF] = min(CTFsysTemp); % find minimum position of CTF
    [ ~, indCut ] =  min( abs(CTFsysTemp(indStartCTF:end)-ctgt(p))); % find index that is closest to desired contrast
    indEnd = indCut+indStartCTF; % index of last value in integration

    sFrequency = spatialFreq_mrad(1:indEnd)*Msys; % spatial frequency array used for integration
    CTFsysTemp = CTFsysTemp(1:indEnd); % Portion of CTF used for integration

    if length(sFrequency)<=1
        temp(p)=0; % integration set to zero if CTF is empty
    else
        temp(p) = trapz(sFrequency,sqrt(ctgt(p)./CTFsysTemp)); % integation required for calculating the image quality metric
    end
end

V(1:length(temp)) = ActualTargetAngle(1:length(temp)).*smooth(temp,21,'moving')';  % Image quality metric. Smoothing required for dealing with transition in integration after CTF> cdes


% ==============================
% Calculate Targeting Task Performance (TTP) Metric
% ==============================
A = 1.5; %  The A parameter determines the steepness of the psychometric function used to relate image quality to observer performance.
B = 0; % The B parameter determines the shape of the psychometric function used to relate image quality to observer performance.
ptask = ((V/V50).^(A+B*V/V50))./(1+(V/V50).^(A+B*V/V50)); % probability of performing task given image quality V
ptask(imag(temp) ~= 0) = 0;
ptask = abs(ptask);


% ==============================
% Calculate performance with sequence of images given frame rate
% ==============================
nonP = 1-ptask; % probability that task is unsuccessful
numImages = round(eventDuration*frameRate); % number of images in sequence
nonPseq = nonP.^numImages; % probability that task is unsuccessful after numImages
Pseq = 1 - nonPseq; % probability that task is successful with numImages

MDR = distance2whale(find(Pseq>0.01,1,'last')); % maximum detection range
RDR = distance2whale(find(Pseq>0.999,1,'last')); % reliable detection range

if isempty(RDR)==1
    RDR = 0;
end

if isempty(MDR)==1
    MDR = 0;
end

%%% Adjust probability of detection to include minimum distance
distance2whale = [0 distance2whale(1) distance2whale];
ptask = [0 0 ptask];
Pseq = [0 0 Pseq];

% ==============================
% Whale distribution, pdf, and cdf
% ==============================

for p=1:length(distance2whale)

    if p~=length(distance2whale)
        delR = distance2whale(p+1)-distance2whale(p); 
        delTheta = delR/Rearth; % small angle in radians
    end

    SurfaceAreaCovered(p) =  FOVdegreeY/360*2*pi*(Rearth*10^-3)^2*sin(distance2whale(p)/Rearth)*delTheta; % Surface area of semi annulus at distance distance2whale(p) in km^2
    ExpectedWhales(p) = SurfaceAreaCovered(p)*whaleDensity; % expected number of whales within semi-annulus created by projection camera sensor onto the sea
end

ExpectedWhalesIR = ExpectedWhales.*Pseq; % expected number of whales detected by IR system
ExpectedWhalesIR(isnan(ExpectedWhalesIR))=0; % clean up NaN
pdf = ExpectedWhalesIR./sum(ExpectedWhalesIR); % pdf for whales as function of distance from camera
cdf = cumsum(pdf(2:end)); % cdf for whales as function of distance from camera
cdfW = cumsum(ExpectedWhalesIR(2:end));  % cdf for whales as function of distance from camera in units of whales


% ==============================
% Plot results
% ==============================

figure ('color','white','Position', [100, 100, 800, 800]);
subplot(3,2,1); grid on; hold on;
plot(distance2whale*10^-3,ptask,'-k','linewidth',1.5);
xlabel('Target distance (km)')
ylabel({'Probability of Detection' ,'with one image'})
ylim([0 1])
set(gca,'FontSize',12)

subplot(3,2,2); grid on; hold on;
plot(distance2whale,Pseq,'-k','linewidth',1.5);
xlabel('Distance to cetacean (m)')
ylabel('Probability of Detection')
ylim([0 1])
set(gca,'FontSize',14)

subplot(3,2,3); grid on; hold on;
plot(distance2whale*10^-3,ExpectedWhales,'-r','linewidth',1.5);
plot(distance2whale*10^-3,ExpectedWhalesIR,'-k','linewidth',1.5);


if  max(ExpectedWhalesIR)~=0
ylim([0 max(ExpectedWhalesIR)*2])
end
xlabel('Target distance (km)')
ylabel('Whales detected')
set(gca,'FontSize',12)

subplot(3,2,4); grid on; hold on;
plot(distance2whale(2:end)*10^-3,cdfW,'-k','linewidth',1.5);
xlabel('Target distance (km)')
ylabel('Cumulative whales detected')
set(gca,'FontSize',12)

subplot(3,2,5); grid on; hold on;
plot(distance2whale*10^-3,pdf,'-k','linewidth',1.5);
xlabel('Target distance (km)')
ylabel('pdf')
set(gca,'FontSize',12)

subplot(3,2,6); grid on; hold on;
plot(distance2whale(2:end)*10^-3,cdf,'-k','linewidth',1.5);
xlabel('Target distance (km)')
ylabel('cdf')
set(gca,'FontSize',12)

%%% create distribution plot
figure('color','white','Position', [900, 100, 600, 800]); hold on; grid on;
angleArrF = linspace(-FOVdegreeX/2,FOVdegreeX/2,1000);
xout = [];
yout = [];
for p=1:length(distance2whale)
    numWhales = ExpectedWhalesIR(p);
    if numWhales>=0
        temp=randperm(1000);
        angleArr = angleArrF(temp(1:ceil(numWhales)));

        x = sind(angleArr).*distance2whale(p);
        y = cosd(angleArr).*distance2whale(p);
        xout = [xout x];
        yout = [yout y];
        plot(x,y,'.r','markersize',10);
    end

end

xlabel('x direction (meters)')
ylabel('y direction (meters)')
set(gca,'fontsize',14)

end


% ==============================
%%   FUNCTIONS   %%
% ==============================
function [emis,stefanBoltz,hPlank,k,electron,c,Rearth]=loadConstants()
emis = 1; % emissivity
stefanBoltz = 5.67*10^-8; % Stefan–Boltzmann constant
hPlank = 6.62607015*10^-34; % planck constant
k = 1.380649*10^-23; % boltzmann constant
electron = 1.602*10^-19; % charge of an electron
c = 3*10^8; % speed of light
Rearth = 6371*10^3; % radius of earth in meters
end


function CTFeye = getEyeCTF(spatialFreq,L,w,Msys)

% L is the average display luminance in candelas per square meter
% w is the apparent target angle in degrees
% spatialFreq in cycles/degree
w = w*Msys;
Neye = 2; % number of eyes
num = 540*(1+0.7/L)^-0.2; % numerator for variable a
dem = 1+12./(w.*(1+spatialFreq/3).^2);  % demoninator for variable a
a = num./dem;
b = 0.3*(1+100/L)^0.15;
c = 0.06;

CTFeye = sqrt(2/Neye)./(a.*spatialFreq.*exp(-b.*spatialFreq).*sqrt(1+c.*exp(b.*spatialFreq))); % CTF of the eye

end


function [Heye,Dpup] = getEyeMTF(spatialFreq)

% ξ is the spatial frequency in cycles per milliradian at the eye
% Dpup is calculated in millimeters, and neye is the number of eyes.
% Dpup = 3.9; % mm

Neyes = 2; % number of eyes
L = 12+8; % average luminance
Dpup = -9.011+13.23*exp(-log10(L)/21.082)-0.5*(Neyes-1); % diameter of the eye pupil
E0 = 1/43.69*exp(3.663-0.04974*Dpup^2*log10(Dpup));
i0 = (0.7155+0.277/sqrt(Dpup))^2;

Heye = exp(-(spatialFreq./E0).^i0).* exp(-0.375*spatialFreq.^1.21).*exp(-0.4441*spatialFreq.^2);

end


function MTF = getSystemMTF(fN,lambda,spatialFreqMM)

NAsys = 0.5/fN; % numerical aperture of system
NAobs = 0; 
f0 = 2*NAsys/(lambda*10^3); % 1/mm
eps = NAobs/NAsys;

A = 2/pi*(acos(spatialFreqMM/f0)-spatialFreqMM./f0.*sqrt(1-(spatialFreqMM./f0).^2));
A(spatialFreqMM>f0) = NaN;

MTF = A./(1-eps^2);

end


function [NF,Q] = getNF(spatialFreq,eyeMTF,electronsPerPixel,shotNoise,darkCurrentElectrons,downStreamNoise,MTFdisplay,Dpup)

Ld = 10;  % display luminance in fL
Qe = 4.75;  % temporal bandwidth of eye (Hz)
Qt = 3.538;  % temporal bandwidth of system and eye (Hz)
Aeyepupil = pi*(Dpup/2)^2; % mm^2

neye = 2; % number of eyes
gamma = 240; % The input value gamma (γ) is a unitless term representing the inverse of the eye’s internal contrast noise typically associated with Weber’s Law.
beta = 4.9; % Beta (β) is a psychometric term related to the amount of photon noise inside the eye. Larger values of beta cause image noise to have a smaller impact on performance. The best fit for beta based upon experimental results was 4.9 (default). The units of beta are (root-Trolands)-second.

alpha = sqrt(neye*gamma^2*Qt/(1+beta^2*Qe/(Ld*Aeyepupil))); % constant defined for ease of calculation

for p = 1:length(spatialFreq)
    Hchan = exp(-2.2*log(abs(spatialFreq)./spatialFreq(p)).^2);
    Q(p) = trapz(spatialFreq,abs(eyeMTF.*Hchan.*MTFdisplay).^2); % radiance after integrating over spectrum: units of W/(m2 * sr)
end


for w=1:length(electronsPerPixel) % cycle through distance
    NF(:,w) = sqrt(1+alpha^2.*Q./electronsPerPixel(w).^2*(shotNoise(w).^2+darkCurrentElectrons.^2+downStreamNoise.^2)); % noise factor
end

end


function effLambda = getLambda(L,lambdaArr,quantumEfficiency)

temp1 = trapz(lambdaArr,L.*quantumEfficiency.*lambdaArr.^2); 
temp2 = trapz(lambdaArr,L.*quantumEfficiency.*lambdaArr);

effLambda = temp1/temp2;

end

