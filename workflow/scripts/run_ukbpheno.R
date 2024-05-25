library(data.table)
library(ukbpheno)
library(tidyverse)

setDTthreads(snakemake@threads)
INPUT <- snakemake@input
# trait_def <- snakemake@input[["trait_definition"]]

# interactive 
# INPUT <- list(
#     fgp_clinical = "resources/gp/gp_clinical.txt",
#     fgp_scripts = "resources/gp/gp_scripts.txt",
#     hesin = "resources/hesin/hesin.txt",
#     hesin_diag = "resources/hesin/hesin_diag.txt",
#     hesin_oper = "resources/hesin/hesin_oper.txt",
#     ukbtab = "resources/main_dataset/ukb_data.tab",
#     html = "resources/main_dataset/ukb_data.html",
#     withdrawals = "resources/misc/ukb_withdrawals.txt",
#     trait_definition = "resources/trait_definitions/caliber.txt"
# )

l.data <- harmonize_ukb_data(
    f.ukbtab = INPUT$ukbtab,
    f.html = INPUT$html,
    f.gp_clinical = INPUT$gp_clinical,
    f.gp_scripts = INPUT$gp_scripts,
    f.hesin = INPUT$hesin,
    f.hesin_diag = INPUT$hesin_diag,
    f.hesin_oper = INPUT$hesin_oper,
    allow_missing_fields = TRUE
    )

withdrawals <- fread(INPUT$withdrawals)$V1
df_reference_dt_v0 <- l.data$dfukb[!identifier %in% withdrawals, c("identifier","f.53.0.0")]

f.data_settings <- system.file("extdata", "data.settings.tsv", package="ukbpheno")
df.data_settings <- fread(f.data_settings)

df.definition <- read_definition_table(
    INPUT$trait_definition,
    f.data_settings,
    dir.code.map = system.file("extdata", package="ukbpheno")
)

make_df_case <- function(trait) {
    print(trait)
    get_cases_controls(
        df.definition[df.definition$TRAIT == trait,],
        l.data$lst.data,
        df.data_settings,
        df_reference_date = df_reference_dt_v0
    )$all_event_dt.Include_in_cases.summary
}

traits <- df.definition$TRAIT
names(traits) <- traits

df_res <- rbindlist(lapply(traits, make_df_case), idcol = "pheno")

fwrite(df_res, snakemake@output[[1]], sep = "\t")
