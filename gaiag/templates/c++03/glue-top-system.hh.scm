##ifndef #.COMPONENT _COMPONENT_H
##define #.COMPONENT _COMPONENT_H

##include "#.model Interface.h"

struct #.model Component
  : public #((om:scope-name) (om:port model))Interface
{
  static boost::shared_ptr<#((om:scope-name) (om:port model))Interface> GetInstance() ;
  static void ReleaseInstance();
};
##endif
