--		Copyright 1993-2001 by Daniel R. Grayson

-- this file should be mentioned *last* in dumpseq

-- we need some other way to determine whether to load docs
-- shall we still cache them or not?
-- if phase === 2 or phase === 4 or phase == 5 then load "Macaulay2-doc.m2"
-- load "Macaulay2-doc.m2"

setrecursionlimit 300

addStartFunction(() -> path = unique apply( path, minimizeFilename))
addEndFunction(() -> (
	  scan(openFiles(), f -> if isOutputFile f then flush f);
	  path = {};
	  )
     )

erase symbol outputSymbols

writableGlobals := set (
     symbol oooo, symbol ooo, symbol oo, symbol path, symbol phase, symbol currentDirectory,
     symbol documentationPath, symbol DocDatabase, symbol currentFileName, symbol compactMatrixForm,
     symbol buildHomeDirectory, symbol sourceHomeDirectory, symbol currentPrompts, symbol currentPackage,
     symbol packages, symbol currentDictionary, symbol UserDictionary
     )

scan(pairs Macaulay2Dictionary, (name,sym) -> if not writableGlobals#?sym then protect sym)

-- try to wrap long lines intelligently, could be improved:
Matrix.BeforePrint =
RingElement.BeforePrint =
List.BeforePrint = 
Sequence.BeforePrint = x -> wrap(- width stack lines ZZ.InputPrompt lineNumber() + if width stdio > 0 then width stdio else 80, net x) -- 10 to allow for the prompt

-- make sure this is after all global symbols are defined or erased
closePackage Macaulay2
