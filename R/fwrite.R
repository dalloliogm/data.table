fwrite <- function(x, file.path, append = FALSE, quote = TRUE,
                   sep = ",", eol = "\n", na = "", col.names = TRUE, qmethod = "double",
                   block.size = 10000) {
  
  # validate arguments
  stopifnot(is.data.frame(x))
  stopifnot(ncol(x) > 0)
  
  stopifnot(length(quote) == 1 && class(quote) == "logical")
  stopifnot(length(sep) == 1 && class(sep) == "character" && nchar(sep) == 1)
  stopifnot(length(eol) == 1 && class(eol) == "character")
  stopifnot(length(qmethod) == 1 && qmethod %in% c("double", "escape"))
  stopifnot(length(col.names) == 1 && class(col.names) == "logical")
  stopifnot(length(append) == 1 && class(append) == "logical")
  stopifnot(length(block.size) == 1 && block.size > 0)
  
  # handle paths like "~/foo/bar"
  file.path <- path.expand(file.path)
  
  quoted_cols <- rep(quote, ncol(x))
  
  # special case: single-column data.frame, doing x[block_begin:block_end,]
  # for such data frame gives a vector
  if (!is.data.table(x) && ncol(x) == 1) x <- as.data.table(x)
  
  # write header row separately for correct quoting of row names
  if (col.names && !append) {
    .Call(Cwritefile, as.list(names(x)), file.path, sep, eol, na, quoted_cols, qmethod == "escape", append)
    append <- TRUE
  }
  
  # handle empty x
  if (nrow(x) == 0) return()
  
  # determine from column types, which ones should be quoted
  if (quote) {
    column_types <- sapply(x, class)
    quoted_cols <- column_types %chin% c('character', 'factor')
  }
  
  # write in blocks of given size to avoid generating full copies
  # of columns in memory
  block_begin <- 1
  
  repeat {
    block_end <- min(block_begin+(block.size-1), nrow(x))
    
    dt_block <- x[c(block_begin:block_end),]
    
    # convert data.frame row block to a list of columns
    col_list <- lapply(dt_block, function(column) {
      if (!(class(column) %chin% c('integer', 'numeric', 'character'))) {
        column <- as.character(column)
      }
      column
    })
    
    .Call(Cwritefile, col_list, file.path, sep, eol, na, quoted_cols, qmethod == "escape", append)
    
    if (block_end == nrow(x)) break
    
    append <- TRUE
    block_begin <- block_end+1
  }
}