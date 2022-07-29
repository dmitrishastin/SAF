<p align="right">navigation: <a href="https://github.com/dmitrishastin/SAF">home</a> | <a href="https://github.com/dmitrishastin/SAF/blob/main/doc/README.md">description</a> | <a href="https://github.com/dmitrishastin/SAF/blob/main/doc/use.md">use</a> | <a href="https://github.com/dmitrishastin/SAF/blob/main/doc/dstr.md">data structure</a> | <a href="https://github.com/dmitrishastin/SAF/blob/main/doc/outputs.md">outputs</a></p>

# Data structure

Most of the interim and final results are stored in two structures typically called <ins>PS</ins> and <ins>SD</ins> that are carried throughout the framework before being saved amongst outputs. These structures are formed of custom classes (<ins>SD</ins> contains a hierarchy of subclasses) all of which are stored in **Class_files** folder.

## PS 

<ins>PS</ins> is just an abbreviation for parsed structure, it is generated from **init_class** and mainly contains user-provided inputs, a few additional variables, and the log. The log is a cell that is initialised at the beginning and gets updated throughout execution. 


## SD

<ins>SD</ins> stands for stored data, it is generated from **storage_class** and contains most of the input data and results. At initiation, it creates two substructures called <ins>T1</ins> and <ins>DWI</ins> which are both of **modality_class**, and a substructure called <ins>tx</ins> which is of **tx_class**. **storage_class** also contains a wrapper function used to transform mesh coordinates from structural to diffusion space, and <ins>tx</ins> substructure holds paths to registration files.

## T1 and DWI

Both have identical structure. <ins>T1</ins> is only used to store paths to original FreeSurfer files and (during execution) mesh data in structural coordinates. It is not used after the data are brought to diffusion space and is therefore not discussed further.

<ins>DWI</ins> contains two substructures called <ins>rh</ins> and <ins>lh</ins> that are generated from **surfproper_class**, a substructure called <ins>saf</ins> that is generated from **saf_class**, and a number of helper variables which are annotated in **modality_class.m** file. The class file also contains a function that records vertex and face counts and creates a logical array that flags which surface vertices resulted in streamlines during seeding (if used) called <ins>nverts</ins>, <ins>faces</ins>, <ins>seeds</ins>, respectively, within hemisphere substructures. It also contains functions that calculate local cortical half-thickness and create arrays representing vertex-wise data from the cortex of both hemispheres which are later used for GG and HH filters.
  
## rh and lh

These contain hemisphere data (vertex coordinates, paths to files) and their variables are annotated in **surfproper_class.m**. The class itself does not contain any functions.

Throughout the framework, **all scripts strive to maintain a routine whereby <ins>rh</ins> is always handled before <ins>lh</ins>**.

## saf

This structure contains main filtering results as arrays that are annotated in **saf_class.m**. The arrays store streamline-wise information and depending on the array this may also be split into start and end of each streamline. In other words, for the initial (unfiltered) tractogram with N streamlines, every array will be of size 1xN or 2xN, respectively. In the latter case, the top row will always represent the start of each streamline (its first coordinate) and the bottom row will represent the end (its last coordinate). 

Every array in some way relates a respective filtering step to each streamline. For example, <ins>t_gghh</ins> represents GG filter. Generally, the index of the midcortical vertex at which the respective streamline starts or ends is recorded here. For those streamline ends that do not terminate in the cortex a value of 0 is recorded. Then, streamlines surviving GG filtering can be identified as follows:
```
GG = all(SD.DWI.saf.t_gghh);
```
<ins>h</ins> represents the results of HH filter. **It will allocate 0 to all streamline terminations in the right hemisphere, and 1 to all streamline terminations in the left hemisphere.** However, as the empty array contains all zeroes and not all streamlines terminate in the cortex, streamline terminations outside the cortex will also end up recorded as 0. This means that by itself <ins>h</ins> can not be used to detect results of HH filtering. Instead, it is typically combined with GG, e.g.:
```
GGHH = all(SD.DWI.saf.t_gghh) & diff(SD.DWI.saf.h) == 0;
```
Streamlines from each hemisphere surviving GG & HH are selected as follows:
```
rhs = all(SD.DWI.saf.t_gghh) & ~any(SD.DWI.saf.h);
lhs = all(SD.DWI.saf.t_gghh) & all(SD.DWI.saf.h);
``` 
<ins>h</ins> is the only array to store hemispheric data. Other arrays like <ins>t_gghh</ins> will record values that could be from either hemisphere. Selecting indices from each hemisphere can be done as follows:
```
rhi = SD.DWI.saf.t_gghh(:, rhs);
lhi = SD.DWI.saf.t_gghh(:, lhs);
```
This leverages the fact that after GG and HH filters all columns in <ins>t_gghh</ins> identified by rhs and lhs will describe streamlines starting and ending in the neocortex of the corresponding hemisphere.

Similar logic can be applied to all arrays in <ins>saf</ins>. The length of the arrays does not change and it represents the number of streamlines in the unfiltered tractogram; every streamline can be traced back. One exeption to this is filtering with `gwg_hard` enabled. In this case, some streamlines will be broken down into multiple segments leading to <ins>t_gwg</ins> and <ins>h</ins> changing size and order. Although this may be inconvenient for troubleshooting and development, arrays <ins>pre_c</ins>, <ins>pre_xp</ins>, <ins>pre_h</ins> are meant to help trace every segment back. 
