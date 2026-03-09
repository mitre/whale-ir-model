# Infrared Camera Cetacean Detection Model

## Description

This README contains instructions for using the infrared (IR) camera model developed by the MITRE Corporation. The model predicts the probability of detecting cetaceans, specifically whale blows, using IR cameras mounted on stable platforms. Probability of detecting whale blows depends on camera specifications, environmental conditions, and whale blow characteristics.

The MATLAB script IRwhaleDetect.m accepts several key parameters that characterize the IR camera system, cetacean of interest, and environmental conditions. Using radiometry and camera projection geometry, the model calculates the probability of detection as a function of distance, the reliable detection range (RDR), maximum detection range, and azimuthal field-of-view. The model assumes that the camera is mounted such that the horizon line is aligned with the top row of the sensor.

## Using the Model

The model runs in MATLAB and requires the Signal Processing and Curve Fitting Toolboxes. After downloading the function IRwhaleDetect and adding the appropriate pathway, the user can type IRwhaleDetect() in the command window to run the model with default values according to the system used in Guazzo et al. The function generates several plots to summarize probability of detection and whale distribution over the sea. 

The function has the following inputs:

	Tb: temperature of background in K (default 307.15 K)
	visibility: visibility in km (default 30km)
	f: focal length of the lens in m (default 100e-3m)
	fN: f-number of the lens (default 1.6)
	cameraElevation: camera height relative to sea level in meters (default 28.1m)
	cameraType: selected sensor type from list below. (default 1 corresponds to FLIR F-606 ID: Uncooled VOx Microbolometer 640x480 sensor with 17um pixel size)
	taskType: object recognition task type (0 for detection |  1 for identification, default is detection)

The model outputs are:
	
	distance2whale: distances between the camera and whale in meters. The array consists of distances that each pixel in the vertical direction corresponds to.
	Pseq: probability of detection as a function of distance.
	RDR: reliable detection range. Maximum distance at which the probability of executing the task is >99.9%
	MDR: maximum detection range. Maximum distance that the probability of detection is >1%
	FOVdegreeX: azimuthal field-of-view of the camera in degrees.

If the user defines all input variables, then the model runs using: 
```Tb = 307;
visibility = 30;
f = 100e-3;
fN = 1.6;
cameraElevation = 30;
cameraType = 1;
taskType = 0;
[distance2whale,Pseq,RDR,MDR,FOVdegreeX] = IRwhaleDetect(Tb,visibility,f,fN,cameraElevation,cameraType,taskType);
```

## Camera Sensor Types

The specifications of the camera sensor are:
	pixelSize: pixel size in m
        frameRate: frame rate of camera in Hz
        Ny: number of pixels in y direction
        Nx: number of pixels in x direction
	downStreamNoise: read-out noise and other downstream sensor noise in electrons/pixel/frame
	darkCurrentDensity: dark current density in A/cm2

The model includes four sensors that can be selected by the user by changing the cameraType input from 1-4. The sensors are:

	Option 1: FLIR F-606 ID, Uncooled VOx Microbolometer
	pixelSize = 17um
	frameRate = 30Hz
	Ny = 480 pixels
	Nx = 640 pixels
	downStreamNoise = 500 electrons/pixel/frame
	darkCurrentDensity = 10^-7 A/cm2

	Option 2:Cooled equivalent to FLIR F-606 ID
	pixelSize = 17um
	frameRate = 30Hz
	Ny = 480 pixels
	Nx = 640 pixels
	downStreamNoise = 50 electrons/pixel/frame
	darkCurrentDensity = 10^-12 A/cm2

	Option 3: Uncooled- FLIR FH-313 R
	pixelSize = 17um
	frameRate = 30Hz
	Ny = 256 pixels
	Nx = 320 pixels
	downStreamNoise = 500 electrons/pixel/frame
	darkCurrentDensity = 10^-17 A/cm2

	Option 4: Cooled - FLIR A6301
	pixelSize = 15um
	frameRate = 30Hz
	Ny = 512 pixels
	Nx = 640 pixels
	downStreamNoise = 50 electrons/pixel/frame
	darkCurrentDensity = 10^-12 A/cm2


## Additional Parameters

The model includes several parameters that an expert user may want to adjust for their application, which can be adjusted in the function directly.

The whale blow geometry can be set as either a cone or ellipsoid with average height and radius. The blow duration and temperature may also be adjusted. Parameters set in the function are based on the Guazzo paper. 

The model assumes several parameters for the camera that can be adjusted. The exposure time is equal to 0.8/framerate. The quantum efficiency of the sensor and optical transmission of the lens system are assumed to be constant with respect to wavelength. 

The task performance metric is based on the human visual system (HVS) response while looking at a display of the image. Therefore, the model also includes parameters on the HVS (e.g., temporal bandwidth of eye, pupil size, number of eyes viewing the image, etc.) and the display (e.g. display luminance, display distance to observer, display pixel size, etc.). All these parameters are set to default values that correspond to the HVS response when viewing a screen in a typical setting.

## Whale distribution plots

The RDR is measured empirically by plotting detections of cetaceans in a histogram and finding the distance corresponding to the peak of the histogram. This method depends on the assumption that the whale distribution is uniform. To compare the model with empirical data, whale distributions are generated by assuming the whale density is also uniform over the sea. The whale density variable whaleDensity will need to be adjusted to match the experimental dataset. The value depends on the duration of the experimental observation (i.e., longer observation time will lead to larger number of detections, which for the model corresponds to a higher density of whales over the sea). The binning of the histogram affects how the model result may appear relative to an experimental dataset, so cumulative density plots may be better for comparing the model to experimental results.


## Support

For support with this model, contact Jon Bumstead (jbumstead@mitre.org). For support related to the NOAA project, contact Project Leader Dr. Matt Adams (mtadams@mitre.org).

## Frequently Asked Questions

- Q: Why?
A: We're trying.

## License

Copyright 2025 The MITRE Corporation

Licensed under the Apache License, Version 2.0 (the "License"); you may not use this file except in compliance with the License. You may obtain a copy of the License at

     http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software distributed under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the License for the specific language governing permissions and limitations under the License.


## References 

Baille, Loïcka M. R.; Zitterbart, Daniel P. Effectiveness of surface-based detection methods for vessel strike mitigation of North Atlantic right whales. Endangered Species Research. 2022.

Vollmerhausen, Richard H.; Jacobs, Eddie. The Targeting Task Performance (TTP) Metric: A New Model for Predicting Target Acquisition Performance. Technical Report AMSEL-NV-TR-230. 2004.

Guazzo, Regina A.; Weller, David W.; Europe, Hollis M.; Durban, John W. Migrating eastern North Pacific gray whale call and blow rates estimated from acoustic recordings, infrared camera video, and visual sightings. Scientific Reports. 2019.