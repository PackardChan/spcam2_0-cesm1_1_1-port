#!/bin/bash
 # ------------------------------------------------------------------
 # Author: 
 # Title: cesm-loop_branch.sh
 # Description: Loop over list of restart dates
 #              Clone a CESM case and submit a restart simulation
 # ------------------------------------------------------------------
 USAGE="Usage: $0 CASEprefix CLONEROOT"
# OPTIONS="res [default:f19_f19], compset [default:F_2000], ncores [default:128] in that order"
 # --- Options processing -------------------------------------------
 if [ $# -ne 2 ] ; then
     echo $USAGE
#     echo $OPTIONS
     exit 1;
 fi
 CASEprefix=$1
 shopt -s extglob
 CLONEROOT=${2%%+(/)}
 cd $CLONEROOT
 clonebld=`./xmlquery EXEROOT -s -valonly`
 # Accept arguments with defaults:
# RES=${2:-"f19_f19"}
# COMPSET=${3:-"F_2000"}
# NCORES=${4:-"128"}
 MACHINE="odyssey"
# echo MACHINE!!!!!!!$MACHINE
# echo RES:$RES
# echo COMPSET:$COMPSET
 #module
 #module restore runmodel
# grep 'impi/5.1.2.150-fasrc01/netcdf/4.1.3-fasrc09' <<< "$LD_LIBRARY_PATH" >/dev/null
 grep 'impi/2017.2.174-fasrc01/netcdf/4.1.3-fasrc02' <<< "$LD_LIBRARY_PATH" >/dev/null
 if [ $? -ne 0 ]; then
   echo
   echo module mismatch!
   echo Loading modules ... takes half a minute ...
   echo load modules beforehand next time ^_^
   echo edit $0 if this behaviour unwanted
#   source new-modules.sh
   module purge
#   module load intel/15.0.0-fasrc01 impi/5.1.2.150-fasrc01 netcdf/4.1.3-fasrc09
#   module load perl-modules/5.22.0-fasrc03
   module load intel/17.0.4-fasrc01 impi/2017.2.174-fasrc01 netcdf/4.1.3-fasrc02
   module load perl-modules/5.10.1-fasrc13
 fi
 export COMPILER="intel"
 #libs and includes
 #export INC_NETCDF="/n/sw/centos6/netcdf-4.3.0_intel-13.0.079/include"
 #export LIB_NETCDF="/n/sw/centos6/netcdf-4.3.0_intel-13.0.079/lib"
 #export INC_MPI="/n/sw/centos6/openmpi-1.7.2_intel-13.0.079/include"
 #export LIB_MPI="/n/sw/centos6/openmpi-1.7.2_intel-13.0.079/lib"

# SCRIPTDIR=$PWD
# CESMROOT="/glade/p/cesm"
# CESMDATAROOT="/glade/p/cesmdata/cseg"

 BRCPATH="/n/home05/pchan/zlf/cesm_output/"  #TODO
 BRCCASE="c3rest"
 casenum=0
 for BRCDATE in `\ls -1 ${BRCPATH}/${BRCCASE}/rest/ |cut -c 1-10`; do

 cd ~pchan/spcam2_0-cesm1_1_1/scripts/

 casenum=$((casenum+1))
 CASE="$CASEprefix$casenum"
 # illustration of directories: http://www.cesm.ucar.edu/events/tutorials/2016/practical1-bertini.pdf p.48
 CASEROOT="${HOME}/cesm_caseroot/ens/${CASE}"  # TODO edit if dislike
 OUTPUT="/n/kuanglfs/${USER}/cesm_output/${CASE}" #TODO "/n/regal/`id -gn`/$USER/cesm_output/${CASE}"
 RUNDIR="${OUTPUT}/run"
 EXEROOT="${OUTPUT}/bld"
 echo $CASEROOT

# ./create_newcase -case ${CASEROOT} -mach ${MACHINE} -res ${RES} -compset ${COMPSET} || exit -1
 ./create_clone -case ${CASEROOT} -clone ${CLONEROOT} || exit -1

 cp -a $0 $CASEROOT/
# cp -a $SCRIPTDIR/Tools/mkbatch.${MACHINE} $CASEROOT/Tools/
#cloned cp -a $SCRIPTDIR/user_nl_* $CASEROOT/
 # Copy source modifications
#cloned cp -a $SCRIPTDIR/SourceMods/* $CASEROOT/SourceMods/

 cd $CASEROOT

 # http://www.cesm.ucar.edu/models/cesm1.1/cesm/doc/modelnl/env_run.html

# sed -i "s/180/${NCORES}/g" env_mach_pes.xml
#TODO ./xmlchange NTASKS_ATM=${NCORES},NTASKS_LND=${NCORES},NTASKS_ICE=${NCORES},NTASKS_OCN=${NCORES},NTASKS_CPL=${NCORES},NTASKS_GLC=${NCORES},NTASKS_ROF=${NCORES}

 # Partition
 sed -i 's/\(#SBATCH -p \).*$/\1huce_amd/' Tools/mkbatch.${MACHINE}  #TODO
 ./xmlchange MAX_TASKS_PER_NODE=64  #TODO
# sed -i 's/\(#SBATCH -p \).*$/\1huce_intel/' Tools/mkbatch.${MACHINE}
# ./xmlchange MAX_TASKS_PER_NODE=32
# sed -i 's/\(#SBATCH --mem-per-cpu=\).*$/\11000/' Tools/mkbatch.${MACHINE}

 # Email when job ends
# sed -i 's/#\(#SBATCH --mail-type\)/\1/' Tools/mkbatch.${MACHINE}  #TODO turn on
# sed -i 's/^\(#SBATCH --mail-type\)/#\1/' Tools/mkbatch.${MACHINE}  #TODO turn off

 ./cesm_setup -clean
 # storage, work against hardcoded dirs
# ./xmlchange DIN_LOC_ROOT="/n/kuanglfs/pchan/CAM_input"  #don't change
 ./xmlchange -file env_build.xml -id EXEROOT -val $EXEROOT
 ./xmlchange -file env_run.xml -id RUNDIR -val $RUNDIR
 ./xmlchange -file env_run.xml -id DOUT_S -val TRUE  #TODO
 ./xmlchange -file env_run.xml -id DOUT_S_ROOT -val $OUTPUT

 grep ${CLONEROOT##*/} env_*.xml
 if [ $? -eq 0 ]; then
   echo not clean, exitting..
   exit -1
 fi

 # Set up for a 1-month run:
 ./xmlchange -file env_run.xml -id STOP_OPTION -val nstep
 ./xmlchange -file env_run.xml -id STOP_N -val 4  #TODO
#TODO ./xmlchange -file env_run.xml -id GET_REFCASE -val FALSE  #or it will check input data from svn...
# ./xmlchange -file env_run.xml -id RESUBMIT -val 1  #times of submit = RESUBMIT+1

 # continue run not a new one?
 ./xmlchange -file env_run.xml -id CONTINUE_RUN -val FALSE  # false: new run

 # restart files
 #./xmlchange -file env_run.xml -id REST_N -val 1
# ./xmlchange -file env_run.xml -id DOUT_S_SAVE_INT_REST_FILES -val TRUE  #TODO retain intermed restart
 #./xmlchange -file env_run.xml -id DOUT_S_SAVE_ALL_ON_DISK -val TRUE
 #./xmlchange -file env_run.xml -id DOUT_S_SAVE_ROOT -val $RUNDIR
   ##this is to save extra restart file

 # branch run (http://www.cesm.ucar.edu/models/cesm1.1/cesm/doc/usersguide/ug.pdf#use_case_branch)
 BRANCH=1
 if [ $BRANCH == 1 ] ; then
#   BRCPATH="/n/kuanglfs/nedkleiner/cesm_output/"
#   BRCCASE="longtest"
#   BRCDATE="0031-01-01"  #set before
   ./xmlchange -file env_run.xml -id RUN_TYPE -val "branch"
   ./xmlchange -file env_run.xml -id RUN_REFCASE -val $BRCCASE
   ./xmlchange -file env_run.xml -id RUN_REFDATE -val $BRCDATE
 fi

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
 ./xmlchange -file env_run.xml -id CAM_NAMELIST_OPTS -val solar_const=700.  #TODO pchan only

 # change timestep set atm_cpl_dt...(DRV namelist  seq_timemgr_inparm)to change dtime, and atm_cpl_dt is changed by modifying ATM_NCPL(default 48) in env_run.xml
 #./xmlchange -file env_run.xml -id ATM_NCPL -val 8640
 #./xmlchange -file env_run.xml -id GLC_NCPL -val 8640

 # If not using the default deep convection parameterization zmconv_...
 # Then change it from the Buildconf/cam.buildnml.csh
 # Not suggest to change  CAM_CONFIG_OPTS any more!!! cannot change nml there!
 #./xmlchange -file env_build.xml -id CAM_CONFIG_OPTS -val "-nlev 56"


 #configure utilities of CAM (work for CAM only) Not Suggested! will change original set
 #/n/home05/mjfu/cesm1_2_0/models/atm/cam/bld/configure -chem waccm_ghg -nlev 66 -waccm_phys -test

# ./xmlchange -file env_build.xml -id GMAKE_J -val 4
 #configure
 ./cesm_setup
 ln -sfT $OUTPUT scratch

 #build
 cp -a $clonebld/cesm.exe $EXEROOT/
# cp -a $clonebld/* $EXEROOT/
 # sed required if re-build needed
 # Deppath Filepath Makefile.conf* config.* *.bldlog.*
# ./${CASE}.build
 echo
 ./xmlchange -file env_build.xml -id BUILD_COMPLETE -val TRUE  # fool *.run

 #branch: copy restart file
 if [ $BRANCH == 1 ] ; then
   cp -a ${BRCPATH}/${BRCCASE}/rest/${BRCDATE}-00000/rpointer.* ${RUNDIR}/
   ln -sf ${BRCPATH}/${BRCCASE}/rest/${BRCDATE}-00000/${BRCCASE}.* ${RUNDIR}/
   echo branch from ${BRCPATH}/${BRCCASE}/rest/${BRCDATE}-00000/
 fi

 # echo
 grep -Ev '^\s*$|^\s*!' user_nl_*
 \ls -l SourceMods/*/*

 # run file changes
# sed -i "s/P00000000/mjfu/g" ${CASE}.run
# sed -i "s/ptile=15/ptile=16/g" ${CASE}.run
# sed -i "s/8:00/12:00/g" ${CASE}.run

 ./${CASE}.submit
done
# printf "To submit job, issue:\n"
# printf "cd ${CASEROOT}\n"
# printf "./${CASE}.submit\n"

