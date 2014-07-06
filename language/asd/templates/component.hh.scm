##ifndef __#.component _COMPONENT_H__
##define __#.component _COMPONENT_H__

#(map-ports
#{
##include "#.interface Interface.h"
#} (ast:ports model))
##include <boost/shared_ptr.hpp>

class #.component Component # (string-if (ast:bottom? model)
#{: public #.interface Interface#})
{
public:
# (string-if (ast:bottom? model)
#{
  static boost::shared_ptr<#.interface Interface> GetInstance();
#}
#{
  static boost::shared_ptr<#.component Component> GetInstance();
#})
  static void ReleaseInstance();
# (string-if (not (ast:bottom? model))
#{
 #(map-ports
#{
  virtual void Get#.api #.port(boost::shared_ptr<#.interface #.api >* #.ap ) = 0;
  virtual void Register#.callback #.port(boost::shared_ptr<#.interface #.callback > #.cb ) = 0;
##if 0
  virtual void Get#(list .port)Interface(boost::shared_ptr<#.interface Interface>* intf) = 0;
##endif
#} (ast:ports model))
#})
};

##endif // __#.component _COMPONENT_H__
