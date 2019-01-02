# spcam2_0-cesm1_1_1-port
spcam2_0-cesm1_1_1 port on Harvard Odyssey. (only porting shown)

This repository is designed only for display purpose.

This repository only shows porting of Superparameterized Community Atmosphere Model 2.0 (SPCAM) - Community Earth System Model 1.1.1 (CESM). It doesn't host the full model code. You cannot run the model with this repository alone. Please find full model code from official [SPCAM wiki](https://wiki.ucar.edu/pages/viewpage.action?pageId=205489281).

I am NOT a developer of the SPCAM/CESM model. I do not claim authorship/ownership of any kind to any script hosted here. Please contact me if any script hosted here is against copyright.

## Running the model
Please see how to run the model on [Harvard Wiki](https://wiki.harvard.edu/confluence/pages/viewpage.action?pageId=228526202). Please create issues here if they do NOT fit in [CESM Forum](https://bb.cgd.ucar.edu/).

## Incompatible changes
 * 20180301: **User experience**. DOUT_S now default true.
 * 20180502: **No known bad impact**. GET_REFCASE change from false to compset default.
 * 20180502: **No known bad impact**. Inputdata directory write access opened.
 * 20190101: **No known impact**. Use official release of SPCAM, discarding unofficial edits by Mark Branson from 2013-08 through 2015-11.
 * 20190101: **Bug unwarned**. Radiation rrtmg bug, affecting CAM5: https://bb.cgd.ucar.edu/4xco2-experiment-crashed-during-running#comment-1014317

## Porting the model
Please do not redo porting if you are running the same model (CESM1.1.1 or SPCAM2.0) on Harvard Odyssey - this helps save disk space.

The following steps are what I did for porting - might be helpful if you are porting same model on a different platform, or similar model on the same platform. If you have Odyssey account, please see private shell script to create this GitHub repository at ~pchan/script/cesm/git-spcam.sh.
1. Register on http://www.cesm.ucar.edu/models/register/register.html
1. Run `svn co https://svn-ccsm-release.cgd.ucar.edu/model_development_releases/spcam2_0-cesm1_1_1`. Accept server certificate and provide username and password from previous step.
1. Read scripts/doc/usersguide/porting.xml
1. Edit ~/.bashrc to include following lines (for CentOS7):
```
module load intel/17.0.4-fasrc01 impi/2017.2.174-fasrc01 netcdf/4.1.3-fasrc02
module load perl-modules/5.10.1-fasrc13
```
5. If you never use cpan (package manager for Perl) before, after loading perl-modules, enter `cpan`, [respond: yes, blank, yes.., then exit cpan](https://www.rc.fas.harvard.edu/resources/documentation/software-on-odyssey/perl/#cpan). (takes several minutes)
1. Locate inputdata: /n/tzipermanfs2/ccsm_inputdata (X) and /n/kuanglfs/dingma/CAM_input (F)
1. Edit like commits in this repository.

