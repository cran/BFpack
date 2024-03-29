### Joris Mulder 2019. Bayes factor for a one sample Student t test
### via adjusted FBFs (Mulder, 2014) using (m)lm-objects using a t.test object.

#' @method BF htest
#' @export
BF.htest <-
  function(x,
           hypothesis = NULL,
           prior.hyp = NULL,
           ...) {
    stop("Please use the function t_test() from the 'bain' package for a t-test or bartlett_test() from the 'BFpack' package for a test on group variances.")
  }



#' @importFrom stats approxfun
#' @describeIn BF BF S3 method for an object of class 't_test'
#' @method BF t_test
#' @export
BF.t_test <- function(x,
                      hypothesis = NULL,
                      prior.hyp = NULL,
                      complement = TRUE,
                      BF.type = 2,
                      ...){

  numpop <- length(x$estimate)

  if(is.null(BF.type)){
    stop("The argument 'BF.type' must be the integer 1 (for the fractional BF) or 2 (for the adjusted fractional BF).")
  }
  if(!is.null(BF.type)){
    if(is.na(BF.type) | (BF.type!=1 & BF.type!=2))
      stop("The argument 'BF.type' must be the integer 1 (for the fractional BF) or 2 (for the adjusted fractional BF).")
  }
  if(BF.type==2){
    bayesfactor <- "generalized adjusted fractional Bayes factors"
  }else{
    bayesfactor <- "generalized fractional Bayes factors"
  }

  if(numpop==1){ #one sample t test
    tvalue <- x$statistic
    mu0 <- x$null.value
    xbar <- x$estimate
    df <- x$parameter
    n <- df + 1
    stderr <- (xbar - mu0) / tvalue #standard error
    sigmaML <- stderr*sqrt(n-1)
    #evaluation of posterior
    relfit0 <- dt((xbar-mu0)/stderr,df=df,log=TRUE) - log(stderr)
    relfit1 <- log(1-pt((xbar-mu0)/stderr,df=df))
    relfit2 <- log(pt((xbar-mu0)/stderr,df=df))
    #evaluation of prior
    if(BF.type==2){
      relcomp0 <- dt(0,df=1,log=T) - log(sigmaML)
      relcomp1 <- relcomp2 <- log(.5)
    }else{
      relcomp0 <- dt((xbar-mu0)/sigmaML,df=1,log=TRUE) - log(sigmaML)
      relcomp1 <- log(1-pt((xbar-mu0)/sigmaML,df=1))
      relcomp2 <- log(pt((xbar-mu0)/sigmaML,df=1))
    }

    #exploratory BFs
    if(x$method=="Paired t-test"){
      hypotheses_exploratory <- c(paste0("difference=",as.character(mu0)),paste0("difference<",as.character(mu0)),
                                  paste0("difference>",as.character(mu0)))
    }else{
      hypotheses_exploratory <- c(paste0("mu=",as.character(mu0)),paste0("mu<",as.character(mu0)),paste0("mu>",as.character(mu0)))
    }
    logBFtu <- c(relfit0-relcomp0,relfit1-relcomp1,relfit2-relcomp2)
    names(logBFtu) <- hypotheses_exploratory
    BFtu_exploratory <- matrix(exp(logBFtu),nrow=1)
    colnames(BFtu_exploratory) <- hypotheses_exploratory
    row.names(BFtu_exploratory) <- "BFtu"
    PHP_exploratory <- BFtu_exploratory/sum(BFtu_exploratory)
    colnames(PHP_exploratory) <- c(paste0("Pr(=",as.character(mu0),")"),paste0("Pr(<",as.character(mu0),")"),
                                   paste0("Pr(>",as.character(mu0),")"))
    if(x$method=="Paired t-test"){
      row.names(PHP_exploratory) <- "difference"
    }else{
      row.names(PHP_exploratory) <- "mu"
    }

    relfit_exploratory <- matrix(c(exp(relfit0),rep(1,3),exp(relfit1),exp(relfit2)),ncol=2)
    relcomp_exploratory <- matrix(c(exp(relcomp0),rep(1,3),rep(.5,2)),ncol=2)
    row.names(relfit_exploratory) <- row.names(relcomp_exploratory) <- hypotheses_exploratory
    colnames(relfit_exploratory) <- c("f=","f>")
    colnames(relcomp_exploratory) <- c("c=","c>")

    if(!is.null(hypothesis)){ #perform confirmatory tests
      #execute via BF.lm
      sd1 <- sqrt(n) * (xbar - mu0) / tvalue
      y1 <- rnorm(n)
      y1 <- y1 - mean(y1)
      y1 <- sd1*y1/sd(y1) + xbar
      lm1 <- lm(y1 ~ 1)
      if(x$method=="Paired t-test"){
        names(lm1$coefficients) <- "difference"
      }else{
        names(lm1$coefficients) <- "mu"
      }
      BFlm1 <- BF(lm1,hypothesis,prior.hyp=prior.hyp,complement=complement,BF.type=BF.type)
      BFtu_confirmatory <- BFlm1$BFtu_confirmatory
      PHP_confirmatory <- BFlm1$PHP_confirmatory
      BFmatrix_confirmatory <- BFlm1$BFmatrix_confirmatory
      BFtable <- BFlm1$BFtable_confirmatory
      hypotheses <- row.names(BFtable)
      priorprobs <- BFlm1$prior
    }
    if(x$method=="Paired t-test"){
      parameter <- "difference in means"
    }else{
      parameter <- "mean"
    }
  }else{ # two samples t test

    if(!grepl("Welch",x$method)){ # equal variances assumed
      # compute via a lm-analysis
      x1 <- c(rep(1,x$n[1]),rep(0,x$n[2]))
      y1 <- c(rep(0,x$n[1]),rep(1,x$n[2]))
      matx1y1 <- cbind(x1,y1)
      draw1 <- rnorm(x$n[1])
      out1 <- (draw1 - mean(draw1))/sd(draw1)*sqrt(x$v[1])+x$estimate[1]
      draw2 <- rnorm(x$n[2])
      out2 <- (draw2 - mean(draw2))/sd(draw2)*sqrt(x$v[2])+x$estimate[2]
      out <- c(out2,out1)
      # perform the test via a lm object using a factor for the group indicator
      # such that the name of the key variable (the difference between the means)
      # is called 'difference'
      df1 <- data.frame(out=out,differenc=factor(c(rep("a",x$n[2]),rep("e",x$n[1]))))
      lm1 <- lm(out ~ differenc,df1)
      BFlm1 <- BF(lm1,hypothesis=hypothesis,prior.hyp=prior.hyp,complement=complement,BF.type=BF.type)
      BFtu_exploratory <- t(as.matrix(BFlm1$BFtu_exploratory[2,]))
      PHP_exploratory <- t(as.matrix(BFlm1$PHP_exploratory[2,]))
      row.names(BFtu_exploratory) <- row.names(PHP_exploratory) <- "difference"
#
      if(!is.null(hypothesis)){
        BFtu_confirmatory <- BFlm1$BFtu_confirmatory
        PHP_confirmatory <- BFlm1$PHP_confirmatory
        BFmatrix_confirmatory <- BFlm1$BFmatrix_confirmatory
        BFtable <- BFlm1$BFtable_confirmatory
        hypotheses <- row.names(BFtable)
        priorprobs <- BFlm1$prior
      }
    }else{ #equal variances not assumed. BF.lm cannot be used
      meanN <- x$estimate
      scaleN <- (x$v)/(x$n)
      dfN <- x$n-1
      scale0 <- (x$v)*(x$n-1)/(x$n)
      nulldiff <- x$null.value
      df0 <- rep(1,2)
      samsize <- 1e7
      drawsN <- rt(samsize,df=dfN[1])*sqrt(scaleN[1]) + meanN[1] - rt(samsize,df=dfN[2])*sqrt(scaleN[2]) - meanN[2]
      densN <- approxfun(density(drawsN),yleft=0,yright=0)
      relfit0 <- log(densN(nulldiff))
      relfit1 <- log(mean(drawsN<nulldiff))
      relfit2 <- log(mean(drawsN>nulldiff))
      if(BF.type == 2){
        draws0 <- rt(samsize,df=df0[1])*sqrt(scale0[1]) - rt(samsize,df=df0[2])*sqrt(scale0[2])
        relcomp0 <- log(mean((draws0<1)*(draws0> -1))/2)
        relcomp1 <- log(mean(draws0<0))
        relcomp2 <- log(mean(draws0>0))
      }else{
        draws0 <- rt(samsize,df=df0[1])*sqrt(scale0[1]) + meanN[1] - rt(samsize,df=df0[2])*sqrt(scale0[2]) - meanN[2]
        relcomp0 <- log(mean((draws0 < nulldiff + 1)*(draws0 > nulldiff - 1))/2)
        relcomp1 <- log(mean(draws0<nulldiff))
        relcomp2 <- log(mean(draws0>nulldiff))
      }

      #exploratory Bayes factor test
      hypotheses_exploratory <- c("difference=0","difference<0","difference>0")
      logBFtu_exploratory <- c(relfit0-relcomp0,relfit1-relcomp1,relfit2-relcomp2)
      names(logBFtu_exploratory) <- hypotheses_exploratory
      BFtu_exploratory <- exp(logBFtu_exploratory)
      PHP_exploratory <- matrix(BFtu_exploratory/sum(BFtu_exploratory),nrow=1)
      colnames(PHP_exploratory) <- c("Pr(=0)","Pr(<0)","Pr(>0)")
      row.names(PHP_exploratory) <- "difference"
      relfit <- matrix(c(exp(relfit0),rep(1,3),exp(relfit1),exp(relfit2)),ncol=2)
      relcomp <- matrix(c(exp(relcomp0),rep(1,3),rep(.5,2)),ncol=2)
      row.names(relfit) <- row.names(relcomp) <- hypotheses_exploratory
      colnames(relfit) <- c("f=","f>")
      colnames(relcomp) <- c("c=","c>")

      if(!is.null(hypothesis)){
        name1 <- "difference"
        parse_hyp <- parse_hypothesis(name1,hypothesis)
        parse_hyp$hyp_mat <- do.call(rbind, parse_hyp$hyp_mat)
        RrList <- make_RrList2(parse_hyp)
        RrE <- RrList[[1]]
        RrO <- RrList[[2]]
        # if(ncol(do.call(rbind,RrE))>2 || ncol(do.call(rbind,RrO))>2){
        #   stop("hypothesis should be formulated on the only parameter 'difference'.")
        # }
        relfit <- t(matrix(unlist(lapply(1:length(RrE),function(h){
          if(!is.null(RrE[[h]]) & is.null(RrO[[h]])){ #only an equality constraint
            nullvalue <- RrE[[h]][1,2]/RrE[[h]][1,1]
            relfit_h <- c(log(densN(nullvalue)),0)
          }else if(is.null(RrE[[h]]) & !is.null(RrO[[h]])){
            relfit_h <- log(c(1,mean(apply(as.matrix(RrO[[h]][,1])%*%t(drawsN) - as.matrix(RrO[[h]][,2])%*%t(rep(1,samsize)) > 0,2,prod)==1)))
          }else stop("hypothesis should either contain one equality constraint or inequality constraints on 'difference'.")
          return(relfit_h)
        })),nrow=2))
        #relfit <- exp(relfit)
        relcomp <- t(matrix(unlist(lapply(1:length(RrE),function(h){
          if(!is.null(RrE[[h]]) & is.null(RrO[[h]])){ #only an equality constraint
            nullvalue <- RrE[[h]][1,2]/RrE[[h]][1,1]
            relcomp_h <- log(c((sum((draws0<1+nullvalue)*(draws0> -1+nullvalue))/samsize)/2,1))
          }else if(is.null(RrE[[h]]) & !is.null(RrO[[h]])){ #order constraint(s)
            relcomp_h <- log(c(1,mean(apply(as.matrix(RrO[[h]][,1])%*%t(draws0) - as.matrix(RrO[[h]][,2])%*%t(rep(1,samsize)) > 0,2,prod)==1)))
          }else stop("hypothesis should either contain one equality constraint or inequality constraints on 'difference'.")
          return(relcomp_h)
        })),nrow=2))
        #relcomp <- exp(relcomp)
        row.names(relfit) <- row.names(relcomp) <- parse_hyp$original_hypothesis
        colnames(relfit) <- c("f=","f>")
        colnames(relcomp) <- c("c=","c>")
        if(complement == TRUE){
          #add complement to analysis
          welk <- (relcomp==1)[,2]==F
          if(sum((relcomp==1)[,2])>0){ #then there are only order hypotheses
            relcomp_c <- 1-sum(exp(relcomp[welk,2]))
            if(relcomp_c!=0){ # then add complement
              relcomp <- rbind(relcomp,c(0,log(relcomp_c)))
              relfit_c <- 1-sum(exp(relfit[welk,2]))
              relfit <- rbind(relfit,c(0,log(relfit_c)))
              row.names(relfit) <- row.names(relcomp) <- c(parse_hyp$original_hypothesis,"complement")
            }
          }else{ #no order constraints
            relcomp <- rbind(relcomp,c(0,0))
            relfit <- rbind(relfit,c(0,0))
            row.names(relcomp) <- row.names(relfit) <- c(parse_hyp$original_hypothesis,"complement")
          }
        }
        relfit <- exp(relfit)
        relcomp <- exp(relcomp)
        # Check input of prior probabilies
        if(is.null(prior.hyp)){
          priorprobs <- rep(1/nrow(relcomp),nrow(relcomp))
        }else{
          if(!is.numeric(prior.hyp) || length(prior.hyp)!=nrow(relcomp)){
            warning(paste0("Argument 'prior.hyp' should be numeric and of length ",as.character(nrow(relcomp)),". Equal prior probabilities are used."))
            priorprobs <- rep(1/nrow(relcomp),nrow(relcomp))
          }else{
            priorprobs <- prior.hyp
          }
        }
        rm(drawsN)
        rm(draws0)
        #compute Bayes factors and posterior probabilities for confirmatory test
        BFtu_confirmatory <- c(apply(relfit / relcomp, 1, prod))
        PHP_confirmatory <- BFtu_confirmatory*priorprobs / sum(BFtu_confirmatory*priorprobs)
        BFmatrix_confirmatory <- matrix(rep(BFtu_confirmatory,length(BFtu_confirmatory)),ncol=length(BFtu_confirmatory))/
          t(matrix(rep(BFtu_confirmatory,length(BFtu_confirmatory)),ncol=length(BFtu_confirmatory)))
        diag(BFmatrix_confirmatory) <- 1
        row.names(BFmatrix_confirmatory) <- colnames(BFmatrix_confirmatory) <- names(BFtu_confirmatory)
        relative_fit <- relfit
        relative_complexity <- relcomp

        BFtable <- cbind(relative_complexity,relative_fit,relative_fit[,1]/relative_complexity[,1],
                         relative_fit[,2]/relative_complexity[,2],apply(relative_fit,1,prod)/
                           apply(relative_complexity,1,prod),PHP_confirmatory)
        row.names(BFtable) <- names(BFtu_confirmatory)
        colnames(BFtable) <- c("complex=","complex>","fit=","fit>","BF=","BF>","BF","PHP")
        hypotheses <- row.names(relative_complexity)
      }
    }
    parameter <- "difference in means"
  }

  if(is.null(hypothesis)){
    BFtu_confirmatory <- PHP_confirmatory <- BFmatrix_confirmatory <- relative_fit <-
      relative_complexity <- BFtable <- hypotheses <- priorprobs <- NULL
    }

  BFlm_out <- list(
    BFtu_exploratory=BFtu_exploratory,
    PHP_exploratory=PHP_exploratory,
    BFtu_confirmatory=BFtu_confirmatory,
    PHP_confirmatory=PHP_confirmatory,
    BFmatrix_confirmatory=BFmatrix_confirmatory,
    BFtable_confirmatory=BFtable,
    prior.hyp=priorprobs,
    hypotheses=hypotheses,
    estimates=x$coefficients,
    model=x,
    bayesfactor=bayesfactor,
    parameter=parameter,
    call=match.call())

  class(BFlm_out) <- "BF"
  return(BFlm_out)
}













