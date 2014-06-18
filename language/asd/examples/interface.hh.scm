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

class %.interface %.api : public %.interface 
{
public:
  virtual ~%.interface %.api () {}
% (map-events
"  virtual void %.event () = 0;
" (filter event-in? (interface-events (interface ast))))
protected:
  %.interface %.api () {}
private:
  %.interface %.api & operator = (const %.interface %.api & other);
  %.interface %.api (const %.interface %.api & other);
};

class %.interface %.callback 
{
public:
  virtual ~%.interface %.callback () {}
% (map-events
"  virtual void %.event () = 0;
" (filter event-out? (interface-events (interface ast))))
protected:
  %.interface %.callback () {}
private:
  %.interface %.callback & operator = (const %.interface %.callback & other);
  %.interface %.callback (const %.interface %.callback & other);
};


class %.interface Interface
{
public:
  virtual ~%.interface Interface() {}
  // interface used as provided:
  virtual void Get%.api (boost::shared_ptr<%.interface %.api >* %.ap ) = 0;
  virtual void Register%.callback (boost::shared_ptr<%.interface %.callback > %.cb ) = 0;
  // interface used as required:
  virtual void Get%.callback (boost::shared_ptr<%.interface %.callback >* %.cb ) = 0;
  virtual void Register%.api (boost::shared_ptr<%.interface %.api > %.ap ) = 0;
  
  virtual void Register%.callback (boost::shared_ptr<asd::channels::ISingleThreaded> %.cb ) = 0;
protected:
  %.interface Interface() {}
private:
  %.interface Interface& operator = (const %.interface Interface& other);
  %.interface Interface(const %.interface Interface& other);
};

#endif // __%.interface _INTERFACE_H__
