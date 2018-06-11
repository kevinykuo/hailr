### =========================================================================
### HailTable objects
### -------------------------------------------------------------------------
###
### Direct mapping of Hail Table API to R. HailDataFrame wraps this to
### provide the familiar data.frame API. HailPromises can be derived
### from a HailTable (and serve as columns in a DataFrame).
###

setClass("is.hail.table.Table", contains="JavaObject")

setClass("org.apache.spark.sql.Dataset", contains="JavaObject")

### This is a reference class, because:
### (1) It holds a reference to the Hail table, although that is immutable.
### (2) Practically it would be infeasible to directly map the Hail API to R
###     top-level functions due to name collisions.
### (3) This effectively reimplements the Python glue, so it seems natural
###     for it to be structured like Python, or at least the non-canonical
###     syntax indicates the presence of an external interface.
.HailTable <- setRefClass("HailTable",
                          fields=c(impl="is.hail.table.Table"))

.HailTableRows <- setClass("HailTableRows", slots=c(table="HailTable"),
                           contains="Context")

.HailTableGlobals <- setClass("HailTableGlobals", slots=c(table="HailTable"),
                              contains="Context")

### - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
### Construction
###

HailTable <- function(impl) {
    .HailTable(impl=impl)
}

setMethod("transmit", c("org.apache.spark.sql.Dataset", "is.hail.HailContext"),
          function(x, dest) {
              jvm(dest)$is$hail$table$Table$fromDF(dest, x,
                                                   keys=JavaArrayList())
          })

setMethod("unmarshal", c("is.hail.table.Table", "ANY"),
          function(x, skeleton) unmarshal(HailTable(x), skeleton))

HailTableRows <- function(table) {
    .HailTableRows(table=table)
}

HailTableGlobals <- function(table) {
    .HailTableGlobals(table=table)
}

### - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
### Accessors
###

setMethod("hailType", "HailTable", function(x) as(x$tir$typ, "HailType"))
setMethod("hailType", "HailTableRows", function(x) rowType(hailType(x@table)))
setMethod("hailType", "HailTableGlobals",
          function(x) globalType(hailType(x@table)))

### - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
### I/O
###

readHailTable <- function(file) HailTable(hail_context()$readTable(file))

readHailTableFromText <- function(file,
                                  keyNames = character(0L),
                                  nPartitions = NULL,
                                  types = list(),
                                  comment = character(0L),
                                  separator = "\t",
                                  missing = "NA",
                                  noHeader = FALSE,
                                  impute = FALSE,
                                  quote = NULL,
                                  skipBlankLines = FALSE)
{
    hail_context()$importTable(file, keyNames, as.integer(nPartitions),
                               types, ScalaOption(comment), separator, missing,
                               noHeader, impute, JavaCharacter(quote),
                               skipBlankLines)
}