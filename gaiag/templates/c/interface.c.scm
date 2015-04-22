##include "#.model .h"

##include <string.h>

#(->string (map (enum-to-string model) (gom:interface-enums model)))
#(->string (map (enum-to-string model) (gom:enums)))
#(->string (map (string-to-enum model) (gom:interface-enums model)))
