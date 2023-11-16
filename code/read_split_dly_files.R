#!/usr/bin/env Rscript

library(tidyverse)
#library(archive)
library(glue)
library(lubridate)

tday_julian = yday(today())
window <- 30
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

process_xfiles <- function(x) {

    print(x)

    read_fwf(x,
                fwf_widths(widths, headers),
                na = c("NA", "-9999"),
                col_types =cols(.default=col_character()),
                col_select = c("ID", "YEAR", "MONTH", 
                #"ELEMENT", 
                starts_with("VALUE"))) |>
            rename_all(tolower) |>
            #filter(element == "PRCP") |>
        # select(-element) |>
            pivot_longer(cols = starts_with("value"),
                names_to = "day",
                values_to = "prcp") |>
                #drop_na() |>
                #filter(prcp != 0) |>
                mutate(day = str_replace(day, "value", ""),
                        date = ymd(glue("{year}-{month}-{day}"), quiet=TRUE),
                        prcp = replace_na(prcp, "0"),
                        prcp = as.numeric(prcp)/100) |> #prcp now in cm
                drop_na(date) |>
                select(id, date, prcp) |>
                mutate(julian_day = yday(date),
                        diff = tday_julian - julian_day,
                        is_in_window = case_when((diff < window) & (diff > 0) ~ TRUE,
                                                  diff > window ~ FALSE,
                                                  tday_julian < window & diff + 365 < window ~ TRUE,
                                                  diff < 0 ~ FALSE),
                        year = year(date),
                        year = if_else(diff < 0, year + 1, year)) |>
                filter(is_in_window) |>
                group_by(id, year) |>
                summarize(prcp = sum(prcp), .groups = "drop") #|>
                    # write_tsv("data/composite_dly.tsv")

}

x_files <- list.files("data/temp", full.names=T)

map_dfr(x_files, process_xfiles) |>
group_by(id, year) |>
summarize(prcp = sum(prcp ), .groups = "drop") |>
write_tsv("data/ghcnd_tidy.tsv.gz")