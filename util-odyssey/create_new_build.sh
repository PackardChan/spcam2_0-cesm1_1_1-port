#!/bin/bash
 # ------------------------------------------------------------------
 # Author: arhines@fas.harvard.edu
 # Title: create_build_test.sh
 # Description: creates a CESM case, configures it, and builds it.
 #              Finally, a brief test spin-up is submitted and run.
 #              Script MUST be run from a non-legacy Odyssey node.
 #              Options are set up for the c105_c2_v* series
 # ------------------------------------------------------------------
 VERSION=1.0.0
 DATE="Mon 11:57:12 EST 2014"
 USAGE="Usage: create_build_test CASENAME"
 OPTIONS="res [default:f19_f19], compset [default:FC4AQUAP], ncores [default:128] in that order"
 # --- Options processing -------------------------------------------
 if [ $# == 0 ] ; then
     echo $USAGE
     echo $OPTIONS
     exit 1;
 fi
 CASENAME=$1
 # Accept arguments with defaults:
 RES=${2:-"f19_f19"}
 COMPSET=${3:-"FC4AQUAP"}
 NCORES=${4:-"128"}
 MACHINE=${5:-"yellowstone"}
 echo MACHINE!!!!!!!$MACHINE
 echo RES:$RES
 echo COMPSET:$COMPSET
 #module
 #module restore runmodel
 export COMPILER="intel"
 #libs and includes
 #export INC_NETCDF="/n/sw/centos6/netcdf-4.3.0_intel-13.0.079/include"
 #export LIB_NETCDF="/n/sw/centos6/netcdf-4.3.0_intel-13.0.079/lib"
 #export INC_MPI="/n/sw/centos6/openmpi-1.7.2_intel-13.0.079/include"
 #export LIB_MPI="/n/sw/centos6/openmpi-1.7.2_intel-13.0.079/lib"

 SCRIPTDIR=$PWD
 #home05 is the original one
 CESMROOT="/glade/p/cesm"
 CESMDATAROOT="/glade/p/cesm/cseg"
 cd /glade/p/work/mjfu/cesm1_2_2_1/scripts/

 CASEROOT="/glade/u/home/mjfu/cesm_caseroot/${CASENAME}"
 OUTPUT="/glade/scratch/mjfu/${CASENAME}" #ORIGINALLY /P/WORK/ WAS /SCRATCH/
 RUNDIR="/glade/scratch/mjfu/$CASENAME/run"
 echo $CASEROOT

 ./create_newcase -case ${CASEROOT} -mach ${MACHINE} -res ${RES} -compset ${COMPSET}

 cp $SCRIPTDIR/user_nl_cam $CASEROOT
 cp $SCRIPTDIR/user_nl_clm $CASEROOT
 # Copy source modifications
 cp -r $SCRIPTDIR/SourceMods/* $CASEROOT/SourceMods/

 cd $CASEROOT

 # Default setup is for 2 nodes; switch to 4 (lots of places in env_mach_pes.xml):
 sed -i "s/180/${NCORES}/g" env_mach_pes.xml
 sed -i "s/900/${NCORES}/g" env_mach_pes.xml
 ./cesm_setup -clean
 # storage
 ./xmlchange -file env_build.xml -id EXEROOT -val $CASEROOT/bld
 ./xmlchange -file env_run.xml -id RUNDIR -val $RUNDIR
 ./xmlchange -file env_run.xml -id DOUT_S_ROOT -val $OUTPUT

 # Set up for a 5-year run:
 #./xmlchange -file env_build.xml -id GMAKE_J -val 1
 ./xmlchange -file env_run.xml -id STOP_OPTION -val nsteps
 ./xmlchange -file env_run.xml -id STOP_N -val 3
 ./xmlchange -file env_run.xml -id GET_REFCASE -val FALSE
 ./xmlchange -file env_run.xml -id RESUBMIT -val 10
  ##or it will check input data from svn...

 # continue run not a new one?
 ./xmlchange -file env_run.xml -id CONTINUE_RUN -val FALSE

 # restart files
 #./xmlchange -file env_run.xml -id REST_N -val 1
 #./xmlchange -file env_run.xml -id DOUT_S_SAVE_INT_REST_FILES -val TRUE
 #./xmlchange -file env_run.xml -id DOUT_S_SAVE_ALL_ON_DISK -val TRUE
 #./xmlchange -file env_run.xml -id DOUT_S_SAVE_ROOT -val $RUNDIR
   ##this is to save extra restart file

 # branch run
 #BRANCH=TRUE
 #BRCPATH="/glade/scratch/mjfu/"
 #BRCCASE="WACCMSC_CO2_1148"
 #BRCDATE="0013-01-01"
 #./xmlchange -file env_run.xml -id RUN_TYPE -val "branch"
 #./xmlchange -file env_run.xml -id RUN_REFCASE -val $BRCCASE
 #./xmlchange -file env_run.xml -id RUN_REFDATE -val $BRCDATE

 # DEBUG
 #./xmlchange -file env_build.xml -id DEBUG -val TRUE
 #./xmlchange -file env_run.xml -id INFO_DBUG -val 3

 #chemistry
 #./xmlchange -file env_build.xml -id CAM_CONFIG_OPTS -val -chem trop_mam3
 #namelist variable
 # Now namelist variables can only be changed in usr_nl_cam etc.

 # If using a non-standard SST forcing, uncomment this and fill in the path:
 #./xmlchange -file env_run.xml -id SSTICE_DATA_FILENAME -val /glade/scratch/mjfu/SST_4xCO2/finalBC_CESM/sstice_clim.nc
 ######./xmlchange -file env_run.xml -id DOCN_SSTDATA_FILENAME -val /glade/scratch/mjfu/SST_4xCO2/finalBC_CESM/sstice_clim.nc

 # If wanting to change CO2 concentration
 #./xmlchange -file env_run.xml -id CCSM_CO2_PPMV -val 1148

 # change timestep set atm_cpl_dt...(DRV namelist  seq_timemgr_inparm)to change dtime, and atm_cpl_dt is changed by modifying ATM_NCPL(default 48) in env_run.xml
 #./xmlchange -file env_run.xml -id ATM_NCPL -val 8640
 #./xmlchange -file env_run.xml -id GLC_NCPL -val 8640

 # If not using the default deep convection parameterization zmconv_...
 # Then change it from the Buildconf/cam.buildnml.csh
 # Not suggest to change  CAM_CONFIG_OPTS any more!!! cannot change nml there!
 #./xmlchange -file env_build.xml -id CAM_CONFIG_OPTS -val "-nlev 56"


 #configure utilities of CAM (work for CAM only) Not Suggested! will change original set
 #/n/home05/mjfu/cesm1_2_0/models/atm/cam/bld/configure -chem waccm_ghg -nlev 66 -waccm_phys -test

 #configure
 ./cesm_setup
 chmod +x ./Buildconf/*.csh

 #copy branch ref case
 #cp ${BRCPATH}${BRCCASE}/rest/${BRCDATE}-00000/* ${RUNDIR}
 #echo "COPY!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"

 #build
 ./${CASENAME}.build

 # run file changes
 sed -i "s/P00000000/mjfu/g" ${CASENAME}.run
 sed -i "s/ptile=15/ptile=16/g" ${CASENAME}.run
 sed -i "s/8:00/12:00/g" ${CASENAME}.run

 printf "To submit the test job, issue:\nsbatch ${CASENAME}.${MACHINE}.run\n"
 printf "Once that run completes, issue:\n"
 printf "./xmlchange -file env_run.xml -id CONTINUE_RUN -val TRUE\n"
 printf "and then:\n"
 printf "./xmlchange -file env_run.xml -id STOP_N -val 10\n"
 printf "and re-submit as before after changing the wallclock limit\n"
