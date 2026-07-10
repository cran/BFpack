## ----setup, include=FALSE-----------------------------------------------------
knitr::opts_chunk$set(
  echo = TRUE,
  eval = FALSE,        # Code is shown but not run when knitting (keeps the
  message = FALSE,     # vignette fast for CRAN). The expected results are
  warning = FALSE,     # reported in the text and tables. Set eval = TRUE, or
  collapse = TRUE,     # paste the chunks into R, to reproduce them live.
  comment = "#>"
)

## ----packages-----------------------------------------------------------------
# # install.packages("BFpack")   # once, if needed (correlation tests need v0.3+)
# library("BFpack")
# 
# set.seed(1)   # cor_test() uses MCMC; fix the seed for reproducibility.

## ----data---------------------------------------------------------------------
# memoryHC <- subset(memory, Group == "HC")[, -7]   # 20 healthy controls
# memorySZ <- subset(memory, Group == "SZ")[, -7]   # 20 patients (schizophrenia)
# 
# colnames(memoryHC)   #> "Im" "Del" "Wmn" "Cat" "Fas" "Rat"

## ----cortest------------------------------------------------------------------
# cor6 <- cor_test(memoryHC, memorySZ)

## ----estimates----------------------------------------------------------------
# get_estimates(cor6)
# #> Correlation names include, among others:
# #>   Del_with_Im_in_g1,  Del_with_Im_in_g2,
# #>   Del_with_Wmn_in_g1, Del_with_Wmn_in_g2,  ...  (30 in total: 15 per group)

## ----hypotheses---------------------------------------------------------------
# constraints_full <-
#  "Del_with_Im_in_g1  > Del_with_Im_in_g2  &
#   Del_with_Wmn_in_g1 > Del_with_Wmn_in_g2 &
#   Del_with_Cat_in_g1 > Del_with_Cat_in_g2 &
#   Del_with_Fas_in_g1 > Del_with_Fas_in_g2 &
#   Del_with_Rat_in_g1 > Del_with_Rat_in_g2 &
#   Im_with_Wmn_in_g1  > Im_with_Wmn_in_g2  &
#   Im_with_Cat_in_g1  > Im_with_Cat_in_g2  &
#   Im_with_Fas_in_g1  > Im_with_Fas_in_g2  &
#   Im_with_Rat_in_g1  > Im_with_Rat_in_g2  &
#   Wmn_with_Cat_in_g1 > Wmn_with_Cat_in_g2 &
#   Wmn_with_Fas_in_g1 > Wmn_with_Fas_in_g2 &
#   Wmn_with_Rat_in_g1 > Wmn_with_Rat_in_g2 &
#   Cat_with_Fas_in_g1 > Cat_with_Fas_in_g2 &
#   Cat_with_Rat_in_g1 > Cat_with_Rat_in_g2 &
#   Fas_with_Rat_in_g1 > Fas_with_Rat_in_g2;
#   Del_with_Im_in_g1  = Del_with_Im_in_g2  &
#   Del_with_Wmn_in_g1 = Del_with_Wmn_in_g2 &
#   Del_with_Cat_in_g1 = Del_with_Cat_in_g2 &
#   Del_with_Fas_in_g1 = Del_with_Fas_in_g2 &
#   Del_with_Rat_in_g1 = Del_with_Rat_in_g2 &
#   Im_with_Wmn_in_g1  = Im_with_Wmn_in_g2  &
#   Im_with_Cat_in_g1  = Im_with_Cat_in_g2  &
#   Im_with_Fas_in_g1  = Im_with_Fas_in_g2  &
#   Im_with_Rat_in_g1  = Im_with_Rat_in_g2  &
#   Wmn_with_Cat_in_g1 = Wmn_with_Cat_in_g2 &
#   Wmn_with_Fas_in_g1 = Wmn_with_Fas_in_g2 &
#   Wmn_with_Rat_in_g1 = Wmn_with_Rat_in_g2 &
#   Cat_with_Fas_in_g1 = Cat_with_Fas_in_g2 &
#   Cat_with_Rat_in_g1 = Cat_with_Rat_in_g2 &
#   Fas_with_Rat_in_g1 = Fas_with_Rat_in_g2"

## ----BFtest-------------------------------------------------------------------
# BF_full <- BF(cor6, hypothesis = constraints_full)
# print(BF_full)
# summary(BF_full)

## ----posthoc------------------------------------------------------------------
# vars  <- colnames(memoryHC)
# n1    <- nrow(memoryHC)
# n2    <- nrow(memorySZ)
# pairs <- combn(vars, 2, simplify = FALSE)
# 
# # Fisher r-to-z comparison of two independent correlations.
# compare_corrs <- function(x1, x2, y1, y2, n1, n2) {
#   r1 <- cor(x1, y1, use = "pairwise.complete.obs")
#   r2 <- cor(x2, y2, use = "pairwise.complete.obs")
#   z1 <- atanh(r1); z2 <- atanh(r2)
#   se <- sqrt(1 / (n1 - 3) + 1 / (n2 - 3))
#   zstat <- (z1 - z2) / se
#   data.frame(r_HC = r1, r_SZ = r2, z = zstat,
#              p_equal        = 2 * pnorm(abs(zstat), lower.tail = FALSE),
#              p_HC_greater   = pnorm(zstat, lower.tail = FALSE))
# }
# 
# results <- do.call(rbind, lapply(pairs, function(pr) {
#   res <- compare_corrs(memoryHC[[pr[1]]], memorySZ[[pr[1]]],
#                        memoryHC[[pr[2]]], memorySZ[[pr[2]]], n1, n2)
#   res$pair <- paste0(pr[1], "_with_", pr[2]); res
# }))
# 
# # Holm correction across the 15 one-sided tests.
# results$p_HC_greater_holm <- p.adjust(results$p_HC_greater, method = "holm")
# results <- results[order(results$pair), ]
# print(cbind(results$pair, round(results[, c("r_HC","r_SZ","z",
#       "p_equal","p_HC_greater","p_HC_greater_holm")], 3)), row.names = FALSE)

## ----session-info, eval=FALSE, echo=FALSE-------------------------------------
# # sessionInfo()   # uncomment when running live to record the environment

