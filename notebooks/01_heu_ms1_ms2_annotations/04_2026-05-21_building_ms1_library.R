library(tidyverse)

# ok we have SRM annotations, CSM official annotations, L4 annotations (hmdb + lmsd) and authentic library

#### SRM and authentic library in 1

ms1_anot_dir <- "/Users/chongj/Desktop/Li_Lab/Projects/HEU/2026-05-21_MS1/2026-05-21_csm_srm_annotations/"

ms1_files <- list.files(ms1_anot_dir,
                        pattern = "Concise",
                        full.names = TRUE) %>%
  map_dfr(~ readr::read_delim(.x, show_col_types = FALSE) %>%
            mutate(source_file = basename(.x))) %>%
  dplyr::mutate(mode = case_when(
    grepl("hilicneg", source_file) ~ "HILIC_neg",
    grepl("hilicpos", source_file) ~ "HILIC_pos",
    grepl("rpneg", source_file) ~ "RP_neg",
    grepl("rppos", source_file) ~ "RP_pos",
  ))

auth_lib_matches <- ms1_files %>%
  dplyr::filter(!is.na(lib_id)) %>%
  dplyr::select(id, mz, rtime,
                lib_id, lib_name,
                lib_mz, lib_rtime,
                lib_identifier,
                lib_ion, lib_isotope, mode) %>%
  dplyr::mutate(source = "v3_authlib2024")

srm_matches <- ms1_files %>%
  dplyr::filter(!is.na(CSMF_ID)) %>%
  dplyr::select(id, mz, rtime,
                CSMF_ID, CSM_ion,
                CSM_top_recommendation_name,
                CSM_HMDB,
                CSM_rtime, CSM_mz,
                mode) %>% 
  dplyr::rename(lib_id = CSMF_ID,
                lib_mz = CSM_mz,
                lib_rtime = CSM_rtime,
                lib_name = CSM_top_recommendation_name,
                lib_ion = CSM_ion,
                lib_identifier = CSM_HMDB) %>%
  dplyr::mutate(source = "srm1950lib_v1")

#### L4 annotations

l4_annots <- "/Users/chongj/Desktop/Li_Lab/Projects/HEU/2026-05-21_MS1/2026-05-28_heu_combined_all_ms1_l4_annotations.csv" %>%
  read.csv() %>%
  dplyr::select(feature, accession, 
                primary_id, primary_db, name,
                neutral_formula_mass, mode) %>%
  dplyr::rename(id = feature,
                lib_id = accession,
                lib_identifier = primary_id,
                lib_name = name,
                lib_mz = neutral_formula_mass, 
                source = primary_db)

#### CSM annotations

csm_annots <- list.files("/Users/chongj/Desktop/Li_Lab/Projects/HEU/2026-05-21_MS1/CSM_annotations/",
           pattern = "recommended.tsv", 
           full.names = TRUE) %>%
  map_dfr(~ readr::read_delim(.x, show_col_types = FALSE) %>%
                                        mutate(source_file = basename(.x))) %>%
  dplyr::mutate(mode = case_when(
    grepl("hilicneg", source_file) ~ "HILIC_neg",
    grepl("hilicpos", source_file) ~ "HILIC_pos",
    grepl("rpneg", source_file) ~ "RP_neg",
    grepl("rppos", source_file) ~ "RP_pos",
  )) %>%
  dplyr::filter(!is.na(top_recommendation)) %>%
  dplyr::select(feature_ID, mz, rtime,
                   neuMR_ID, ion_csm,
                   top_recommendation_name,
                   mode) %>% 
  dplyr::rename(id = feature_ID,
                lib_id = neuMR_ID,
                lib_name = top_recommendation_name,
                lib_ion = ion_csm) %>%
  dplyr::mutate(source = "CSM_r1_libs_1.6.2")

#### COMBINE

all_ms1_matches <- dplyr::bind_rows(auth_lib_matches,
                                     srm_matches,
                                     csm_annots,
                                     l4_annots) %>%
  dplyr::filter(!lib_name %in% c("nan", "")) %>%
  dplyr::arrange(mode, id)

saveRDS(all_ms1_matches,
        glue::glue("{Sys.Date()}_all_ms1_matches_authlib_l4_csm_srm.RDS"))



  