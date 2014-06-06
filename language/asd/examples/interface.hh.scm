#ifndef __%(*interface*)_INTERFACE_H__
#define __%(*interface*)_INTERFACE_H__

#include <boost/shared_ptr.hpp>

#ifdef ASD_HAVE_CONFIG_H
  #include "asdConfig.h"
#else
  #include "asdDefConfig.h"
#endif

#include "asdPassByValue.h"
#include "asdInterfaces.h"

struct %(*interface*)
{
%(*enums*)
};

class %(*api-class*) : public %(*interface*)
{
public:
  virtual ~%(*api-class*)() {}
% (map-events
"  virtual void %(*event*) () = 0;
" (filter event-in? (interface-events (interface ast))))
protected:
  %(*api-class*)() {}
private:
  %(*api-class*)& operator = (const %(*api-class*)& other);
  %(*api-class*)(const %(*api-class*)& other);
};

class %(*callback-class*)
{
public:
  virtual ~%(*callback-class*)() {}
% (map-events
"  virtual void %(*event*) () = 0;
" (filter event-out? (interface-events (interface ast))))
protected:
  %(*callback-class*)() {}
private:
  %(*callback-class*)& operator = (const %(*callback-class*)& other);
  %(*callback-class*)(const %(*callback-class*)& other);
};


class %(*interface*)Interface
{
public:
  virtual ~%(*interface*)Interface() {}
  // interface used as provided:
  virtual void Get%(*api*)(boost::shared_ptr<%(*api-class*)>* %(*ap*)) = 0;
  virtual void Register%(*callback*)(boost::shared_ptr<%(*callback-class*)> %(*cb*)) = 0;
  // interface used as required:
  virtual void Get%(*callback*)(boost::shared_ptr<%(*callback-class*)>* %(*cb*)) = 0;
  virtual void Register%(*api*)(boost::shared_ptr<%(*api-class*)> %(*ap*)) = 0;
  
  virtual void Register%(*callback*)(boost::shared_ptr<asd::channels::ISingleThreaded> %(*cb*)) = 0;
protected:
  %(*interface*)Interface() {}
private:
  %(*interface*)Interface& operator = (const %(*interface*)Interface& other);
  %(*interface*)Interface(const %(*interface*)Interface& other);
};

#endif // __%(*interface*)_INTERFACE_H__
