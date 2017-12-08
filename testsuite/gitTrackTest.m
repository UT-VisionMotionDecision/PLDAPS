function p = gitTrackTest(p)

assert(isa(p, 'pldaps'))

p = pds.git.track(p, mfilename);