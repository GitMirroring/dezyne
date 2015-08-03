##ifndef #.COMPONENT _COMPONENT_H
##define #.COMPONENT _COMPONENT_H

##include "#.model Interface.h"

struct #.model Component
//  : public #((c++:scope-name) (om:port model))Interface
    : public #(om:name (om:port model))Interface
{
//  static boost::shared_ptr<#((c++:scope-name) (om:port model))Interface> GetInstance();
  static boost::shared_ptr<#(om:name (om:port model))Interface> GetInstance();
  static void ReleaseInstance();
};
##endif
