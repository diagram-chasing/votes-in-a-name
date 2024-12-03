library(tidyverse)
library(scales)
library(jsonlite)


dummies <- read_csv("./copycat_candidates_full.csv")
elections <- read_csv("./TCPD.csv") %>%
  filter(Election_Type %in% c("Lok Sabha Election (GE)", "State Assembly Election (AE)")) %>% 
  group_by(Year, State_Name) %>%
  mutate(Election_ID = cur_group_id()) %>%
  ungroup() 
  

### Where do the algorithms agree and disagree?
similarity_long <- dummies %>%
  filter(Weighted_Similarity > 0.70) %>% 
  select(State_Name, 
         Ref_Candidate,
         Dummy_Candidate, 
         Dummy_Party,
         Ref_Party,
         Similarity_BiSim, 
         Similarity_JW, 
         Similarity_Dice) %>%
  group_by(State_Name) %>% 
  mutate(n_cases = n()) %>%
  ungroup() %>%
  group_by(State_Name, Ref_Candidate, Dummy_Candidate ) %>%
  ungroup() %>%
  filter(n_cases >= 30) %>%
  pivot_longer(
    cols = starts_with("Similarity"),
    names_to = "algorithm",
    values_to = "score"
  ) %>%
  mutate(
    algorithm = str_remove(algorithm, "Similarity_"),
    algorithm = case_when(
      algorithm == "BiSim" ~ "Bi-gram Similarity",
      algorithm == "JW" ~ "Jaro-Winkler",
      algorithm == "Dice" ~ "Dice Coefficient"
    )
  ) %>%
  mutate(State_Name = as.factor(State_Name),
         State_Name = fct_reorder(State_Name, n_cases ))


optimized_similarity <-  similarity_long %>%
  group_by(State_Name, algorithm) %>%
  summarise(
    points = list(
      tibble(
        ref = Ref_Candidate,
        dummy = Dummy_Candidate,
        dummyParty = Dummy_Party,
        refParty = Ref_Party,
        score = score
      ) %>%
        arrange(score) 
    ),
    n_cases = n(),
    .groups = 'drop'
  ) %>%
  arrange(desc(n_cases))


jsonlite::write_json(
  optimized_similarity,
  "similarity_by_state.json",
  auto_unbox = TRUE
)


ggplot() +
  geom_segment(data = similarity_long,
               aes(x = score,
                   xend = score,
                   y = reorder(State_Name, n_cases),
                   yend = as.numeric(reorder(State_Name, n_cases)) + 0.8,
                   color = algorithm),
               alpha = 0.4,
               size = 0.3) +
  geom_text(data = similarity_long %>% 
              distinct(State_Name,  n_cases),
            aes(x = 0.25,
                y = State_Name,
                label = paste0("n=", n_cases)),
            hjust = 1,
            size = 2.5) +
  scale_color_brewer(palette = "Set2") +
  scale_x_continuous(limits = c(0.5, 1)) +
  theme_minimal() +
  labs(
    title = "Algorithm Disagreement in Detecting Similar Names",
    subtitle = str_wrap("Individual similarity scores by algorithm (lines) and mean disagreement between algorithms (red dots). States ordered by average disagreement.", 100),
    x = "Similarity Score",
    y = NULL,
    color = "Algorithm"
  ) +
  theme(
    legend.position = "top",
    panel.grid.major.y = element_blank(),
    plot.title.position = "plot",
    axis.text = element_text(size = 8)
  )

### Name changes and structure
name_changes <- dummies %>%
  mutate(
    ref_parts = str_split(Ref_Candidate, "\\s+"),
    dummy_parts = str_split(Dummy_Candidate, "\\s+"),
    ref_has_title = str_detect(Ref_Candidate, "^(Sri|Shri|Dr\\.|Mr\\.|Mrs\\.|Ms\\.)"),
    dummy_has_title = str_detect(Dummy_Candidate, "^(Sri|Shri|Dr\\.|Mr\\.|Mrs\\.|Ms\\.)"),
    change_pattern = case_when(
      str_detect(Dummy_Candidate, "^[A-Z](\\.[A-Z])*\\.?$") ~ "Full_To_Initials",
      str_count(Dummy_Candidate, "[A-Z]\\.") > str_count(Ref_Candidate, "[A-Z]\\.") ~ "Added_Initials",
      str_count(Dummy_Candidate, "[A-Z]\\.") < str_count(Ref_Candidate, "[A-Z]\\.") ~ "Removed_Initials",
      map2_lgl(ref_parts, dummy_parts, ~length(.x) > length(.y)) ~ "Component_Removal",
      map2_lgl(ref_parts, dummy_parts, ~length(.x) < length(.y)) ~ "Component_Addition",
      (!ref_has_title & dummy_has_title) ~ "Added_Title",
      (ref_has_title & !dummy_has_title) ~ "Removed_Title",
      map2_lgl(ref_parts, dummy_parts, ~length(.x) > 2 && length(.y) > 2 && 
                 paste(.x[2:(length(.x)-1)], collapse=" ") != paste(.y[2:(length(.y)-1)], collapse=" ")) ~ "Middle_Name_Modified",
      map2_lgl(ref_parts, dummy_parts, ~.x[1] != .y[1] && .x[length(.x)] == .y[length(.y)]) ~ "First_Name_Only",
      map2_lgl(ref_parts, dummy_parts, ~.x[1] == .y[1] && .x[length(.x)] != .y[length(.y)]) ~ "Last_Name_Only",
      map2_lgl(ref_parts, dummy_parts, ~.x[1] != .y[1] && .x[length(.x)] != .y[length(.y)]) ~ "Both_Names_Changed",
      TRUE ~ "Other_Modification"
    ),
    decade = (Year %/% 10) * 10,
    vote_effectiveness = Dummy_Votes/Ref_Votes,
    similarity_color = scales::rescale(Weighted_Similarity, to = c(0, 1))
  ) %>%
  select(
    Ref_Candidate, Dummy_Candidate, 
    change_pattern, State_Name, Year, decade,
    vote_effectiveness, Dummy_Vote_Share, Ref_Vote_Share,
    Weighted_Similarity, similarity_color,
    Confidence_Score
  )


write_csv(name_changes, "name_changes_viz.csv")



###### MODELLING ########
library(tidyverse)
library(boot)
library(tidyverse)

# Fixed simulation function that takes individual parameters
simulate_vote_transfer <- function(dummy_votes, similarity, transfer_rate) {
  # Ensure dummy_votes is an integer
  dummy_votes <- as.integer(dummy_votes)
  
  # Calculate transferred votes using similarity score as a weight
  transferred_votes <- rbinom(
    n = 1, 
    size = dummy_votes,
    prob = min(transfer_rate * similarity, 1)  # Ensure probability doesn't exceed 1
  )
  
  return(transferred_votes)
}

# Prepare data for simulation
simulation_data <- dummies %>%
  left_join(
    elections %>%
      group_by(State_Name, Constituency_Name, Year) %>%
      arrange(desc(Votes)) %>%
      slice(1) %>%
      select(State_Name, Constituency_Name, Year, Winner_Votes = Votes),
    by = c("State_Name", "Constituency_Name", "Year")
  ) %>%
  # Filter for cases where reference candidate didn't win
  filter(Ref_Votes < Winner_Votes, Ref_Party != "IND") %>%
  # Calculate original margin
  mutate(Original_Margin = Winner_Votes - Ref_Votes)

# Run simulations
set.seed(123)  # for reproducibility
transfer_rates <- seq(0.3, 0.9, by = 0.1)
n_sims <- 400

simulation_results <- crossing(
  simulation_data,
  transfer_rate = transfer_rates,
  sim_number = 1:n_sims
) %>%
  mutate(
    Transferred_Votes = mapply(
      simulate_vote_transfer,
      dummy_votes = Dummy_Votes,
      similarity = Weighted_Similarity,
      transfer_rate = transfer_rate
    ),
    Simulated_Votes = Ref_Votes + Transferred_Votes,
    Would_Win = Simulated_Votes > Winner_Votes
  )

# Analyze results
summary_results <- simulation_results %>%
  group_by(State_Name, Constituency_Name, Year, transfer_rate, Winner_Votes) %>%
  summarize(
    Win_Probability = mean(Would_Win),
    Avg_Vote_Transfer = mean(Transferred_Votes),
    Avg_Final_Votes = mean(Simulated_Votes),
    CI_Lower = quantile(Simulated_Votes, 0.025),
    CI_Upper = quantile(Simulated_Votes, 0.975),
    Original_Margin = first(Original_Margin),
    Dummy_Votes = first(Dummy_Votes),
    Similarity = first(Weighted_Similarity),
    .groups = 'drop'
  ) %>%
  # Calculate impact metrics
  mutate(
    Margin_Reduction = (Original_Margin - (Winner_Votes - Avg_Final_Votes)) / Original_Margin,
    Risk_Level = case_when(
      Win_Probability > 0.5 ~ "High Risk",
      Win_Probability > 0.25 ~ "Medium Risk",
      Win_Probability > 0.1 ~ "Low Risk",
      TRUE ~ "Minimal Risk"
    )
  ) %>%
  arrange(desc(Win_Probability))

# Identify critical cases
critical_cases <- summary_results %>%
  filter(Dummy_Votes < 10000) %>% 
  filter(transfer_rate == 0.7) %>%  # Using 70% as baseline transfer rate
  filter(Win_Probability > 0.1) %>%  # Focus on cases with >10% flip probability
  # Join back with dummies to get candidate pairs
  left_join(
    dummies %>% 
      select(State_Name, Constituency_Name, Year, Ref_Votes,
             Ref_Candidate, Ref_Party, Dummy_Candidate, Dummy_Party),
    by = c("State_Name", "Constituency_Name", "Year")
  ) %>%
  # Join with elections to get election type
  left_join(
    elections %>% 
      distinct(State_Name, Constituency_Name, Year, Election_Type),
    by = c("State_Name", "Constituency_Name", "Year")
  ) %>%
  mutate(
    # Create a more readable format for the candidate-dummy relationship
    Candidate_Pair = str_glue("{Ref_Candidate} ({Ref_Party}) → {Dummy_Candidate} ({Dummy_Party})"),
    # Format probabilities and percentages for readability
    Win_Probability = scales::percent(Win_Probability, accuracy = 0.1),
    Margin_Reduction = scales::percent(Margin_Reduction, accuracy = 0.1)
  ) %>%
  filter(Dummy_Party == "IND", Dummy_Votes > Original_Margin, Year > 2000) %>% 
  arrange(Original_Margin) %>%
  select(
    State_Name, Constituency_Name, Year, Election_Type, 
    Ref_Candidate, Ref_Votes, Dummy_Candidate, Dummy_Votes, Similarity, Original_Margin, 
    Win_Probability
  ) %>% 
  group_by(State_Name, Ref_Candidate, Constituency_Name, Year) %>%
  # Keep only the first instance of each election
  slice(1)

jsonlite::write_json(critical_cases, "./critical_cases.json")

library(tidyverse)
library(gt)
library(jsonlite)

# Read and process the data
elections_data <- fromJSON(txt = "critical_cases.json") %>%
  as_tibble() %>%
  # Create a combined label for election info
  mutate(
    Location = paste0(
      State_Name, " - ", 
      Constituency_Name
    ),
    Election_Type = str_extract(Election_Type, "^[^(]+"),
    # Separate reference and dummy candidates
    Reference_Candidate = Ref_Candidate,
    Dummy_Candidate = Dummy_Candidate,
    Vote_Counts = paste0(
      format(Ref_Votes, big.mark = ","), " / ",
      format(Dummy_Votes, big.mark = ",")
    )
  ) %>%
  # Select and rename columns for clarity
  select(
    Year,
    Location,
    Election_Type,
    Reference_Candidate,
    Dummy_Candidate,
    Vote_Counts,
    Original_Margin,
    Similarity,
    Win_Probability
  ) %>%
  # Sort by Original_Margin
  arrange(Original_Margin) %>% 
  distinct()

# Create custom theme colors
theme_colors <- list(
  header_bg = "#1f4257",
  header_text = "white",
  row_striping = "#f7f9fb",
  highlight = "#ffebee"
)

# Create the GT table
elections_table <- elections_data %>%
  gt() %>%
  # Format columns
  fmt_number(
    columns = Original_Margin,
    decimals = 0,
    use_seps = TRUE
  ) %>%
  fmt_percent(
    columns = Similarity,
    decimals = 1
  ) %>%
  # Column headers
  cols_label(
    Year = "Year",
    Location = "Location",
    Election_Type = "Election",
    Reference_Candidate = "Reference Candidate",
    Dummy_Candidate = "Similar Candidate",
    Vote_Counts = "Votes (Ref/Similar)",
    Original_Margin = "Margin",
    Similarity = "Name Similarity",
    Win_Probability = "Win Probability"
  ) %>%
  # Apply theme
  tab_header(
    title = md("**Critical Election Cases Analysis**"),
    subtitle = "Cases with similar candidate names and close margins"
  ) %>%
  tab_style(
    style = cell_text(
      color = theme_colors$header_text,
      weight = "bold"
    ),
    locations = cells_column_labels()
  ) %>%
  tab_style(
    style = cell_fill(
      color = theme_colors$header_bg
    ),
    locations = cells_column_labels()
  ) %>%
  # Add row striping
  tab_style(
    style = cell_fill(
      color = theme_colors$row_striping
    ),
    locations = cells_body(
      rows = seq(1, nrow(elections_data), 2)
    )
  ) %>%
  # Highlight extremely close margins
  tab_style(
    style = cell_fill(
      color = theme_colors$highlight
    ),
    locations = cells_body(
      columns = Original_Margin,
      rows = Original_Margin < 100
    )
  ) %>%
  # Add borders
  tab_style(
    style = cell_borders(
      sides = "bottom",
      color = "#ddd",
      weight = px(1)
    ),
    locations = cells_body()
  ) %>%
  # Set column widths
  cols_width(
    Location ~ px(150),
    Reference_Candidate ~ px(150),
    Dummy_Candidate ~ px(150),
    Vote_Counts ~ px(130),
    Election_Type ~ px(120),
    Year ~ px(70),
    everything() ~ px(100)
  ) %>%
  # Add source note
  tab_source_note(
    source_note = md("*Note: Name similarity calculated using string matching algorithms*")
  ) %>%
  # Add footnote about highlighting
  tab_footnote(
    footnote = "Highlighted margins indicate extremely close races (< 100 votes)",
    locations = cells_column_labels(
      columns = Original_Margin
    )
  )

# Histogram of vote shares
vote_share_plot <- dummies %>%
  ggplot(aes(x = Dummy_Vote_Share * 100)) +
  geom_histogram(binwidth = 0.3, fill = "#2c3e50", alpha = 0.8) +
  geom_vline(xintercept = median(dummies$Dummy_Vote_Share * 100), 
             color = "#e74c3c", linetype = "dashed") +
  scale_x_continuous(labels = scales::label_percent(scale = 1)) +
  labs(x = "Vote Share (%)", 
       y = "Number of Namesake Candidates",
       title = "Most namesake candidates barely make a dent",
       subtitle = "Distribution of vote shares for suspected namesake candidates") +
  theme_minimal() +
  theme(
    plot.title.position = "plot",
    plot.title = element_text(face = "bold", size = 16),
    plot.subtitle = element_text(color = "grey40", size = 12)
  )

# 1. Vote Share Distribution Data
vote_share_data <- dummies %>%
  mutate(vote_share_percent = Dummy_Vote_Share * 100) %>%
  summarise(
    bins = list(hist(vote_share_percent, breaks = seq(0, max(vote_share_percent) + 0.5, by = 0.5), 
                     plot = FALSE)),
    median = median(vote_share_percent)
  ) %>%
  transmute(
    histogram = list(tibble(
      bin_start = bins[[1]]$breaks[-length(bins[[1]]$breaks)],
      bin_end = bins[[1]]$breaks[-1],
      count = bins[[1]]$counts
    )),
    median = median
  ) %>%
  unnest(histogram) %>%
  select(-median) %>%
  mutate(
    bin_middle = (bin_start + bin_end) / 2
  ) %>%
  toJSON(pretty = TRUE)

write(vote_share_data, "vote_share_distribution.json")

# Party analysis - who faces the most namesakes?
party_namesakes <-dummies %>%
  group_by(Ref_Party) %>%
  summarize(
    namesake_count = n(),
    avg_vote_share = mean(Dummy_Vote_Share),
    total_impact = namesake_count * avg_vote_share
  ) %>%
  # Filter to have enough cases for meaningful analysis
  filter(namesake_count >= 10) %>%
  arrange(desc(total_impact))

viz_data <- party_namesakes %>%
  # Calculate total impact (namesakes × vote share)
  mutate(
    total_impact = namesake_count * avg_vote_share,
    # Create a category for the relationship between count and share
    strategy_type = case_when(
      namesake_count > median(namesake_count) & avg_vote_share > median(avg_vote_share) ~ "High Count, High Impact",
      namesake_count > median(namesake_count) & avg_vote_share <= median(avg_vote_share) ~ "High Count, Low Impact",
      namesake_count <= median(namesake_count) & avg_vote_share > median(avg_vote_share) ~ "Low Count, High Impact",
      TRUE ~ "Low Count, Low Impact"
    )
  ) %>%
  # Get top 15 parties by total impact
  slice_max(total_impact, n = 15)

# Create the visualization
ggplot(viz_data, aes(x = namesake_count, y = avg_vote_share)) +
  # Create segments from origin to each point
  geom_segment(aes(x = 0, y = 0, xend = namesake_count, yend = avg_vote_share, 
                   color = strategy_type), 
               alpha = 0.6) +
  # Add points
  geom_point(aes(size = total_impact, color = strategy_type)) +
  # Add party labels
  geom_text_repel(aes(label = Ref_Party), 
                  size = 3.5, 
                  fontface = "bold",
                  box.padding = 0.5) +
  # Custom theming
  scale_color_manual(values = c("High Count, High Impact" = "#FF4E50",
                                "High Count, Low Impact" = "#FC913A",
                                "Low Count, High Impact" = "#4A4E4D",
                                "Low Count, Low Impact" = "#8EA4D2")) +
  scale_size_continuous(range = c(3, 10)) +
  # Use sqrt scale for better distribution visualization
  scale_x_sqrt() +
  scale_y_sqrt() +
  # Custom theme
  theme_minimal() +
  theme(
    plot.title = element_text(size = 16, face = "bold"),
    plot.subtitle = element_text(size = 12),
    legend.position = "bottom",
    legend.title = element_blank(),
    panel.grid.minor = element_blank()
  ) +
  # Labels
  labs(
    title = "The Namesake Strategy in Indian Elections",
    subtitle = "How different parties experience dummy candidate phenomena",
    x = "Number of Namesake Candidates",
    y = "Average Vote Share per Namesake",
    caption = "Larger circles indicate higher total vote impact"
  )

json_data <- party_namesakes %>%
  mutate(
    total_impact = namesake_count * avg_vote_share,
    strategy_type = case_when(
      namesake_count > median(namesake_count) & avg_vote_share > median(avg_vote_share) ~ "High Count, High Impact",
      namesake_count > median(namesake_count) & avg_vote_share <= median(avg_vote_share) ~ "High Count, Low Impact",
      namesake_count <= median(namesake_count) & avg_vote_share > median(avg_vote_share) ~ "Low Count, High Impact",
      TRUE ~ "Low Count, Low Impact"
    )
  ) %>%
  filter(Ref_Party != "IND") %>% 
  slice_max(total_impact, n = 15) %>%
  # Rename columns to be more JS-friendly
  rename(
    party = Ref_Party,
    count = namesake_count,
    voteShare = avg_vote_share
  ) %>%
  # Convert to JSON format
  jsonlite::toJSON(pretty = TRUE)

# Write to file
writeLines(json_data, "namesake_by_party_data.json")


