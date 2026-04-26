I've already set my mind on useScrolling on how it listen to the events, but now we have the problem of when an ancestor of a node also has useScrolling which means both of them scroll at once. 

My initial shallow thought on how to fix this was adding support for context/providers just like what React has.
