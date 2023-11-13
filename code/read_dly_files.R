library(tidyverse)
library(archive)
library(glue)

quadruple <- function(x){

    c(glue("VALUE{x}"), glue("MFLAG{x}"), glue("QFLAG{x}"), glue("SFLAG{x}"))
    
}

#dly_files <- archive("data/ghcnd_all.tar.gz") |>
#    filter(str_detect(path, ".dly")) |>
#    slice_sample(n = 5) |>
#    pull(path) 
#head(dly_files)
#list.files("data/ghcnd_all", full.names = TRUE)

widths <- c(11, 4, 2, 4, rep(c(5,1,1,1), 31))
headers <- c("ID", "YEAR", "MONTH", "ELEMENT",  unlist(map(1:31, quadruple)))

read_fwf("data/ghcnd_cat.gz",
            fwf_widths(widths, headers),
            na = c("NA", "-9999"),
            col_types =cols(.default=col_character()),
            col_select = c("ID", "YEAR", "MONTH", "ELEMENT", starts_with("VALUE"))) 
            |>
        rename_all(tolower) |>
        filter(element == "PRCP") |>
        select(-element) |>
        pivot_longer(cols = starts_with("value"),
            names_to = "day",
            values_to = "prcp") |>
            drop_na() |>
            mutate(day = str_replace(day, "value", ""),
                    date = ymd(glue("{year}-{month}-{day}")),
                    prcp_cm = as.numeric(prcp)/100) |>
                    select(id, date, prcp_cm) |>
                    write_tsv("data/composite_dly.tsv")





