data("ft_na")
se_na <- ft_na[["na"]]
minf <- m0 <- m <- assay(se_na)
m0[3, 2] <- m0[4, 1] <- m0[1, 1] <- 0
minf[m0 == 0] <- Inf
se_zero <- SummarizedExperiment(assay = m0)
se_inf <- SummarizedExperiment(assay = minf)

ft0 <- QFeatures(list(na = se_na, zero = se_zero, inf = se_inf),
                 colData = DataFrame(row.names = LETTERS[1:3]))

test_that("function: .zeroIsNA, .infIsNA", {
    ## .zeroIsNA
    expect_equivalent(se_na, QFeatures:::.zeroIsNA(se_zero))
    expect_equivalent(se_na, zeroIsNA(se_zero))
    ## .infIsNA
    expect_equivalent(se_na, QFeatures:::.infIsNA(se_inf))
    expect_equivalent(se_na, infIsNA(se_inf))
})

test_that("function: .nNAByAssay, .nNAByMargin, .nNA, and .nNAi", {
    ## .nNAByAssay
    nNAassay <- QFeatures:::.nNAByAssay(se_na)
    ## The expected results are initialized after manual inspection
    expect_identical(nNAassay,
                     DataFrame(nNA = 3L,
                               pNA = 3 / 12 * 100))
    
    ## .nNAByMargin
    nNArows <- QFeatures:::.nNAByMargin(se_na, MARGIN = 1)
    nNAcols <- QFeatures:::.nNAByMargin(se_na, MARGIN = 2)
    ## The expected results are initialized after manual inspection
    expect_identical(nNArows,
                     DataFrame(name = rownames(se_na),
                               nNA = c(1L, 0L, 1L, 1L),
                               pNA = c(1/3, 0, 1/3, 1/3) * 100))
    expect_identical(nNAcols,
                     DataFrame(name = colnames(se_na),
                               nNA = c(2L, 1L, 0L),
                               pNA = c(1/2, 1/4, 0) * 100))
    
    ## .nNA for SummarizedExperiemnt
    expect_identical(QFeatures:::.nNA(se_na),
                     list(nNA = nNAassay, nNArows = nNArows, 
                          nNAcols =nNAcols))
    ## Expect only 0's (no missing data) for se_zero
    expect_true(all(sapply(QFeatures:::.nNA(se_zero), 
                           function(x) all(x[, "pNA"] == 0))))
    
    ## .nNAi for QFeatures
    ## The expected results are initialized after manual inspection
    nNAassay <- c(3L, 0L)
    pNAassay <- nNAassay / 12 * 100
    nNArows <- c(1L, 0L, 1L, 1L, rep(0L, 4))
    pNArows <- nNArows / 3 * 100
    nNAcols <- c(2L, 1L, 0L, rep(0L, 3))
    pNAcols <- nNAcols / 4 * 100
    ## Test results 
    n_na <- QFeatures:::.nNAi(ft0, 1:2)
    ## .nNAByAssay
    expect_identical(n_na$nNA,
                     DataFrame(assay = names(ft0)[1:2],
                               nNA = nNAassay, pNA = pNAassay))
    ## .nNAByMargin by row
    expect_identical(n_na$nNArows,
                     DataFrame(assay = rep(names(ft0)[1:2], each = 4),
                               name = unlist(rownames(ft0[, , 1:2]), 
                                             use.names = FALSE),
                               nNA = nNArows, pNA = pNArows))
    ## .nNAByMargin by column
    expect_identical(n_na$nNAcols,
                     DataFrame(assay = rep(names(ft0)[1:2], each = 3),
                               name = unlist(colnames(ft0[, , 1:2]), 
                                             use.names = FALSE),
                               nNA = nNAcols, 
                               pNA = pNAcols))
    ## Check .nNAi with character indexing
    expect_identical(n_na, QFeatures:::.nNAi(ft0, c("na", "zero")))
})

test_that("function: .row_for_filterNA", {
    def <- QFeatures:::.row_for_filterNA(m)
    def_0 <- QFeatures:::.row_for_filterNA(m, pNA = 0L)
    expect_error(QFeatures:::.row_for_filterNA(se_na))
    expect_error(QFeatures:::.row_for_filterNA(m, pNA = TRUE))
    expect_error(QFeatures:::.row_for_filterNA(m, pNA = "0"))
    expect_error(QFeatures:::.row_for_filterNA(m, pNA = c(A = 0, B = 0.5, C = 1)))
    expect_identical(def, def_0)
    expect_identical(def, c(a = FALSE, b = TRUE, c = FALSE, d = FALSE))
    expect_identical(QFeatures:::.row_for_filterNA(assay(se_zero)),
                     c(a = TRUE, b = TRUE, c = TRUE, d = TRUE))
    expect_identical(QFeatures:::.row_for_filterNA(assay(se_na), pNA = .9),
                     c(a = TRUE, b = TRUE, c = TRUE, d = TRUE))
    expect_identical(QFeatures:::.row_for_filterNA(assay(se_zero)),
                     c(a = TRUE, b = TRUE, c = TRUE, d = TRUE))
    expect_identical(QFeatures:::.row_for_filterNA(assay(se_na), pNA = .5),
                     c(a = TRUE, b = TRUE, c = TRUE, d = TRUE))
    expect_identical(QFeatures:::.row_for_filterNA(assay(se_na), pNA = .33),
                     QFeatures:::.row_for_filterNA(assay(se_na), pNA = 0))
    expect_identical(QFeatures:::.row_for_filterNA(assay(se_na), pNA = 0),
                     QFeatures:::.row_for_filterNA(assay(se_na), pNA = -1))
    expect_identical(QFeatures:::.row_for_filterNA(assay(se_na), pNA = 1),
                     QFeatures:::.row_for_filterNA(assay(se_na), pNA = 2))
})

test_that("zeroIsNA,QFeatures", {
    expect_error(ft <- zeroIsNA(ft0))
    ft <- zeroIsNA(ft0, 1)
    expect_equivalent(ft[["na"]], ft[["zero"]])
    ft <- zeroIsNA(ft0, "na")
    expect_equivalent(ft[["na"]], ft[["zero"]])
    ## zeroIsNA on multiple assays
    ft <- zeroIsNA(ft0, 1:2)
    expect_identical(ft, zeroIsNA(ft, c("na", "zero")))
    expect_identical(ft, zeroIsNA(ft, c(1.1, 2.1)))
    expect_equivalent(assay(ft[["na"]]), assay(se_na))
    expect_equivalent(assay(ft[["zero"]]), assay(se_na))
})

test_that("infIsNA,QFeatures", {
    expect_error(ft <- infIsNA(ft0))
    ft <- zeroIsNA(ft0, 1)
    expect_equivalent(ft[["na"]], ft[["zero"]])
    ft <- zeroIsNA(ft0, "na")
    expect_equivalent(ft[["na"]], ft[["zero"]])
    ## zeroIsNA on multiple assays
    ft <- zeroIsNA(ft0, 1:2)
    expect_identical(ft, zeroIsNA(ft, c("na", "zero")))
    expect_identical(ft, zeroIsNA(ft, c(1.1, 2.1)))
    expect_equivalent(assay(ft[["na"]]), assay(se_na))
    expect_equivalent(assay(ft[["zero"]]), assay(se_na))
})

test_that("nNA,SummarizedExperiment and nNA,QFeatures", {
    ## Add an assay with different dimensions (cf issue 118)
    ft0 <- addAssay(ft0, ft0[[1]][1:2, 1:2])
    ## Method vs internal function
    expect_identical(nNA(se_na), QFeatures:::.nNA(se_na))
    expect_identical(nNA(ft0, 1:4), QFeatures:::.nNAi(ft0, 1:4))
    ## nNA on a single assay
    expect_identical(nNA(ft0[[1]]), nNA(se_na))
    ## nNA on multiple assays
    expect_identical(nNA(ft0, 1:3), nNA(ft0, c("na", "zero", "inf")))
})

test_that("filterNA,QFeatures and filterNA,SummarizedExperiment", {
    se_na_filtered <- filterNA(se_na)
    expect_error(filterNA(ft0))
    ft_filtered <- filterNA(ft0, i = seq_along(ft0))
    expect_equivalent(se_na_filtered, ft_filtered[[1]])
    expect_identical(assay(se_na_filtered), m[2, , drop = FALSE])
    se_na_filtered <- filterNA(se_na, pNA = 0.9)
    ft_filtered <- filterNA(ft0, i = seq_along(ft0), pNA = 0.9)
    expect_equivalent(se_na_filtered, ft_filtered[[1]])
    expect_equivalent(se_na_filtered, ft0[[2]])
})

test_that("aggregateFeatures with missing data", {
    expect_message(ft_na <- aggregateFeatures(ft_na, "na", fcol = "X", name = "agg_na",
                                              fun = colSums))
    expect_message(ft_na <- aggregateFeatures(ft_na, "na", fcol = "X", name = "agg_na_rm",
                                              fun = colSums,
                                              na.rm = TRUE))
    agg1 <- matrix(c(NA, NA, 20,
                     NA, 14, 22),
                   ncol = 3, byrow = TRUE,
                   dimnames = list(1:2, LETTERS[1:3]))
    agg2 <- matrix(c(3, 5, 20,
                     2, 14, 22),
                   ncol = 3, byrow = TRUE,
                   dimnames = list(1:2, LETTERS[1:3]))
    expect_identical(assay(ft_na[[2]]), agg1)
    expect_identical(assay(ft_na[[3]]), agg2)
    expect_identical(rowData(ft_na[[2]]), rowData(ft_na[[3]]))
    rd <- DataFrame(X = c(1L, 2L),
                    Y = LETTERS[1:2],
                    .n = c(2L, 2L),
                    row.names = 1:2)
    expect_equivalent(rowData(ft_na[[2]]), rd)
})
