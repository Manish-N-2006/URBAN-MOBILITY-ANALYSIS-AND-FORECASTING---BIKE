# scratch/inspect_zones.R
df <- read.csv("data/raw/rapido_rides.csv", stringsAsFactors = FALSE)
cat("Sample of 30 source locations:\n")
sample_src <- head(unique(df$source), 30)
print(sample_src)

# Check last word of source
last_word <- sub(".* ", "", df$source)
cat("\nTop 20 last words in source:\n")
print(head(sort(table(last_word), decreasing = TRUE), 20))

# Try removing the last token to see what base names look like
base_name <- sub(" [^ ]+$", "", df$source)
cat("\nTop 20 base names:\n")
print(head(sort(table(base_name), decreasing = TRUE), 20))
cat("\nDistinct base names count:", length(unique(base_name)), "\n")
