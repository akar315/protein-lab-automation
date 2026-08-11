// Script by Akash Emmanuel Aravindan (akashemmanuel.ae@gmail.com)
// 2021 09 11, update: 2022 02 02
//This script performs a FRAP analysis.
//It requires 3 ROIS needed
// ROI 1 = FRAP 						/ Mean1
// ROI 2 = TOTAL CELL or reference ROI 	/ Mean2
// ROI 3 = BACKGROUND 					/ Mean3
//It will also grab the time stamp per frame from the image OME data and compute the correct time
//The script will also lookup the FRAP frame and correct the time accordingly, such that the FRAP event equals t=0


//Set the measurements
	run("Set Measurements...", "area mean invert redirect=None decimal=3");
	run("Input/Output...", "jpeg=100 gif=-1 file=.csv copy_column copy_row save_column save_row");

//get and calibrate File info
	dir=getDirectory("image");
	name=getTitle;
	imageCount=nSlices
	Stack.getDimensions(width, height, channels, slices, frames)
	getPixelSize(unit, pw, ph, pd);

//place scale bar
	run("Set Scale...", "distance="+1/pw+" known=1 pixel=1 unit=um");
	//run("Scale Bar...", "width=1 height=2 font=18 color=White background=None location=[Lower Right] bold hide");


//set directory to which analysis data will be saved
	output_directory = "FRAP_analysis";
	File.makeDirectory(dir+output_directory);
	output = dir+output_directory+"//";


//User Interactive section to select ROIs
	roiManager("Reset");
	setTool("rectangle");
	makeRectangle(100, 100, 30, 30);
	waitForUser("Select the FRAP region ROI");
	setTool("oval");
	roiManager("Add");
	waitForUser("Select the TOTAL region ROI");
	roiManager("Add");
	waitForUser("Select the Background ROI");
	roiManager("Add");

//measure ROI intensities for FRET analysis 
	roiManager("Select", newArray(0,1,2));
	roiManager("Multi Measure");
	
//grab time from file ome data information
	run("Bio-Formats Macro Extensions");
	path = dir+name;
	Ext.setId(path); 
	for (no=0; no<nSlices; no++) 
		{
		Ext.getPlaneTimingDeltaT(dt, no); 
		//print(dt);
		setResult("time",no,dt); 
  		}

		

//calculate FRAP 
	for (no=0; no<imageCount; no++) {
	    //setResult('time', no, s);
	    setResult('X1', no, no+1);
	    newTime = getResult('X1', no); 
	    setResult('NewTime', no, newTime * 0.5);
	    Mean1=getResult('Mean1',no);
	    Mean2=getResult('Mean2',no);
	    Mean3=getResult('Mean3',no);
	    setResult('FRAP', no, Mean1-Mean3);
	    setResult('TOTAL', no, Mean2-Mean3);
	    FRAP0=getResult('FRAP', 0);
	    TOTAL0=getResult('TOTAL', 0);
	    setResult('FRAP1', no, ((Mean1-Mean3)/FRAP0) / ((Mean2-Mean3)/TOTAL0));
	  }
	

//Save data to disk
	saveAs("Measurements", output+name+"_54.txt");
	//run("Close");
	//close(name);

//clear memory
	call("java.lang.System.gc");
	call("java.lang.System.gc");
