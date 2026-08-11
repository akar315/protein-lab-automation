// Script by Akash Emmanuel Aravindan (akashemmanuel.ae@gmail.com)
// 2020 10 20, update: 2022 05 11
// images analyze for particles, area, mean cIn/cOut, mean cIn-cOut, mean fraction phase separated
// processes all images within stacks and all images within a folder
// creates subfolder analysis. Here all analysis values will be stored.

// NEW! testSegmentaion - This option allows manual inspection of the segmentation. Put the variable to 1 for 
// manual adjustment of the segmentation parameters, blur1, blur2, segementation_threshold and number_of_erodes.
// Adjust the parameters using a representative image for the most extreme conditions, e.g. drops and no drops.
// Use testSegementation = 0 for final analysis of the entire dataset. 
// Mac or PC - please read in the function "saveData" and adjust accordingly. 

run("Collect Garbage");
run("Clear Results");
run("Input/Output...", "jpeg=85 gif=-1 file=.csv use_file copy_column copy_row save_column decimal=3");

//ManualSegmentationAdjustment--------------------------------------------------------------------

testSegmentation 		= 0; // 0 = analyze complete dataset, 1 = test and adjust segmentation manually

//VariablesForManualSegmentationAdjustment--------------------------------------------------------

blur1					=  5.00; 	// Value used to blur the temp image to remove speckels amd smoothen the outlines
blur2					=  50.00; 	// Value used to blur the temp image for illumination correction and image normalization
segmentation_threshold	=   0.10; 	// Smaller values will segment dimmer objects (closer to background) 
number_of_erodes		=   0.00; 	// The image_illumination_correction increases the segmentation area. This value corrects for this
camera_noise 			= 100.00; 	// This value is the camera noise and will be subtracted from the measured values
pixels_to_crop 			= -10.00; 	// This value crops the image to focus the analysis to the center of the image
min_condensate_size		=   2.00; 	// This is the minimum area of a droplet
Channel_for_Segmentation=  2;

//Analysis-----------------------------------------------------------------------------------------
if (testSegmentation == 0) {
setBatchMode(true);
input 	= getDirectory("Input directory");
output	= "condensate analysis";
File.makeDirectory(input + output);
Dialog.create("File type");
Dialog.addString("File suffix: ", ".nd2", 5);
Dialog.show();
suffix = Dialog.getString();

//------------------------------------------------------------------------------------------------

processFolder(input);
function processFolder(input) {
	list = getFileList(input);
	for (i = 0; i < list.length; i++) {
		if (File.isDirectory(list[i])) processFolder("" + input + list[i]);
		if (endsWith(list[i], suffix)) processFile(input, output, list[i]);
	}
}

function processFile(input, output, file) {
	run("Collect Garbage");
	file_to_open = input + file;
	run("Bio-Formats Importer","open=[file_to_open] color_mode=Default concatenate_series open_all_series rois_import=[ROI manager] view=Hyperstack stack_order=XYCZT");
	img = getTitle();
	resetMinAndMax();
	regionToAnalyze(pixels_to_crop);
	getDimensions(width, height, channels, slices, frames);
	for (slice = 0; slice < slices; slice++) {
		Stack.setChannel(Channel_for_Segmentation);
		//Stack.setSlice(slice + 1);
		for (frame = 0; frame < frames; frame++) {
			Stack.setFrame(frame + 1);
			illumination_correction(blur1, blur2);
			segmentation(segmentation_threshold, number_of_erodes);
			measure_condensates();
			//size_correction(channels);
		}
	}
	saveData(input, output, file);
}

function regionToAnalyze(pixels_to_crop) {
	run("Select None"); 
	run("Select All");
	run("Enlarge...", "enlarge=" + pixels_to_crop + " pixel");
	run("Crop");
}

function illumination_correction(blur1, blur2) {
	run("Select None");
	Stack.setChannel(Channel_for_Segmentation);
	run("Duplicate...", "title=measure_this");
	run("Duplicate...", "title=img_smoothed");
	run("Gaussian Blur...", "sigma=" + blur1);
	img_smoothed_blur1 = getTitle();
	run("Duplicate...", "title=img_blur2");
	img_blur2 = getTitle();
	run("Gaussian Blur...", "sigma=" + blur2);
	imageCalculator("Divide create 32-bit", img_smoothed_blur1, img_blur2);
	close(img_smoothed_blur1);
	close(img_blur2);
	close("measure_this");
	selectWindow("Result of img_smoothed");
	rename("img_illumination_corrected_normalized");
	run("Despeckle");
}

function segmentation(segmentation_threshold, number_of_erodes) {
	roiManager("reset");
	selectWindow("img_illumination_corrected_normalized");
	getStatistics(x, Mean, Min, Max, SD);
	minimum_threshold = Mean + (segmentation_threshold * Mean);
	maximum_threshold = Max;
	setThreshold(minimum_threshold, maximum_threshold);
	setOption("BlackBackground", true);
	run("Create Mask");
	run("Fill Holes");
	for (i = 0; i < number_of_erodes ; i++) {
	 run("Erode");
	}
	run("Watershed");
	run("Create Selection");
	roiManager("split");
	close("Mask of mask");
	close("Mask");
	close("mask");
	close("Result of smoothed");
	close("img_illumination_corrected_normalized");
}

function measure_condensates() {
	selectWindow(img);
	getDimensions(width, height, channels, slices, frames);
	no_particles = roiManager("count");
	n = nResults;
	for (i = 0; i < no_particles ; i++) {
		for (c = 0; c < channels; c++) {
			Stack.setChannel(c+1);
			roiManager("select", i);
			//Condensate parameters
				Width_condensate_Ch 	= "Width_condensate_Ch"+c;
					Width_condensate 	= getValue("Width");
				run("Enlarge...", "enlarge=" + (Width_condensate / -6));
				Mode_condensate_Ch 		= "Mode_condensate_Ch"+c;
					Mode_condensate 	= getValue("Mean") - camera_noise;
				Max_condensate_Ch 		= "Max_condensate_Ch"+c;
					Max_condensate 		= getValue("Max") - camera_noise;
				Skew_condensate_Ch 		= "Skew_condensate_Ch"+c;
					Skew_condensate 	= getValue("Skew");
			//Local Condensate background
			roiManager("select", i);
				run("Enlarge...", "enlarge=" + (sqrt(Width_condensate) / 1));
				Mean_bg_Ch 				=  "Background_condensate_Ch"+c;
					Mean_bg 			= getValue("Min") - camera_noise;
			//Calculate partition coefficient
				PC_Ch 					= "PC_Ch"+c;
					 PC_condensate 		= Mode_condensate / Mean_bg;
				cINcOUT_Ch				= "cIncOut_Ch"+c;
					cINcOUT				= Mode_condensate - Mean_bg;
			//Built results table
				setResult("Area_condensate",		n+i, getValue("Area"));
				setResult(Width_condensate_Ch, 		n+i, Width_condensate);
				setResult(Mode_condensate_Ch, 		n+i, Mode_condensate);
				setResult(Max_condensate_Ch, 		n+i, Max_condensate);
				setResult(Skew_condensate_Ch, 		n+i, Skew_condensate);
				setResult(Mean_bg_Ch, 				n+i, Mean_bg);
				setResult(PC_Ch, 					n+i, PC_condensate);
				setResult(cINcOUT_Ch, 				n+i, cINcOUT);
				setResult("Slice", 					n+i, getValue("Slice"));
				setResult("Frame", 					n+i, getValue("Frame"));
		}
		updateResults();
	}
	selectWindow(img);
}

function saveData(input, output, file){
	saveAs("Results", input + output + "\\" + file + "_condensate_analysis.txt"); // "/"for mac and "\\"for windows
	close(img);
	run("Clear Results");
}

cleanUp();
function cleanUp() {
	run("Collect Garbage");
	print("All done");
	setBatchMode(false);
}
}

else {
img = getTitle();
Stack.setChannel(Channel_for_Segmentation);
resetMinAndMax();
//Dialog
abort = 0;
while (abort == 0) {
Dialog.create("Image Segmentation Settings");
Dialog.addSlider("Blur 1:", 1, 20, blur1);
Dialog.addSlider("Blur 2:", 1, 100, blur2);
Dialog.addSlider("Segmentation Threshold:", 0.01, 0.99, segmentation_threshold);
Dialog.addSlider("Number of Erodes:", 0, 5, number_of_erodes);
Dialog.addCheckbox("Abort", false);
Dialog.show();
 blur1 = Dialog.getNumber();
 blur2 = Dialog.getNumber();
 segmentation_threshold = Dialog.getNumber();
 number_of_erodes = Dialog.getNumber();
 abort = Dialog.getCheckbox();
illumination_correction(blur1, blur2);
segmentation(segmentation_threshold, number_of_erodes);
selectWindow(img);
roiManager("show all without labels");
print("\\Clear");
print("Blur 1: " + blur1);
print("Blur 2: " + blur2);
print("Segmentation Threshold: " + segmentation_threshold);
print("Number of Erodes: " + number_of_erodes);
}
}
