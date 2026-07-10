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
# # install.packages("BFpack")   # once, if needed
# library("BFpack")

## ----data---------------------------------------------------------------------
# install.packages("osfr")   # once, if needed
# library("osfr")            # must be loaded before the download call below
# 
# EVS_Germany <- read.csv(osf_download(
#   osf_ls_files(osf_retrieve_node("7q5pf"),
#                pattern = "regression_EVS_Germany.csv"),
#   conflicts = "overwrite")$local_path)

## ----prepare------------------------------------------------------------------
# EVS_Germany <- EVS_Germany[complete.cases(EVS_Germany), ]
# 
# EVS_Germany$attitude  <- c(scale(EVS_Germany$attitude))
# EVS_Germany$education  <- c(scale(EVS_Germany$education))
# EVS_Germany$income     <- c(scale(EVS_Germany$income))
# EVS_Germany$class      <- c(scale(EVS_Germany$class))
# EVS_Germany$gender     <- as.factor(EVS_Germany$gender)
# 
# fit1 <- lm(attitude ~ education + income + gender + class, data = EVS_Germany)

## ----estimates----------------------------------------------------------------
# get_estimates(fit1)
# #> Coefficient names include: education, income, gender1, class

## ----BFtest-------------------------------------------------------------------
# set.seed(1)   # the equality/order tests use sampling; fix the seed.
# 
# BF_App1 <- BF(fit1,
#   hypothesis = "class > education > income > 0;
#                 education > (class, income) > 0;
#                 class = education = income > 0",
#   complement = TRUE)
# 
# print(BF_App1)

## ----posthoc------------------------------------------------------------------
# library("multcomp")
# library("car")
# 
# K_eq <- rbind(
#   "class - education = 0"  = c(0, -1,  0, 0, 1),
#   "class - income = 0"     = c(0,  0, -1, 0, 1),
#   "education - income = 0" = c(0,  1, -1, 0, 0),
#   "class = 0"              = c(0,  0,  0, 0, 1),
#   "education = 0"          = c(0,  1,  0, 0, 0),
#   "income = 0"             = c(0,  0,  1, 0, 0)
# )
# 
# glht_eq <- multcomp::glht(fit1, linfct = K_eq)   # two-sided by default
# ci_eq   <- confint(glht_eq)                        # 95% (unadjusted) CIs
# sm_eq   <- summary(glht_eq, test = adjusted("holm"))  # Holm-adjusted p-values
# 
# res <- data.frame(
#   Null_hypothesis = names(sm_eq$test$coefficients),
#   Estimate        = as.numeric(sm_eq$test$coefficients),
#   LB_95           = ci_eq$confint[, "lwr"],
#   UB_95           = ci_eq$confint[, "upr"],
#   t_value         = as.numeric(sm_eq$test$tstat),
#   p_adjusted      = as.numeric(sm_eq$test$pvalues),
#   row.names       = NULL
# )
# print(cbind(Null_hypothesis = res[, 1], round(res[, -1], 3)))

## ----session-info, eval=FALSE, echo=FALSE-------------------------------------
# # sessionInfo()   # uncomment when running live to record the environment

