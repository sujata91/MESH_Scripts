#Shell script to clip the netcdf file using bilinear interpolation based on basin_grid_information, fill the missing value for leap year (Feb 29 based on the average value of Feb 28 and March 1) and fill the missing cell value to nearest neighbor cell
#Written by Sujata(sujata.budhathoki@usask.ca) and Daniel Princz (daniel.princz@canada.ca) (2020/10/16)
#Following example clips the CanRCM4-WGC data from the Graham cluster (script can be modified to clip any other netcdf source file and fill the missing values) 
#Output is netcdf file
#Provide the basin_grid_information in separate text file

#!/bin/bash
module load cdo #Load the module named cdo

for R in {8..10}
do
 for P in {1..5}
  do
    for field in huss pr ps rlds rsds sfcWind tas 

    do
      cdo -b F32 remapbil,basin_grid_information /project/6008034/Model_Output/CCRN/CanRCM4/WFDEI-GEM-CaPA/r"${R}"i2p1r"${P}"/"${field}"_r"${R}"i2p1r"${P}"_final.nc4 /path_to_output_folder/"${R}""${field}""${P}".nc  #clip the netcdf file using bilinear interpolation based on basin grid information( Note: Run this line individually if there is no issue with missing data)
     
   	  infile=/path_to_output_folder/"${R}""${field}""${P}".nc #Clipped forcing file
	  
	  set -e 

      isleap() {

      date -d $1-02-29 &>/dev/null && echo 0 || echo 1

      }

      outfile=/final_path_to_output_folder/"${R}""${field}""${P}"_Final.nc #Final filled forcing file
      for year in $(cdo showyear $infile)

      do

       if [ $(isleap $year) -eq 0 ] 

       then

        for hour in {00..23..3}

        do

         cdo -L -a -b 32 -settime,$hour:00:00 -setday,29 -setmon,2 -divc,2 -add -seltime,$hour:00:00 -selday,28 -selmon,2 -selyear,$year $infile -seltime,$hour:00:00 -selday,1 -selmon,3 -selyear,$year $infile tmp.$year.$hour.nc #fill the missing Feb 29 value for leap year

        done

       fi

    done

    cdo -a mergetime $infile tmp.????.??.nc tmp.nc

    cdo setcalendar,'standard' tmp.nc tmp1.nc #set the time to standard netcdf calender
  
    cdo setmisstonn tmp1.nc $outfile #Fill the missing cell value to nearest neighbor cell, if there are no missing cell values then comment out this line

    rm tmp.????.??.nc tmp.nc tmp1.nc
    done
 done
done
