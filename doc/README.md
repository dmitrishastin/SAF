<p align="right">navigation: <a href="https://github.com/dmitrishastin/SAF">home</a> | <a href="https://github.com/dmitrishastin/SAF/blob/main/doc/README.md">description</a> | <a href="https://github.com/dmitrishastin/SAF/blob/main/doc/use.md">use</a> | <a href="https://github.com/dmitrishastin/SAF/blob/main/doc/dstr.md">data structure</a> | <a href="https://github.com/dmitrishastin/SAF/blob/main/doc/outputs.md">outputs</a></p>

# Description

The framework follows a series of processing steps that result in a filtered short association fibre (SAF) tractogram and additional outputs. Results of every step are recorded in a data structure and can be accessed subsequently without having to re-run anything. 

## Registration

The first step will register diffusion to structural data using a masked fractional anisotropy map and a FreeSurfer brain image. The surface meshes are then brought into diffusion space using inverse transform. All subsequent processing is performed in diffusion space. It is possible to omit registration (by passing `noregister` input) if the data are pre-registered. Alternatively, custom registration scripts may be created following the structure of the default registration module and used by passing `registration` input followed by the name of the matlab script.

## Tractography

Framework-specific filtering is carried out on an initial unfiltered tractogram which can be generated or provided. For the original paper, [a modified version of MRtrix](https://github.com/MRtrix3/mrtrix3/pull/2493) was used that enabled seeding from surface vertices, and default settings are set for this mode. Standard MRtrix seeding mechanisms can be enabled by changing `surfseed` value to 'false'. A pre-generated tractogram may be provided using `noseed` input followed by a path to the .tck file. For SAF-specific tractography, a lower FOD threshold and probabilistic tractography algorithms are recommended.

## GG and HH filters

Tractogram filtering begins by generating mid-cortical mesh coordinates (MCC). This involves averaging the corresponding coordinates of the white (inner cortical) and pial (outer cortical) meshes. Next, at each MCC the corresponding cortical thickness is calculated. For each end of every streamline, the closest MCC is found and if the streamline end lies within a sphere centred on that MCC with diameter equal to its corresponding cortical thickness, the streamline end is recorded as terminating at that MCC. All streamlines that do not terminate in the cortex at either end are discarded (GG, or grey-grey, filter). All streamlines that do not terminate in the same hemisphere are discarded (HH, or hemisphere-hemisphere, filter).

## PG filter

This optional filter removes streamlines that course outside the brain. It works on the same principle as the GWG filter below and can take a while to run; as there are usually very few (if any) streamlines outside, it is disabled by default but can be switched on by passing `pialfilter` as input (particularly useful at very low FOD thresholds). Technically, the pipeline can be modified to run this after GWG thus decreasing the number of streamlines to be examined but it was considered advantageous to apply the filter before the tractrogram-wise modules.

## Additional tractogram-wise modules

Any modules that require whole-brain tractogram processing before the tractogram is reduced to SAF-specific streamlines are executed here. Currently more of a placeholder, it enables allocation of whole-brain tractogram weights to individual streamlines (input: `sl_weights`) and application of maximum streamline length filter (input: `maxlen`) that is enforced after any whole-brain processing takes place. Once this processing is complete, streamlines that do not terminate in non-neocortical grey matter are no longer handled.

## GWG filter

GWG (grey-white-grey) filter detects streamline escape into the white matter by looking for intersections between all remaining streamlines and the white matter cortical mesh of each hemisphere. The default mode will look for escape at streamline ends only. This means that as long as both ends are in the grey matter (confirmed by the GG filter) and there are at least two intersections with the white matter mesh, the section in between is deemed to be coursing in the white matter and the streamline is passed by the filter. The alternative mode (`gwg_hard` input) considers every intersection and will subdivide streamlines into smaller fragments (potentially more than one per streamline) for >2 intersections. Intersection detection by default happens for mesh faces only, a more precise mechanics including considering vertices and edges can be enabled by setting `fastx` to 'false' although this is typically of little advantage and works slower.

The filter will also record the white surface mesh (as opposed to MCC) vertex closest to each intersection and truncate the intracortical streamline portions (default behaviour, can be disabled with `notrunc` input).

## Optional modules and wrap up

The final part of the framework will produce surface maps including streamline termination density, mean streamline length per vertex and mean scalar values per streamline (averaged per cortical vertex). When fractional anisotropy is provided for registration, its averaged cortical map is calculated automatically. Any other scalars can be sampled using `scalar2surf` input. After this step, user-provided optional post-processing modules can be run at the end of the framework (`optmodules` input). The last step includes calculating summary statistics, recording log and saving data. Temporary data will be deleted unless diagnostic mode is switched on (`dgn` input).
