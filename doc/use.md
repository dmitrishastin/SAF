<p align="right">navigation: <a href="https://github.com/dmitrishastin/SAF">home</a> | <a href="https://github.com/dmitrishastin/SAF/blob/main/doc/README.md">description</a> | <a href="https://github.com/dmitrishastin/SAF/blob/main/doc/use.md">use</a> | <a href="https://github.com/dmitrishastin/SAF/blob/main/doc/dstr.md">data structure</a> | <a href="https://github.com/dmitrishastin/SAF/blob/main/doc/outputs.md">outputs</a></p>

# Use

The framework's minimum inputs include paths to the subject's FreeSurfer directory and an MRtrix fibre orientation dispersion (FOD) file. The main outputs are the filtered short association fibre (SAF) tractogram file, a log file and MATLAB data files that can be used as inputs for subsequent post-processing, analysis and/or repeat runs. 

The framework is run as a MATLAB script and it is designed to make use of parallel processing. The inputs are provided as name-value pairs. Boolean inputs can be passed as names only (omitting the accompanying values) to get enabled. Some inputs can be passed as name-value pairs multiple times (the name remains unchanged each time).

<ins><b>NB! Features not described in the publication have not been fully tested</b></ins>

## Required input <a href="#f1" id="s1">[1]</a>

* `fs_dir` path to subject's FreeSurfer directory. Alternatively, a path to a T1-weighted image can be provided to run recon-all on instead (if FreeSurfer is installed) although this is not recommended 
* `fod` path to MRtrix FOD file

## Optional input

### Tractography

* `surfseed` enable seeding from surface mesh vertices (def: false)
* `tckgen` additional tckgen arguments as required (supplied in a single string)
* `noseed` path to a pre-generated .tck file
* `sl_weights` path to a file with pre-generated streamline weights (currently only used to map weights onto the post-filtering streamlines)
* `maxlen` upper threshold for streamline lengths, applied after whole-brain modules before GWG filter (def: 90)

### Filters

* `fastx` only look for intersection with faces when running PG and GWG filters. Disabling will consider edges and vertices too and ensure that for each triangle that each streamline segment intersects (including adjacent half-edges), only one intersection is recorded (def: True)
* `pialfilter` use optional PG filter to remove streamlines outside the cerebral cortex (def: False)
* `gg_margin` this value will be added to the local cortical half-thickness of the GG filter when testing for streamline intracortical termination, with some checks to generally avoid including extrapial streamlines. Higher values will include streamlines terminating deeper into the white matter and will typically increase average streamline length. Streamline ends terminating in white matter within this range need not cross the grey-white interface to be cleared by GWG filter later (def: 0)
* `gwg_hard` GWG will strictly leave just the white matter portions of each streamline, possibly generating multiple small segments. If `notrunc` is also enabled, only the streamlines crossing the grey-white interface strictly twice will be left (def: False)

### Other processing

* `fa` path to a masked fractional anisotropy map file (same space as FOD file) - used for registration
* `registration` name of a MATLAB wrapper script to run structural-diffusion data registration (def: 'SAF_registration_default')
* `noregister` skip registration, assuming structural and diffusion data are in the same space (def: False)
* `remesh_seeds` if seeding from mesh vertices is enabled, temporarily remeshes the surface by bisecting long edges once to improve normality of edge lengths and face areas before using vertex coordinates as seeds; does not affect subsequent steps (def: False)
* `notrunc` leave streamlines untruncated (def: False)
* `scalar2surf` path to a scalar map that will be sampled onto streamlines; mean per-streamline value of all streamlines terminating at surface vertices will then be averaged per vertex producing a FreeSurfer surface map (can be called multiple times)
* `optmodules`<a href="#f2" id="s2">[2]</a> name of a MATLAB script that will execute at the end of the pipeline (can be called multiple times)

### General

* `mrtrix_prefix` a string input to precede mrtrix commands when executing in the shell - e.g., path to libraries or container interaction (def: none)
* `outf` custom output folder (def: "SAF_output" in your provided FOD file directory)
* `dgn` diagnostic mode, produces additional outputs with no clean-up after execution (def: False)
* `wrks` number of workers for parallel computing - sometimes lowering this helps to avoid the occasional crash when doing batch processing (def: same as default matlab profile)
* `force` re-do every step on repeat runs (def: False)
* `quiet` suppress messages (def: False)

## Footnotes

<a id="f1" href="#s1">[1]</a> It is also possible to provide a <ins>PS</ins> structure from a previous run as the first input. This will re-use all inputs from that run and set `force` to True. This can optionally be followed by name-value pairs of inputs to be overwritten (including setting `force` to False if desired). Name-value pairs that take multiple values can be emptied by passing `{''}` as a value.

<a id="f2" href="#s2">[2]</a> `optmodules` points to MATLAB scripts that have <ins>PS</ins> and <ins>SD</ins> structures as inputs (in that order) and <ins>PS</ins> structure as output (to update <ins>PS.log</ins>). They do not have write access to <ins>SD</ins> and so should save any post-processing data externally at run-time, possibly linking to that in the log.

## Examples

Bare minimum run, assumes structural and diffusion data are co-registered:
```
fs_dir = 'path/to/subjects/FreeSurfer/folder';
fod = 'path/to/subjects/fod/file';
[SD, PS] = SAF_pipeline('fs_dir', fs_dir, 'fod', fod, 'noregister');
```

Standard registration settings, seeding from surface vertices disabled and using mask image instead, tracking with FOD amplitude threshold of 0.05 and maximum length 40 mm, generating 5M streamlines, diagnostic mode enabled:
```
fa = 'path/to/subjects/fa/file';
[SD, PS] = SAF_pipeline('fs_dir', fs_dir, 'fod', fod, 'fa', fa, 'tckgen', '-seed_image path/to/mask/file -cutoff 0.05 -select 5M -maxlen 40', 'dgn');
```

Re-run the previous example with the same inputs but also enabling `gwg_hard` and saving outputs to a custom folder (assumes "PS" from the previous step remains in the workspace):
```
CustomDir = 'path/to/custom/dir';
[SD, PS] = SAF_pipeline(PS, 'gwg_hard', 'outf', CustomDir);
```

Bare minimum run, point to gcc libraries for MRtrix to execute correctly (sometimes required e.g. when running on the cluster) - in this example gcc is in /usr/local/:
```
[SD, PS] = SAF_pipeline('fs_dir', fs_dir, 'fod', fod, 'noregister', 'mrtrix_prefix', 'export LD_LIBRARY_PATH=/usr/local/gcc/lib64/;');
```

## Seeding from coordinates

Seeding directly from the surface vertices did not appear to make a strong difference compared to the unaltered MRtrix ACT strategy. Nevertheless, should one wish to explore this option, changes to MRtrix code can be seen [here](https://github.com/MRtrix3/mrtrix3/pull/2493). The easiest way to use it is as follows:

1. Clone the fork:
```
git clone https://github.com/dmitrishastin/mrtrix3 
```
 
2. Switch to coordinate seeding branch (uses development branch):
```
git remote add upstream https://github.com/mrtrix3/mrtrix3 
git fetch upstream
git checkout add_coordinate_seeding
git rebase upstream/dev
```

3. Proceed to build MRtrix as described [on the website](https://mrtrix.readthedocs.io/en/latest/installation/build_from_source.html).

4. Once completed, tckgen should have two more seeding options: `-seed_coordinates_fixed` and `-seed_coordinates_global`. By default, this pipeline uses the latter. 
