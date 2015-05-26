#include <functional>
#include <iostream>

#include <boost/function_types/function_type.hpp>
#include <boost/function_types/formal_types.hpp>
#include <boost/function_types/function_arity.hpp>

struct S
{
void foo(double d, int i)
  {
std::cout << "foo(" << d << "," << i << ")" << std::endl;
  }
};

std::function<void()> queue;

void handle_event(const std::function<void()>& f)
{
  std::cout << "hiero" << std::endl;
  queue = f;
}

// template <typename T>
// std::function<std::function<void()>(double)> prep_handle_event(const std::function<T>& f)
// {
//   using namespace std::placeholders;
//   return std::function<std::function<void()>(double)>(std::bind(handle_event, std::bind(f, _1)));
// }

template <typename A0>
void indirection(const std::function<void(A0)>& e, A0 a0)
{
  handle_event(std::function<void()>(std::bind(e, a0)));
}

template <typename A0, typename A1>
void indirection(const std::function<void(A0, A1)>& e, A0 a0, A1 a1)
{
  handle_event(std::function<void()>(std::bind(e, a0, a1)));
}

template <typename T>
std::function<T> prep_handle_event(const std::function<T>& f)
{
  using namespace std::placeholders;
  //return std::function<void(double)>([f](double d){  std::cout << "daaro" << std::endl; handle_event(std::bind(f, d));});
  //typename boost::function_types::formal_types<T>::type a = 0;

  typedef typename boost::mpl::at_c<typename boost::function_types::formal_types<T>::type, 0>::type A0;
  typedef typename boost::mpl::at_c<typename boost::function_types::formal_types<T>::type, 1>::type A1;
return std::function<void(A0,A1)>(std::bind(indirection<A0,A1>, f, _1, _2));
}

void flush()
{
  queue();
}

int main()
{
  S s;

  using namespace std::placeholders;
std::function<void(double, int)> port_event = prep_handle_event(std::function<void(double, int)>(std::bind(&S::foo, &s, _1, _2)));//insert mechanics here

  //std::cout << port_event(0.123) << std::endl;

port_event(0.123, 123);// capture formal_list, store in queue

  flush();// execute s.foo(0.123);
}
