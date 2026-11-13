# ==========================================================================
# BAT 402 - FUNDAMENTALS OF ANALYTICS MODELING | FINAL PROJECT
# Group members: [Surname 1, Surname 2, Surname 3]   Section: [ ]
# Dataset: PS4_GamesSales.csv
#   Source: Kaggle - "Video Games Sales Dataset" by SID_TWR
#   https://www.kaggle.com/datasets/sidtwr/videogames-sales-dataset
#   (retrieved [DATE]; scraped from VGChartz)
# Business goal: FORECAST a PS4 game's total global unit sales (millions of
#   copies) from its early North American result plus factors known at launch,
#   so a publisher can plan manufacturing, marketing and inventory while the
#   game is still selling.
# Decision context: the forecast is made AFTER the first North American sales
#   figures arrive, so NorthAmerica is legitimately known at decision time.
#   Europe, Japan and RestofWorld are NOT used because they arrive at the
#   same time as the global figure and would make the model circular.
# Outcome variable: Global (numeric, millions of units) -> REGRESSION
# Predictors: NorthAmerica (early sales signal), Year (via console lifecycle
#   phase), Genre, Publisher tier.
# How to run: place this script and PS4_GamesSales.csv in the same folder,
#   set that folder as the working directory in RStudio, then Run All.
# ==========================================================================

# --------------------------------------------------------------------------
# 0 SETUP - load nothing external; base R only, so the script runs in a
#   fresh R session with no package installation needed.
# --------------------------------------------------------------------------
if (requireNamespace("rstudioapi", quietly = TRUE)) {          # in RStudio, jump to the
  setwd(dirname(rstudioapi::getActiveDocumentContext()$path))   # script folder automatically;
}                                                              # otherwise set it manually

# --------------------------------------------------------------------------
# 1 LOAD AND FIRST LOOK - read the raw file and describe its size and shape
# --------------------------------------------------------------------------
df <- read.csv("PS4_GamesSales.csv", stringsAsFactors = TRUE) # load raw data
dim(df)                    # rows and columns: 1034 x 9
head(df)                   # first six rows: one row = one PS4 game
str(df)                    # variable types; Year is read as text (has "N/A")
summary(df)                # ranges: Global is heavily right-skewed (max 19.39M)

# --------------------------------------------------------------------------
# 2 QUALITY AUDIT - the six required checks plus two extra consistency checks
# --------------------------------------------------------------------------
colSums(is.na(df))         # check 1: missing values - 0 because "N/A" and ""
                           #   are stored as text, not true NA; fixed in block 3
sum(duplicated(df))        # check 2: fully duplicated rows - 0
sum(duplicated(df$Game))   # check 3: repeated game names - 3 (investigated below)
summary(df$Global)         # check 4: outcome distribution - median 0.06 vs mean 0.58
boxplot(df$Global, main = "Global sales per game (millions of units)",
        ylab = "Millions of units")            # check 5: extreme blockbusters
reg_sum <- df$NorthAmerica + df$Europe + df$Japan + df$RestofWorld
sum(abs(df$Global - reg_sum) > 0.011)          # check 6: Global column does not
                           #   equal the sum of the four regions - 2 data errors
sum(df$Global == 0 & reg_sum == 0)             # extra: 322 rows with NO recorded
                           #   sales at all (unreleased or untracked titles)
sum(df$Year == "N/A")      # extra: 209 rows with unknown release year
sum(df$Publisher == "")    # extra: 209 rows with blank publisher

# --------------------------------------------------------------------------
# 3 CLEANING - every action is investigated first, then justified
# --------------------------------------------------------------------------
# 3a. Duplicate game names: War Thunder, Apotheon and Biomutant each appear
#     twice with conflicting year/genre and zero sales. Keep the first row.
df <- df[!duplicated(df$Game), ]                # removed 3 conflicting repeats
# 3b. Data-entry errors: for 2 games the Global column disagrees with the sum
#     of the four regions. Re-derive Global from the regions (regions agree
#     with VGChartz per-title figures, Global was mistyped).
reg_sum <- df$NorthAmerica + df$Europe + df$Japan + df$RestofWorld
sum(abs(df$Global - reg_sum) > 0.011)           # confirm the 2 problem rows
df$Global <- round(reg_sum, 2)                  # corrected 2 values
# 3c. Missing outcome: 319 rows have Global = 0 in ALL regions. VGChartz has
#     no recorded sales for them (mostly unreleased or Japan-only titles).
#     A missing outcome cannot train or test a model, so they are removed.
n_zero <- sum(df$Global == 0)
df <- df[df$Global > 0, ]                       # removed rows with no recorded sales
cat("Rows removed for missing outcome:", n_zero, " Remaining rows:", nrow(df), "\n")
# 3d. Blank publisher (categorical): fill with the most common publisher,
#     an accepted treatment that keeps the rows usable.
pub_mode <- names(sort(table(df$Publisher), decreasing = TRUE))[1]
df$Publisher[df$Publisher == ""] <- pub_mode    # imputed with the modal value
cat("Rows with blank publisher imputed with:", pub_mode,
    "(" , sum(df$Publisher == pub_mode), "games total )\n")
# 3e. Year stored as text with "N/A": only 3 such rows remain, too few to
#     justify losing them, so fill with the median year of the clean data.
df$Year <- as.integer(ifelse(df$Year == "N/A", NA, as.character(df$Year)))
df$Year[is.na(df$Year)] <- median(df$Year, na.rm = TRUE)  # imputed 3 values
dim(df)                    # clean dataset: 712 rows x 9 columns

# --------------------------------------------------------------------------
# 4 FEATURE ENGINEERING - three new variables, each with a business reason
# --------------------------------------------------------------------------
# 4a. PublisherTier: a publisher with 25+ PS4 titles has the marketing muscle
#     and retail relationships of a major; small publishers behave differently.
pub_n     <- table(df$Publisher)
majors    <- names(pub_n)[pub_n >= 25]
cat("Major publishers (25+ games):", length(majors), "\n")
df$PublisherTier <- ifelse(df$Publisher %in% majors, "Major", "Other")
table(df$PublisherTier)                        # 9 major publishers, rest Other
# 4b. LifecyclePhase: the PS4 installed base grew to 2016 then shrank, so the
#     same game sells differently depending on when in the console's life
#     it launches. Year alone is hard to read; grouping makes it a business
#     concept a manager can act on.
df$LifecyclePhase <- cut(df$Year, breaks = c(2012, 2014, 2016, 2020),
                         labels = c("Launch (2013-2014)", "Peak (2015-2016)",
                                    "Late (2017-2020)"))
table(df$LifecyclePhase)
# 4c. GenreGroup: genres with fewer than 20 games (Puzzle, MMO, Visual Novel,
#     Party, Music) are too rare to estimate reliably, so they are merged
#     into "Other" to keep the model stable.
small_genres <- names(which(table(df$Genre) < 20))
df$GenreGroup <- ifelse(df$Genre %in% small_genres, "Other", as.character(df$Genre))
df$GenreGroup <- as.factor(df$GenreGroup)
table(df$GenreGroup)
write.csv(df, "BAT402_FP_Surname1_Surname2_Surname3_Dataset.csv", row.names = FALSE)

# --------------------------------------------------------------------------
# 5 TRAIN-TEST SPLIT - 80/20 with a fixed seed for full reproducibility
# --------------------------------------------------------------------------
set.seed(42)                                    # stated seed: 42
train_idx <- sample(seq_len(nrow(df)), size = 0.8 * nrow(df))
train <- df[train_idx, ]                        # 569 rows for training
test  <- df[-train_idx, ]                       # 143 rows for testing
cat("Train rows:", nrow(train), " Test rows:", nrow(test), "\n")

# --------------------------------------------------------------------------
# 6 MODEL BUILDING - multiple linear regression on the TRAINING set only
# --------------------------------------------------------------------------
model <- lm(Global ~ NorthAmerica + LifecyclePhase + GenreGroup + PublisherTier,
            data = train)
summary(model)             # coefficients and training-set fit

# --------------------------------------------------------------------------
# 7 TEST EVALUATION - performance on the 143 unseen games
# --------------------------------------------------------------------------
pred_test <- predict(model, newdata = test)
rmse_test <- sqrt(mean((test$Global - pred_test)^2))
ss_res    <- sum((test$Global - pred_test)^2)
ss_tot    <- sum((test$Global - mean(test$Global))^2)
r2_test   <- 1 - ss_res / ss_tot
cat("Test RMSE:", round(rmse_test, 3), "million units\n")
cat("RMSE as % of mean test sales:", round(100 * rmse_test / mean(test$Global), 1), "%\n")
cat("Test R-squared:", round(r2_test, 3), "\n")
cat("Mean test sales:", round(mean(test$Global), 3), "million units\n")
small <- test$Global < 1                       # supplementary view: the typical
cat("RMSE for games under 1M units:",            # game, excluding blockbusters
    round(sqrt(mean((test$Global[small] - pred_test[small])^2)), 3),
    "on", sum(small), "of", nrow(test), "test games\n")

# --------------------------------------------------------------------------
# 8 OVERFITTING CHECK - compare training and test error
# --------------------------------------------------------------------------
pred_train <- predict(model, newdata = train)
rmse_train <- sqrt(mean((train$Global - pred_train)^2))
cat("Train RMSE:", round(rmse_train, 3), " Test RMSE:", round(rmse_test, 3),
    " Gap:", round(rmse_test - rmse_train, 3), "\n")

# --------------------------------------------------------------------------
# 9 CROSS-VALIDATION - five-fold loop on the training set
# --------------------------------------------------------------------------
set.seed(42)                                    # same seed for the fold shuffle
folds <- sample(rep(1:5, length.out = nrow(train)))
cv_rmse <- numeric(5)
for (k in 1:5) {
  fit_k <- lm(Global ~ NorthAmerica + LifecyclePhase + GenreGroup + PublisherTier,
              data = train[folds != k, ])
  p_k    <- predict(fit_k, newdata = train[folds == k, ])
  cv_rmse[k] <- sqrt(mean((train$Global[folds == k] - p_k)^2))
  cat("Fold", k, "RMSE:", round(cv_rmse[k], 3), "\n")
}
cat("Average 5-fold RMSE:", round(mean(cv_rmse), 3),
    "vs single-split test RMSE:", round(rmse_test, 3), "\n")

# --------------------------------------------------------------------------
# 10 WHAT-IF SCENARIO - a game just posted 0.30M NA units; forecast global
# --------------------------------------------------------------------------
scenario <- data.frame(NorthAmerica    = c(0.30, 0.30, 0.30, 1.00),
                       LifecyclePhase  = c("Late (2017-2020)", "Late (2017-2020)",
                                           "Peak (2015-2016)", "Late (2017-2020)"),
                       GenreGroup      = rep("Action", 4),
                       PublisherTier   = c("Major", "Other", "Major", "Major"))
scenario$Predicted <- predict(model, newdata = scenario)
scenario$Game      <- c("0.30M NA, Major publisher", "0.30M NA, Small publisher",
                        "0.30M NA, Major, Peak years", "1.00M NA, Major publisher")
print(scenario[, c("Game", "Predicted")])

# --------------------------------------------------------------------------
# 11 MONTE CARLO - 5,000 simulated launches with uncertain inputs
# --------------------------------------------------------------------------
set.seed(42)                                    # seed before the simulation
n_runs   <- 5000
sim_na   <- rnorm(n_runs, mean = 0.30, sd = 0.10)          # NA launch result is
sim_na   <- ifelse(sim_na < 0, 0, sim_na)                  # uncertain (can't be negative)
sim_genre <- sample(c("Action", "Shooter", "Role-Playing", "Sports"),
                        n_runs, replace = TRUE)            # genre mix uncertain
sim_base <- predict(model, newdata =
              data.frame(NorthAmerica = sim_na,
                         LifecyclePhase = factor("Late (2017-2020)",
                           levels = levels(train$LifecyclePhase)),
                         GenreGroup = sim_genre, PublisherTier = "Major"))
sim_sales <- sim_base + rnorm(n_runs, mean = 0, sd = summary(model)$sigma)
sim_sales <- ifelse(sim_sales < 0, 0, sim_sales)   # sales cannot be negative
cat("Simulated mean forecast:", round(mean(sim_sales), 3), "million units\n")
cat("5th percentile:", round(quantile(sim_sales, 0.05), 3),
    " 95th percentile:", round(quantile(sim_sales, 0.95), 3), "\n")
cat("P(global below 0.30M):", round(mean(sim_sales < 0.30), 3), "\n")

# --------------------------------------------------------------------------
# 12 CHARTS - every chart has a message title and labelled axes with units
# --------------------------------------------------------------------------
png("chart1_actual_vs_predicted.png", width = 900, height = 700)
plot(test$Global, pred_test,
     main = "The model tracks small sellers but underestimates blockbusters",
     xlab = "Actual global sales (millions of units)",
     ylab = "Predicted global sales (millions of units)")
abline(0, 1, col = "red", lwd = 2)              # perfect-prediction line
dev.off()

png("chart2_monte_carlo.png", width = 900, height = 700)
hist(sim_sales, breaks = 40,
     main = "Typical forecast lands between 0.4 and 1.6 million units",
     xlab = "Simulated global sales forecast (millions of units)",
     ylab = "Number of simulated launches")
abline(v = quantile(sim_sales, 0.05), col = "red", lwd = 2, lty = 2)
dev.off()

png("chart3_genre.png", width = 900, height = 700)
med <- tapply(df$Global, df$GenreGroup, median)
barplot(sort(med, decreasing = TRUE), las = 2,
        main = "Shooters have the highest typical sales per game",
        xlab = "Genre", ylab = "Median global sales (millions of units)")
dev.off()

png("chart4_lifecycle.png", width = 900, height = 700)
barplot(tapply(df$Global, df$LifecyclePhase, mean),
        main = "Average sales peaked in the console's middle years",
        xlab = "PS4 lifecycle phase", ylab = "Mean global sales (millions of units)")
dev.off()

# ============================ END OF SCRIPT ================================
