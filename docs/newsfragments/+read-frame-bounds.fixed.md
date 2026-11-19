`read_frame` throws `SeamsError` for a frame below 1 or past the last frame of the file, and for chemfiles-only formats (such as PDB and GRO) when the loaded engine was built without chemfiles.
