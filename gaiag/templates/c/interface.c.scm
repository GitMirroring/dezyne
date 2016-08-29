##include "#.scope_model .h"

##if DZN_TRACING
##include <string.h>

#(->string (map (enum-to-string model) (om:interface-enums model)))
#(->string (map (enum-to-string model) (om:enums)))
#(->string (map (string-to-enum model) (om:interface-enums model)))
##endif // DZN_TRACING
