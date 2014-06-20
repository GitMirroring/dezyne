##ifndef __#.component _COMPONENT_H__
##define __#.component _COMPONENT_H__

#(map-ports
#{
##include "#.interface Interface.h"
#} (component-ports (component ast)))
##include <boost/shared_ptr.hpp>

class #.component Component # (string-if (component-bottom? (component ast))
#{: public #.interface Interface#})
{
public:
# (string-if (component-bottom? (component ast))
#{
  static boost::shared_ptr<#.interface Interface> GetInstance();
#}
#{
  static boost::shared_ptr<#.component Component> GetInstance();
#})
  static void ReleaseInstance();
# (string-if (not (component-bottom? (component ast)))
#{
 #(map-ports
#{
  virtual void Get#.api #.port(boost::shared_ptr<#.interface #.api >* #.ap ) = 0;
  virtual void Register#.callback #.port(boost::shared_ptr<#.interface #.callback > #.cb ) = 0;
##if 0
  virtual void Get#(list .port)Interface(boost::shared_ptr<#.interface Interface>* intf) = 0;
##endif
#} (component-ports (component ast)))
#})
};

##endif // __#.component _COMPONENT_H__
