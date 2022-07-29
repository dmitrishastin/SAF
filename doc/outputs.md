<p align="right">navigation: <a href="https://github.com/dmitrishastin/SAF">home</a> | <a href="https://github.com/dmitrishastin/SAF/blob/main/doc/README.md">description</a> | <a href="https://github.com/dmitrishastin/SAF/blob/main/doc/use.md">use</a> | <a href="https://github.com/dmitrishastin/SAF/blob/main/doc/dstr.md">data structure</a> | <a href="https://github.com/dmitrishastin/SAF/blob/main/doc/outputs.md">outputs</a></p>

# Outputs

## Standard

### Main

- **SAF.tck**: tractogram containing short association fibres after filtering
- **PS.mat**: MATLAB file containing <ins>PS</ins>
- **SD.mat**: MATLAB file containing <ins>SD</ins>
- **log.txt**: log generated from <ins>PS.log</ins> containing timestamp, inputs, filtering performance info, summary statistics. Alternatively, <ins>PS.log</ins> can be queried from multiple datasets to describe a cohort. Optional modules can be written to add entries into the log.

### Additional

- **ants_\***: registration files mapping structural to diffusion space and vice versa
- **brain_DWI.nii.gz**: FreeSurfer's T1-weighted **brain.mgz** image in diffusion space
- **brain_T1.nii.gz**: original FreeSurfer's **brain.mgz** image in NIFTI format
- **DWI_\*** and **T1_\***: surface coordinate files in diffusion and structural spaces, respectively
- **DWI_seeds_out.txt**: seed coordinates per streamline (output of tckgen)
- **remeshed_seeds.txt**: tckgen input for coordinate seeding after remeshing (if `remesh_seeds` enabled)

### Surface function directory

Contents of **surf_data** folder follow the standard FreeSurfer format for surface overlays (Mx1 with row number representing the vertex index and value representing the function value at that vertex). Files for left and right hemispheres start with **lh** and **rh**, respectively. These include:

- **\*.seeds**: distribution of seeds that resulted in streamlines - seed coordinate output from tckgen (request automatically appended to `tckgen`) distributed amongst surface vertices based on Euclidean distance with per-vertex seed counts recorded (only with `dgn` input)
- others: the naming convention is hh.dd.aa, where:
  - hh is the hemisphere (as described above)
  - dd is the input data used to generate the file and this will either be named after an array in <ins>SD.DWI.saf</ins> (e.g., <ins>t_gghh</ins> represents termination density of streamlines surviving GG & HH filters, <ins>t</ins> - termination density of SAF streamlines, <ins>l</ins> - mean streamline length of SAF) or a supplied scalar map being sampled onto the streamlines
  - aa is the array from <ins>SD.DWI.saf</ins> (either <ins>t_gghh</ins> or <ins>t</ins>) that is used for mapping streamline terminations to the surface (<ins>t_gghh</ins> will use initial streamline termination points at the mid-cortical coordinates while <ins>t</ins> will consider streamline intersections of the white surface mesh).
- any mapping of scalar maps onto streamlines is also stored here

## Diagnostic mode

Will be added at a later stage.
