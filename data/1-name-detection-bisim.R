library(tidyverse)
library(stringdist)


tcpd_data <- read_csv("./TCPD.csv") %>%
  group_by(Year, State_Name) %>%
  mutate(Election_ID = cur_group_id()) %>%
  ungroup() %>% 
  filter(Election_Type %in% c("Lok Sabha Election (GE)", "State Assembly Election (AE)"))

calculateBiSim <- function(X, Y) {
  # Add prefix following paper specs - duplicates first letter and capitalizes it
  # e.g., "word" becomes "Wword"
  X <- paste0(toupper(substr(X, 1, 1)), substr(X, 1, 1), substr(X, 2, nchar(X)))
  Y <- paste0(toupper(substr(Y, 1, 1)), substr(Y, 1, 1), substr(Y, 2, nchar(Y)))
  
  m <- nchar(X)
  n <- nchar(Y)
  offset <- 1  # bigram requires looking at previous character
  
  # Initialize dynamic programming array for LCS computation
  S <- rep(0, n - offset)
  
  # Split strings into character vectors for easier indexing
  X_chars <- strsplit(X, "")[[1]]
  Y_chars <- strsplit(Y, "")[[1]]
  
  # Main dynamic programming loop for bigram LCS
  for(i in 2:(m - offset)) {
    prev <- 0  # Store previous diagonal value
    
    for(j in 2:(n - offset)) {
      curr <- S[j-1]
      
      # Check both current and previous character matches for bigram
      # Each match contributes 0.5 to the total score (hence ident/2 below)
      curr_match <- tolower(X_chars[i]) == tolower(Y_chars[j])
      prev_match <- tolower(X_chars[i-1]) == tolower(Y_chars[j-1])
      ident <- curr_match + prev_match
      
      # Calculate score from diagonal + current bigram match
      diag <- prev + ident/2
      
      # Update score matrix - take max of:
      # 1. diagonal + current bigram match
      # 2. score from cell above
      # 3. score from cell to the left
      if(diag > curr) {
        if(diag > S[max(1, j-2)]) {
          S[j-1] <- diag
        } else {
          S[j-1] <- S[max(1, j-2)]
        }
      } else {
        if(curr > S[max(1, j-2)]) {
          S[j-1] <- curr
        } else {
          S[j-1] <- S[max(1, j-2)]
        }
      }
      prev <- curr  # Save current value for next iteration's diagonal
    }
  }
  
  # Normalize by longer length (minus 1 for bigram comparison)
  # Paper shows this normalization gives better results for cognate detection
  score <- S[n - offset - 1]
  return(score / (max(m, n) - 1))
}

# Add Dice Coefficient (DC) calculation
calculateDC <- function(str1, str2) {
  # Convert to bigrams
  getBigrams <- function(str) {
    chars <- strsplit(str, "")[[1]]
    if(length(chars) < 2) return(chars)
    sapply(1:(length(chars)-1), function(i) paste0(chars[i], chars[i+1]))
  }
  
  bigrams1 <- getBigrams(tolower(str1))
  bigrams2 <- getBigrams(tolower(str2))
  
  # Calculate intersection and union
  intersection <- length(intersect(bigrams1, bigrams2))
  total <- length(bigrams1) + length(bigrams2)
  
  # Return Dice coefficient
  return((2 * intersection) / total)
}


# First, improve name cleaning
clean_name <- function(name) {
  name %>%
    # Basic cleaning from before
    str_replace_all("Dr\\.|Col\\.|Adv\\.|ADV\\.", "") %>%
    str_replace_all("\\sS/o.*$|\\sW/o.*$|\\sD/o.*$|\\sC/o.*$", "") %>%
    str_replace_all("\\([^)]*\\)|\\[[^]]*\\]|'[^']*'|\"[^\"]*\"", "") %>%
    # New cleaning steps
    str_replace_all("\\.\\s*", " ") %>%  # Handle dots in initials
    str_replace_all("\\s+", " ") %>%     # Multiple spaces
    str_trim() %>%
    tolower()
}

identify_major_parties <- function(data, min_vote_share = 0.03, min_elections = 2) {
  state_major_parties <- data %>%
    filter(Party != "IND") %>% 
    # Calculate party strength metrics by state
    group_by(State_Name, Party, Year) %>%
    summarize(
      Total_Votes = sum(Votes),
      Total_Seats_Contested = n(),
      .groups = "drop"
    ) %>%
    # Join with total votes per state-year
    left_join(
      data %>%
        group_by(State_Name, Year) %>%
        summarize(State_Total_Votes = sum(Votes),
                  .groups = "drop"),
      by = c("State_Name", "Year")
    ) %>%
    # Calculate vote share and presence metrics
    group_by(State_Name, Party) %>%
    summarize(
      Avg_Vote_Share = mean(Total_Votes / State_Total_Votes),
      Elections_Contested = n_distinct(Year),
      Total_Candidates = sum(Total_Seats_Contested),
      .groups = "drop"
    ) %>%
    # Filter for significant parties
    filter(
      Avg_Vote_Share >= min_vote_share | 
        Elections_Contested >= min_elections
    ) %>%
    # Create a ranked list by state
    group_by(State_Name) %>%
    arrange(State_Name, desc(Avg_Vote_Share)) %>%
    mutate(
      Party_Rank = row_number(),
      Is_Major = Avg_Vote_Share >= min_vote_share | 
        Elections_Contested >= min_elections
    )
  
  return(state_major_parties)
}

# Calculate weighted similarity score
calculate_similarity <- function(name1, name2) {
  # Get individual scores
  bisim <- calculateBiSim(name1, name2)
  jw <- stringsim(name1, name2, method = "jw")
  dice <- calculateDC(name1, name2)
  
  # Weight calculation based on name characteristics
  name_length_ratio <- min(nchar(name1), nchar(name2)) / max(nchar(name1), nchar(name2))
  
  # Adjust weights based on name characteristics
  weights <- c(
    bisim = 0.5,  # Better for longer names
    jw = 0.3,     # Better for shorter names
    dice = 0.2    # Used as validation
  )
  
  # If names are very different in length, trust Jaro-Winkler less
  if (name_length_ratio < 0.7) {
    weights["jw"] <- 0.5
    weights["bisim"] <- 0.3
  }
  
  # Calculate weighted score
  weighted_score <- (bisim * weights["bisim"] + 
                       jw * weights["jw"] + 
                       dice * weights["dice"])
  
  # Calculate disagreement penalty
  max_diff <- max(abs(bisim - jw), abs(bisim - dice), abs(jw - dice))
  disagreement_penalty <- max_diff * 0.1  # 10% penalty for maximum disagreement
  
  list(
    final_score = weighted_score - disagreement_penalty,
    individual_scores = c(bisim = bisim, jw = jw, dice = dice),
    weights = weights,
    penalty = disagreement_penalty
  )
}

detect_dummy_candidates <- function(data, 
                                           similarity_threshold = 0.75,
                                           vote_share_threshold = 0.01,  # 1% of total votes
                                    national_parties = c("BJP", "INC", "BSP", "CPI", "CPM")) {
  
  state_parties <- identify_major_parties(data)
  
  # Create combined list of major parties (national + regional)
  major_parties <- unique(c(
    national_parties,
    state_parties %>%
      filter(Is_Major) %>%
      pull(Party)
  ))
  
  # Rest of the function remains same but uses new major_parties list
  prepared_data <- data %>%
    mutate(
      Clean_Name = clean_name(Candidate),
      Vote_Share = Votes / sum(Votes),
      Is_Major_Party = Party %in% major_parties
    ) %>%
    group_by(Clean_Name) %>%
    mutate(
      Historical_Presence = n_distinct(Year),
      Avg_Vote_Share = mean(Vote_Share)
    ) %>%
    ungroup()
  
  # Modified reference candidate criteria
  reference_candidates <- prepared_data %>%
    filter(
      Is_Major_Party |
        Vote_Share >= vote_share_threshold |
        Historical_Presence > 1
    )
  
  # Potential dummies (more sophisticated filtering)
  potential_dummies <- prepared_data %>%
    filter(
      !Party %in% major_parties,
      Vote_Share < vote_share_threshold,
      Historical_Presence == 1  # First-time candidates
    )
  
  results_list <- list()
  
  # Process each potential dummy with improved matching
  for(i in 1:nrow(potential_dummies)) {
    dummy <- potential_dummies[i,]
    
    # Get relevant reference candidates
    refs <- reference_candidates %>%
      filter(
        Year == dummy$Year,
        State_Name == dummy$State_Name,
        Constituency_Name == dummy$Constituency_Name,
        Clean_Name != dummy$Clean_Name  # Exclude self-matches
      )
    
    if(nrow(refs) > 0) {
      for(j in 1:nrow(refs)) {
        ref <- refs[j,]
        
        # Calculate similarity with improved method
        sim_results <- calculate_similarity(dummy$Clean_Name, ref$Clean_Name)
        
        # Apply more sophisticated matching criteria
        if(sim_results$final_score >= similarity_threshold) {
          
          # Calculate confidence score
          confidence <- sim_results$final_score * 
            (1 - sim_results$penalty) * 
            (1 - dummy$Vote_Share/ref$Vote_Share)
          
          results_list[[length(results_list) + 1]] <- tibble(
            State_Name = dummy$State_Name,
            Constituency_Name = dummy$Constituency_Name,
            Year = dummy$Year,
            Ref_Candidate = ref$Candidate,
            Ref_Party = ref$Party,
            Ref_Votes = ref$Votes,
            Ref_Vote_Share = ref$Vote_Share,
            Similarity_BiSim = sim_results$individual_scores["bisim"],
            Similarity_JW = sim_results$individual_scores["jw"],
            Similarity_Dice = sim_results$individual_scores["dice"],
            Weighted_Similarity = sim_results$final_score,
            Algorithm_Disagreement = sim_results$penalty,
            Confidence_Score = confidence,
            Dummy_Candidate = dummy$Candidate,
            Dummy_Party = dummy$Party,
            Dummy_Votes = dummy$Votes,
            Dummy_Vote_Share = dummy$Vote_Share
          )
        }
      }
    }
  }
  
  # Combine and rank results
  if(length(results_list) > 0) {
    results <- bind_rows(results_list) %>%
      left_join(
        state_parties %>%
          select(State_Name, Party, Is_Major),
        by = c("State_Name", "Ref_Party" = "Party")
      ) %>%
      arrange(desc(Confidence_Score))
    
    return(results)
  }
}

# sample <- tcpd_data %>%
#   filter(Year == 2023)
# results <- detect_dummy_candidates(
#   sample,
#   similarity_threshold = 0.65,      # Single threshold for weighted similarity
#   vote_share_threshold = 0.01       # 1% of total votes
# )

year_state_combos <- tcpd_data %>%
  distinct(Year, State_Name)
dir.create("intermediate_data", showWarnings = FALSE)
for(i in 1:nrow(year_state_combos)) {
  year <- year_state_combos$Year[i]
  state <- year_state_combos$State_Name[i]
  
  cat(sprintf("\nProcessing %d/%d: %s %d", i, nrow(year_state_combos), state, year))
  
  tryCatch({
    chunk_data <- tcpd_data %>%
      filter(Year == year, State_Name == state) %>%
      group_by(Constituency_Name) %>%
      filter(n() >= 5) %>%
      ungroup()
    
    if(nrow(chunk_data) > 0) {
      results <- detect_dummy_candidates(
        chunk_data,
        similarity_threshold = 0.65,      # Single threshold for weighted similarity
        vote_share_threshold = 0.01       # 1% of total votes
      )
      if(nrow(results) > 0) {
        cat(sprintf(" - Found %d potential copycats", nrow(results)))
        write_csv(results, file.path("intermediate_data", sprintf("copycatresults%s_%d.csv", state, year)))
      } else {
        cat(" - No copycats found")
      }
    } else {
      cat(" - No constituencies with 5+ candidates")
    }
  }, error = function(e) {
    cat(sprintf("\nError processing %s %d: %s", state, year, e$message))
  })
}
# Combine all results
result_files <- list.files("intermediate_data", pattern = "copycatresults.*\\.csv", full.names = TRUE)
if(length(result_files) > 0) {
  final_results <- map_df(result_files, read_csv)
  write_csv(final_results, "copycat_candidates_full.csv")
  cat("\nComplete! Total cases found:", nrow(final_results))
} else {
  cat("\nNo copycat cases found in entire dataset")
}


