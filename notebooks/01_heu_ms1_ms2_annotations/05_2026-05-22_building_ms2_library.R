library(tidyverse)
library(IRanges)
library(data.table)

setwd("/Volumes/T7/Li Lab/github/2025-08-04_HEU_analysis/MS2_annotation")

all_ms2_annotations <- "/Users/chongj/Desktop/Li_Lab/Projects/HEU/2026-04-01_MS2/2026-05-28_ms2_annotations/2026-05-28_heu_combined_all_MS2_annotations.csv" %>%
  read.csv() %>%
  dplyr::mutate(
    mode = gsub(".*_", "", year_mode),
    mode = gsub("neg", "_neg", mode),
    mode = gsub("pos", "_pos", mode),
  )

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

search_for_features <- function(mz_tolerance_ppm,
                                rt_tolerance,
                                all_ms2_annotations_hp,
                                all_khipu_files_hp){
  
  all_khipu_files_hp <- all_khipu_files_hp %>%
    dplyr::mutate(mz_lower = mz - (mz * mz_tolerance_ppm / 1e6),
                  mz_upper = mz + (mz * mz_tolerance_ppm / 1e6),
                  rt_lower = rtime - rt_tolerance,
                  rt_upper = rtime + rt_tolerance) %>%
    tibble::rowid_to_column(".row")
  
  # Make interval trees
  mz_scale_factor <- 1e6
  mz_ranges <- IRanges(start = as.integer(all_khipu_files_hp$mz_lower * mz_scale_factor), 
                       end = as.integer(all_khipu_files_hp$mz_upper * mz_scale_factor))
  
  rt_scale_factor <- 1e4
  rt_ranges <- IRanges(start = as.integer(all_khipu_files_hp$rt_lower * rt_scale_factor), 
                       end = as.integer(all_khipu_files_hp$rt_upper * rt_scale_factor))
  
  ## query
  all_queries <- all_ms2_annotations_hp %>%
    dplyr::select(exp_spid, 
                  source_file,
                  year_mode,
                  exp_precursor_mz,
                  exp_rtime,
                  mode) %>%
    dplyr::distinct() %>%
    tibble::rowid_to_column(".row")
  
  # build query ranges for ALL queries at once
  query_mz_ranges <- IRanges(start = as.integer(all_queries$exp_precursor_mz * mz_scale_factor), 
                             end   = as.integer(all_queries$exp_precursor_mz * mz_scale_factor))
  
  query_rt_ranges <- IRanges(start = as.integer(all_queries$exp_rtime * rt_scale_factor), 
                             end   = as.integer(all_queries$exp_rtime * rt_scale_factor))
  
  # find ALL overlaps in one call
  mz_hits <- findOverlaps(query_mz_ranges, mz_ranges)
  rt_hits <- findOverlaps(query_rt_ranges, rt_ranges)
  
  # convert to data frames for joining
  mz_df <- data.frame(query_idx = queryHits(mz_hits), khipu_idx = subjectHits(mz_hits))
  rt_df <- data.frame(query_idx = queryHits(rt_hits),  khipu_idx = subjectHits(rt_hits))
  
  # keep only hits that overlap in BOTH mz and rt
  common_hits <- merge(mz_df, rt_df, by = c("query_idx", "khipu_idx"))
  
  # build result
  matches <- all_queries %>%
    dplyr::slice(common_hits$query_idx) %>%
    dplyr::bind_cols(
      all_khipu_files_hp %>%
        dplyr::slice(common_hits$khipu_idx) %>%
        dplyr::select(id, kp_id, mz, rtime, detection_counts, ion_relation)
    )
  
  return(matches)
  
}

anot_dir <- "./ms2_annotations/"
dir.create(anot_dir)

mz_tolerance_ppm <- 10
rt_tolerance <- 30
sim_cutoff <- 0.5

modes <- c("HILIC_neg", "HILIC_pos", "RP_neg", "RP_pos")

for(m in modes){
  
  all_khipu_files_hp <- all_khipu_files %>%
    dplyr::filter(mode == m) 
  
  all_ms2_annotations_hp <- all_ms2_annotations %>%
    dplyr::filter(mode == m)
  
  hp_matches <- search_for_features(mz_tolerance_ppm,
                                    rt_tolerance,
                                    all_ms2_annotations_hp,
                                    all_khipu_files_hp)
  
  # now adding annotations to ms2 spectra via khipu
  hp_matches_by_khipu <- hp_matches %>%
    dplyr::select(kp_id, exp_spid, source_file, year_mode) %>%
    dplyr::distinct() %>%
    dplyr::left_join(., all_ms2_annotations_hp, by = c("exp_spid", "year_mode", "source_file")) %>%
    # expand to features
    dplyr::left_join(., all_khipu_files_hp %>% 
                       dplyr::select(kp_id, mz, rtime, id), by = "kp_id") %>%
    dplyr::distinct()
  
  saveRDS(hp_matches_by_khipu,
          glue::glue("{anot_dir}{Sys.Date()}_{m}_ms2_matches_full.RDS"))
  
  # filter ms2 matches per kpid
  best_annotation_per_kp <- hp_matches_by_khipu %>%
    dplyr::select(-c(mz, rtime, id)) %>%
    dplyr::group_by(kp_id) %>%
    # first filter to similarity cutoffs and second the scores should be similar
    dplyr::filter(cosine_score > sim_cutoff | entropy_score > sim_cutoff) %>%
    # third average scores
    dplyr::mutate(average_score = (cosine_score + entropy_score) / 2) %>%
    dplyr::arrange(desc(average_score)) %>%
    dplyr::slice_head(n = 1) %>%
    dplyr::ungroup() 
  
  cat(nrow(best_annotation_per_kp), "annotated khipus!")
  
  # propagate the ms2 annotations per khipu to per feature 
  hp_matches_kp_filt <- all_khipu_files_hp %>%
    dplyr::select(kp_id, mz, rtime, id) %>%
    dplyr::inner_join(best_annotation_per_kp, by = "kp_id")
  
  write.csv(hp_matches_kp_filt,
            glue::glue("{anot_dir}{Sys.Date()}_{m}_ms2_matches_filtered.csv")) 
}


####

efv <- all_ms2_annotations %>%
  dplyr::filter(db_name == "Efavirenz") %>%
  write.csv("/Volumes/T7/Li Lab/github/2025-08-04_HEU_analysis/MS2_annotation/efv_ms2_info.csv")

