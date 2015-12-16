##ifndef #.INTERFACE COMPONENT_H
##define #.INTERFACE COMPONENT_H

##include "#.interface Interface.h"

class #.interface Component: public #.interface Interface
{
  public:
  static boost::shared_ptr<#.interface Interface> GetInstance();
  static void ReleaseInstance();
};

##endif // #.INTERFACE COMPONENT_H
