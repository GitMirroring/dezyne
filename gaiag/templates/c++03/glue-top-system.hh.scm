##ifndef #.COMPONENT _COMPONENT_H
##define #.COMPONENT _COMPONENT_H

##include "#.model Interface.h"

struct #.model Component
  : public #(.type (om:port model))Interface
{
  static boost::shared_ptr<#(.type (om:port model))Interface> GetInstance();
  static void ReleaseInstance();
};
##endif
