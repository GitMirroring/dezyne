##include "#.model .h"

##include <string.h>

#(->string (map enum-to-string (gom:interface-enums model)))
#(->string (map string-to-enum (gom:interface-enums model)))
