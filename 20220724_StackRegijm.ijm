// Script by Akash Emmanuel Aravindan (akashemmanuel.ae@gmail.com)
// 2021 09 11, update: 2022 07 24

//-------------------------------------------------------------------------

//input parameters

#@ String(label = "Name of file(s) to analyse ends with:", value=".nd2") fileNameEnd


//choose folder
inputFolder = getDirectory("Input Folder");
print(inputFolder);
filelist = getFileList(inputFolder); 

for (i = 0; i < lengthOf(filelist); i++) {
	
    if (endsWith(filelist[i], fileNameEnd)) { 
    	run("Bio-Formats Importer", "open="+inputFolder+"/"+filelist[i]+" color_mode=Default open_files rois_import=[ROI manager] view=Hyperstack stack_order=XYCZT");
        title = getTitle();
		run("StackReg", "transformation=Translation");
		save(inputFolder+"/"+title+"_StackReg"+".tif");
			
		// close all images
		run("Close");
		}
    } 

