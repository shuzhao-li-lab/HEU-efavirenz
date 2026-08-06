# HEU-efavirenz metabolomics

This is the repository for data analysis in Chong and Zheng et al., 
"Distinct biochemical phenotypes of HIV exposed infants driven by antiviral medication".

All steps are described under `notebooks/`, using shell or R scripts, notebooks in R or Python:

```
├── 00_heu_metabolomics_processing
│   ├── autodrop.json
│   ├── HILICneg_pcpfm_metadata.csv
│   ├── HILICpos_pcpfm_metadata.csv
│   ├── pcpfm_HILICneg.sh
│   ├── pcpfm_HILICpos.sh
│   ├── pcpfm_RPneg.sh
│   ├── pcpfm_RPpos.sh
│   ├── RPneg_pcpfm_metadata.csv
│   └── RPpos_pcpfm_metadata.csv
├── 01_heu_ms1_ms2_annotations
│   ├── 01_2026-05-21_HEU_ms1_srm_authlib_annotation.ipynb
│   ├── 02_2026-05-28_HEU_CSM_L4_annotations.ipynb
│   ├── 03_2026-05-22_HEU_MS2_annotations_MSDial_MONA.ipynb
│   ├── 04_2026-05-21_building_ms1_library.R
│   ├── 05_2026-05-22_building_ms2_library.R
│   └── 06_2026-05-26_combining_heu_annotations.R
└── 02_heu_metabolomics_analysis
    └── 01_2025-12-10_HEU_Metabolomics_Analysis.qmd
```

## Data Availability: 	
The input data (metabolomics and meta data) used in this project are available on Zenodo (DOI 10.5281/zenodo.21827608) and as release on this repo:
https://github.com/shuzhao-li-lab/HEU-efavirenz/releases/download/v1.0-data/2026_07_30_HEU_Metabolomics_DataFreeze.zip

## Citation
To come.
