library(tidyverse)

setwd("/Volumes/T7/Li Lab/github/2025-08-04_HEU_analysis/combining_ms1_ms2_annotations")

all_ms1_matches <- readRDS("/Volumes/T7/Li Lab/github/2025-08-04_HEU_analysis/MS1_annotation/2026-05-28_all_ms1_matches_authlib_l4_csm_srm.RDS") %>%
  dplyr::mutate(
    anot_level = case_when(
      source == "v3_authlib2024" ~ "L1",
      source == "srm1950lib_v1" ~ "SRM",
      source %in% c("HMDBv5", "LMSD") ~ "L4",
      source == "CSM_r1_libs_1.6.2" ~ "CSM"
    )
  )

# 3408 features with preliminary cutoffs
# 2595 features with cosine > 0.7
all_ms2_matches <- list.files("/Volumes/T7/Li Lab/github/2025-08-04_HEU_analysis/MS2_annotation/ms2_annotations/",
                              pattern = "^2026-05-28.*\\.csv$",
                              full.names = TRUE) %>%
  map_dfr(~ readr::read_delim(.x, show_col_types = FALSE)) %>%
  dplyr::mutate(anot_level = "L2") %>%
  dplyr::filter(cosine_score >= 0.7) %>%
  dplyr::mutate(db = ifelse(db == "MS Dial", "Combined MS/MS DB", "MoNA"))

combined_matches <- dplyr::bind_rows(all_ms1_matches %>% dplyr::select(id, lib_id, lib_name, mode, source, anot_level, mz, rtime),
                                 all_ms2_matches %>% 
                                   dplyr::select(id, db_id, db_name, mode, db, anot_level, mz, rtime, cosine_score) %>% 
                                   dplyr::rename(lib_id = db_id,
                                                 lib_name = db_name,
                                                 source = db)) %>%
  dplyr::mutate(anot_level = factor(anot_level,
                                    levels = c("L1", "L2", "CSM", "SRM", "L4"),
                                    ordered = TRUE))

combined_matches_filt <- combined_matches %>%
  dplyr::group_by(mode, id) %>%
  dplyr::arrange(anot_level) %>%
  dplyr::slice_head(n = 1) %>% 
  dplyr::ungroup() %>%
  dplyr::distinct()
          
# sparse for use in analysis
write.csv(combined_matches_filt,
          glue::glue("{Sys.Date()}_combined_heu_annotations_authlib_csm_srm_l2_l4.csv"))

# per annotation level for publication
all_khipu_files <- list.files("/Volumes/T7/Li Lab/Projects/HEU/OLD/2025-12-14_HEU_Metabolomics_V3/heu_data/12_03_2025_empirical_compounds/",
                              full.names = TRUE) %>%
  map_dfr(~ readr::read_delim(.x, show_col_types = FALSE) %>% 
            mutate(source_file = basename(.x))) %>%
  dplyr::mutate(mode = case_when(
    grepl("HILIC_neg", source_file) ~ "HILIC_neg",
    grepl("HILIC_pos", source_file) ~ "HILIC_pos",
    grepl("RP_neg", source_file) ~ "RP_neg",
    grepl("RP_pos", source_file) ~ "RP_pos",
  ))

l1l2_annots <- combined_matches_filt %>%
  dplyr::filter(anot_level %in% c("L1", "L2")) %>%
  select(id, mz, rtime, mode,
         lib_id, lib_name, cosine_score,
         anot_level,  source) %>%
  dplyr::arrange(anot_level)

write.csv(l1l2_annots,
          glue::glue("{Sys.Date()}_l1_l2_annotations_heu.csv"))

csm_annots <- combined_matches_filt %>%
  dplyr::filter(source == "CSM_r1_libs_1.6.2") %>%
  dplyr::left_join(., all_ms1_matches %>% dplyr::select(-c(lib_mz, lib_rtime, lib_isotope, lib_identifier))) %>%
  dplyr::select(id, mz, rtime, mode,
                lib_id, lib_name, lib_ion,
                anot_level,  source)

write.csv(csm_annots,
          glue::glue("{Sys.Date()}_csm_annotations_heu.csv"))

l4_annots <- combined_matches_filt %>%
  dplyr::filter(anot_level == "L4") %>%
  dplyr::select(-c(mz, rtime, cosine_score)) %>%
  dplyr::left_join(., all_khipu_files %>% select(id, mz, rtime, mode)) %>%
  dplyr::select(id, mz, rtime, mode,
                lib_id, lib_name, 
                anot_level,  source)

write.csv(l4_annots,
          glue::glue("{Sys.Date()}_l4_annotations_heu.csv"))


