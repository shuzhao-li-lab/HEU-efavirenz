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

all_ms2_matches <- list.files("/Volumes/T7/Li Lab/github/2025-08-04_HEU_analysis/MS2_annotation/ms2_annotations/",
                              pattern = "^2026-05-28.*\\.csv$",
                              full.names = TRUE) %>%
  map_dfr(~ readr::read_delim(.x, show_col_types = FALSE)) %>%
  dplyr::mutate(anot_level = "L2") 

combined_matches <- dplyr::bind_rows(all_ms1_matches %>% dplyr::select(id, lib_id, lib_name, mode, source, anot_level, mz, rtime),
                                 all_ms2_matches %>% 
                                   dplyr::select(id, db_id, db_name, mode, db, anot_level, mz, rtime) %>% 
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
          
write.csv(combined_matches_filt,
          glue::glue("{Sys.Date()}_combined_heu_annotations_authlib_csm_srm_l2_l4.csv"))
