##ifndef #.COMPONENT _COMPONENT_H
##define #.COMPONENT _COMPONENT_H

##include "#.model Interface.h"

struct #.model Component
: public #.model Interface
{
  static boost::shared_ptr<#.model Interface> GetInstance();
  static void ReleaseInstance();
};

##endif
