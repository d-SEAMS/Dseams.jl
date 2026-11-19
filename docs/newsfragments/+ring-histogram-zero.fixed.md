Indexing a `RingHistogram` with a size that has no ring returns 0 in place of throwing `KeyError`, so a frame with no atoms or no ring of that size gives a count.
