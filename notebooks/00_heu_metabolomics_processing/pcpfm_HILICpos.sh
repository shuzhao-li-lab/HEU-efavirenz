# HILICpos

pcpfm assemble -s 'HILICpos_pcpfm_metadata.csv' -o . -j HEU_08_06_2024_HILICpos
pcpfm asari -i HEU_08_06_2024_HILICpos

pcpfm blank_masking --table_moniker preferred --new_moniker preferred_blank_masked1 --blank_value Solvent_Blank --sample_value Unknown --query_field "Sample Type" --blank_intensity_ratio 3 -i HEU_08_06_2024_HILICpos 
pcpfm blank_masking --table_moniker preferred_blank_masked1 --new_moniker preferred_blank_masked2 --blank_value Blank_IS --sample_value Unknown --query_field "Sample Type" --blank_intensity_ratio 3 -i HEU_08_06_2024_HILICpos     
pcpfm blank_masking --table_moniker preferred_blank_masked2 --new_moniker preferred_blank_masked3 --blank_value Process_Blank --sample_value Unknown --query_field "Sample Type" --blank_intensity_ratio 3 -i HEU_08_06_2024_HILICpos     
pcpfm drop_samples  --table_moniker preferred_blank_masked3 --new_moniker dropping --drop_value Unknown --drop_field "Sample Type" --drop_others true -i HEU_08_06_2024_HILICpos 

pcpfm drop_outliers --table_moniker dropping --new_moniker dropping --auto_drop autodrop.json -i HEU_08_06_2024_HILICpos
pcpfm drop_outliers --table_moniker dropping --new_moniker dropping --auto_drop autodrop.json -i HEU_08_06_2024_HILICpos

pcpfm normalize --table_moniker dropping --new_moniker pref_normalized --TIC_normalization_percentile 0.90 -i HEU_08_06_2024_HILICpos 
pcpfm drop_missing_features --table_moniker pref_normalized --new_moniker pref_missing_dropped --feature_retention_percentile .10  -i HEU_08_06_2024_HILICpos 
pcpfm impute --table_moniker pref_missing_dropped --new_moniker pref_interpolated -i HEU_08_06_2024_HILICpos     
pcpfm log_transform --table_moniker pref_interpolated --new_moniker log_transformed_for_analysis -i HEU_08_06_2024_HILICpos
pcpfm batch_correct --by_batch Batch --table_moniker log_transformed_for_analysis --new_moniker batch_corr -i HEU_08_06_2024_HILICpos
pcpfm report -i HEU_08_06_2024_HILICpos --color_by='["Batch", "Sample Type"]' --marker_by='["Sample Type"]'
