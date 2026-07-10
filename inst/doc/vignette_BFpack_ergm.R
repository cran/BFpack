## ----setup, include=FALSE-----------------------------------------------------
knitr::opts_chunk$set(
  echo = TRUE,
  eval = FALSE,          # Code is shown but not run when knitting.
  message = FALSE,       # Set eval = TRUE to run everything live
  warning = FALSE,       # (fitting the Bayesian ERGMs takes a few minutes).
  collapse = TRUE,
  comment = "#>"
)

## ----packages-----------------------------------------------------------------
# # Install once, if needed:
# # install.packages(c("statnet", "ergm", "BFpack", "btergm", "sna", "Bergm"))
# 
# library("statnet")   # umbrella package: loads network, sna, ergm, ...
# library("ergm")      # fitting ERGMs by MLE
# library("BFpack")    # Bayes factors for constrained hypotheses (v1.2.3+)
# library("btergm")    # ships the chemnet policy-network data
# library("sna")       # network descriptives (e.g. betweenness)
# 
# seed <- 1234
# set.seed(seed)

## ----data---------------------------------------------------------------------
# data("chemnet")   # ?chemnet for documentation (Leifeld & Schneider 2012, AJPS)

## ----covariates---------------------------------------------------------------
# # (1) Confirmed scientific-information tie: i->j only if i claims sending
# #     AND j claims receiving. Element-wise product of scito and t(scifrom).
# sci <- scito * t(scifrom)                 # Eq. (1)
# 
# # (2)-(3) Preference similarity from issue positions: Euclidean distance,
# #     then reversed so that LARGER = MORE similar.
# prefsim <- dist(intpos, method = "euclidean")   # Eq. (2)
# prefsim <- max(prefsim) - prefsim               # Eq. (3): distance -> similarity
# prefsim <- as.matrix(prefsim)
# 
# # Standardize preference similarity (needed for the ORDER test, so that
# # effect sizes are comparable on a common scale). We standardize the
# # off-diagonal entries jointly and write them back.
# prefsim_scaled <- c(scale(c(prefsim[lower.tri(prefsim)],
#                             prefsim[upper.tri(prefsim)])))
# prefsim_st <- prefsim
# prefsim_st[lower.tri(prefsim_st)] <- prefsim_scaled[1:(length(prefsim_scaled)/2)]
# prefsim_st[upper.tri(prefsim_st)] <- prefsim_scaled[(length(prefsim_scaled)/2 + 1):length(prefsim_scaled)]
# 
# # (4) Shared committee memberships: co-membership count, diagonal set to 0.
# committee <- committee %*% t(committee)   # Eq. (4)
# diag(committee) <- 0                       # self-membership is meaningless
# committee_scaled <- c(scale(c(committee[lower.tri(committee)],
#                               committee[upper.tri(committee)])))
# committee_st <- committee
# committee_st[lower.tri(committee_st)] <- committee_scaled[1:(length(committee_scaled)/2)]
# committee_st[upper.tri(committee_st)] <- committee_scaled[(length(committee_scaled)/2 + 1):length(committee_scaled)]
# 
# # Organization type as a vertex attribute (vector form).
# types <- types[, 1]
# 
# # Influence attribution, standardized.
# infrep_st <- matrix(c(scale(c(infrep))), nrow = nrow(infrep))

## ----networks-----------------------------------------------------------------
# # Outcome: political / strategic information exchange
# nw.pol <- network(pol)
# set.vertex.attribute(nw.pol, "orgtype", types)
# set.vertex.attribute(nw.pol, "betweenness", betweenness(nw.pol))
# 
# # Covariate network: confirmed technical / scientific information exchange
# nw.sci <- network(sci)
# set.vertex.attribute(nw.sci, "orgtype", types)
# set.vertex.attribute(nw.sci, "betweenness", betweenness(nw.sci))

## ----fit-model1---------------------------------------------------------------
# model1 <- ergm(
#   nw.pol ~ edges +
#     mutual +                    # reciprocity
#     edgecov(nw.sci) +           # scientific information exchange
#     edgecov(prefsim_st) +       # preference similarity (standardized)
#     edgecov(committee_st) +     # shared committees (standardized)
#     edgecov(infrep_st),         # influence attribution (standardized)
#   control = control.ergm(seed = seed)
# )
# summary(model1)

## ----estimates-model1---------------------------------------------------------
# get_estimates(model1)
# #> Coefficient names include, among others:
# #>   edges, mutual, edgecov.nw.sci,
# #>   edgecov.prefsim_st, edgecov.committee_st, edgecov.infrep_st

## ----test1-model1-------------------------------------------------------------
# # Step 3: formulate the hypothesis (note the correct parameter name).
# hypo1 <- "edgecov.prefsim_st = 0"
# 
# # Step 4: BF() fits the Bayesian ERGM internally (this is the slow part),
# # then computes the Bayes factor and posterior probabilities. By default the
# # null is tested against its complement (the two-sided alternative).
# BF_model1_test1 <- BF(model1, hypothesis = hypo1, main.iters = 2000)
# print(BF_model1_test1)

## ----test1-summary------------------------------------------------------------
# # Posterior probabilities that EACH coefficient is zero, negative, or positive.
# # BFpack produces this exploratory test for every parameter by default.
# summary(BF_model1_test1)

## ----test2-model1-------------------------------------------------------------
# # Steps 1 and 2 are unchanged (same fitted model, same parameter names).
# 
# # Step 3: formulate the three hypotheses, separated by semicolons.
# hyp2 <- "edgecov.committee_st > edgecov.infrep_st > edgecov.prefsim_st > 0;
#          edgecov.committee_st = edgecov.infrep_st = edgecov.prefsim_st > 0;
#          edgecov.committee_st = edgecov.infrep_st = edgecov.prefsim_st = 0"
# 
# # Step 4: compute BFs and posterior probabilities. The complement is added
# # automatically, so the `complement` argument can be omitted.
# # NOTE: we test under model1 (which contains all three terms). An earlier
# # draft mistakenly passed `model2` here before it was even fitted.
# BF_model1_test2 <- BF(model1, hypothesis = hyp2, main.iters = 2000)
# print(BF_model1_test2)
# 
# # The full output, including the Specification Table, is worth studying:
# summary(BF_model1_test2)

## ----test2-priors-------------------------------------------------------------
# # Example: down-weight H1/H2/H3 and put more prior mass on the complement.
# BF_model1_test3 <- BF(model1, hypothesis = hyp2,
#                       main.iters = 2000,
#                       prior.hyp.conf = c(1, 1, 1, 4))
# print(BF_model1_test3)

## ----fit-model2---------------------------------------------------------------
# model2 <- ergm(
#   nw.pol ~ edges +
#     edgecov(prefsim_st) +
#     mutual +
#     nodemix("orgtype", base = -7) +
#     nodeifactor("orgtype", base = -1) +
#     nodeofactor("orgtype", base = -5) +
#     edgecov(committee_st) +
#     edgecov(nw.sci) +
#     edgecov(infrep_st) +
#     gwesp(0.1, fixed = TRUE) +
#     gwdsp(0.1, fixed = TRUE),
#   control = control.ergm(seed = seed)
# )
# summary(model2)

## ----tests-model2-------------------------------------------------------------
# # Test 1: is the effect of preference similarity zero?
# hypo1 <- "edgecov.prefsim_st = 0"
# BF_model2_test1 <- BF(model2, hypothesis = hypo1, main.iters = 10000)
# print(BF_model2_test1)
# summary(BF_model2_test1)
# 
# # Test 2: the ranking of opportunity-structure effects.
# hyp2 <- "edgecov.committee_st > edgecov.infrep_st > edgecov.prefsim_st > 0;
#          edgecov.committee_st = edgecov.infrep_st = edgecov.prefsim_st > 0;
#          edgecov.committee_st = edgecov.infrep_st = edgecov.prefsim_st = 0"
# BF_model2_test2 <- BF(model2, hypothesis = hyp2, main.iters = 10000)
# print(BF_model2_test2)
# summary(BF_model2_test2)

## ----session-info, eval=TRUE, echo=FALSE--------------------------------------
# Uncomment when running live to record the software environment:
# sessionInfo()

