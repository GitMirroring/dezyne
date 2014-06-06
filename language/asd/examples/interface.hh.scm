#ifndef __%(interface-name (interface ast))_INTERFACE_H__
#define __%(interface-name (interface ast))_INTERFACE_H__

#include <boost/shared_ptr.hpp>

#ifdef ASD_HAVE_CONFIG_H
  #include "asdConfig.h"
#else
  #include "asdDefConfig.h"
#endif

#include "asdPassByValue.h"
#include "asdInterfaces.h"

struct %(interface-name (interface ast))
{
%(map (lambda (enum) (string-join (map ->string (enum-elements enum)))) (interface-types (interface ast)))
};

class %(api-class) : public %(interface-name (interface ast))
{
public:
  virtual ~%(api-class)() {}
%(api-events)
protected:
  %(api-class)() {}
private:
  %(api-class)& operator = (const %(api-class)& other);
  %(api-class)(const %(api-class)& other);
};

class %(callback-class)
{
public:
  virtual ~%(callback-class)() {}
%(callback-events)
protected:
  %(callback-class)() {}
private:
  %(callback-class)& operator = (const %(callback-class)& other);
  %(callback-class)(const %(callback-class)& other);
};


class %(interface-name (interface ast))Interface
{
public:
  virtual ~%(interface-name (interface ast))Interface() {}
  // interface used as provided:
  virtual void Get%(api)(boost::shared_ptr<%(api-class)>* %(ap)) = 0;
  virtual void Register%(callback)(boost::shared_ptr<%(callback-class)> %(cb)) = 0;
  // interface used as required:
  virtual void Get%(callback)(boost::shared_ptr<%(callback-class)>* %(cb)) = 0;
  virtual void Register%(api)(boost::shared_ptr<%(api-class)> %(ap)) = 0;
  
  virtual void Register%(callback)(boost::shared_ptr<asd::channels::ISingleThreaded> %(cb)) = 0;
protected:
  %(interface-name (interface ast))Interface() {}
private:
  %(interface-name (interface ast))Interface& operator = (const %(interface-name (interface ast))Interface& other);
  %(interface-name (interface ast))Interface(const %(interface-name (interface ast))Interface& other);
};

#endif // __%(interface-name (interface ast))_INTERFACE_H__
