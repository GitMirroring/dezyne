##ifndef #.COMPONENT COMPONENT_H
##define #.COMPONENT COMPONENT_H

##include "#.model #(symbol-upcase-first .model) Interface.h"

struct #.model Component
: public #.model ::#.model Interface
{
  static boost::shared_ptr<#.model ::#.model Interface> GetInstance();
  static void ReleaseInstance();
};
##endif
