#ifndef __%.interface _INTERFACE_H__
#define __%.interface _INTERFACE_H__

#include <boost/shared_ptr.hpp>

#ifdef ASD_HAVE_CONFIG_H
  #include "asdConfig.h"
#else
  #include "asdDefConfig.h"
#endif

#include "asdPassByValue.h"
#include "asdInterfaces.h"

struct %.interface 
{
 %(->string (map declare-enum (interface-types (interface ast))))
};

class %.module %.api : public %.interface 
{
public:
  virtual ~%.module %.api () {}
% (map-events
"  virtual void %.event () = 0;
" (filter event-in? (interface-events (interface ast))))
protected:
  %.module %.api () {}
private:
  %.module %.api & operator = (const %.module %.api & other);
  %.module %.api (const %.module %.api & other);
};

class %.module %.callback 
{
public:
  virtual ~%.module %.callback () {}
% (map-events
"  virtual void %.event () = 0;
" (filter event-out? (interface-events (interface ast))))
protected:
  %.module %.callback () {}
private:
  %.module %.callback & operator = (const %.module %.callback & other);
  %.module %.callback (const %.module %.callback & other);
};


class %.interface Interface
{
public:
  virtual ~%.interface Interface() {}
  // interface used as provided:
  virtual void Get%.api (boost::shared_ptr<%.module %.api >* %.ap ) = 0;
  virtual void Register%.callback (boost::shared_ptr<%.module %.callback > %.cb ) = 0;
  // interface used as required:
  virtual void Get%.callback (boost::shared_ptr<%.module %.callback >* %.cb ) = 0;
  virtual void Register%.api (boost::shared_ptr<%.module %.api > %.ap ) = 0;
  
  virtual void Register%.callback (boost::shared_ptr<asd::channels::ISingleThreaded> %.cb ) = 0;
protected:
  %.interface Interface() {}
private:
  %.interface Interface& operator = (const %.interface Interface& other);
  %.interface Interface(const %.interface Interface& other);
};

#endif // __%.interface _INTERFACE_H__
