// Dezyne --- Dezyne command line tools
// Copyright © 2015 Jan Nieuwenhuizen <janneke@gnu.org>
//
// This file is part of Dezyne.
//
// Dezyne is free software: you can redistribute it and/or modify it
// under the terms of the GNU Affero General Public License as
// published by the Free Software Foundation, either version 3 of the
// License, or (at your option) any later version.
//
// Dezyne is distributed in the hope that it will be useful, but
// WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
// Affero General Public License for more details.
//
// You should have received a copy of the GNU Affero General Public
// License along with Dezyne.  If not, see <http://www.gnu.org/licenses/>.
//
// Commentary:
//
// Code:

/*
 * This is confidential material the contents of which are the property of Verum Software Technologies BV.  
 * All reproduction and/or duplication in whole or in part without the written prior consent of 
 * Verum Software Technologies BV is strictly forbidden.  Modification of this code is strictly forbidden 
 * and may result in software runtime failure.
 *
 * Modification or removal of this notice in whole or in part is strictly forbidden.
 * Copyright 1998 - 2013 Verum Software Technologies BV
 */
#ifndef __ASD_USEDSERVICEREF_H__
#define __ASD_USEDSERVICEREF_H__

#include <boost/shared_ptr.hpp>

#include <algorithm>
#include <iterator>
#include <sstream>
#include <vector>
#include <string>

namespace asd_0
{
  class timerid_generator: public std::iterator<std::forward_iterator_tag, boost::shared_ptr<std::string> >
  {
    std::string id_;
    size_t idx_;
  public:
    timerid_generator(const std::string& id, size_t idx = 0)
    : id_(id)
    , idx_(idx + 1)
    {}
    timerid_generator& operator ++ ()
    {
      ++idx_;
      return *this;
    }
    boost::shared_ptr<std::string> operator*() const
    {
      std::ostringstream os;
      os << id_ << idx_;
      return boost::shared_ptr<std::string>(new std::string(os.str()));
    }
    bool operator != (const timerid_generator& that)
    {
      return idx_ != that.idx_;
    }
    bool operator == (const timerid_generator& that) 
    {
      return idx_ == that.idx_; 
    }
  };
  
  struct null_ucv
  {
    size_t size() const { return 0; }
    null_ucv& operator [](size_t){ return *this; }
    bool operator == (const null_ucv&) const { return true; }
    bool operator != (const null_ucv&) const { return false; }
    null_ucv& head(){ return *this; }
    null_ucv& tail(){ return *this; }
    template <typename T>
    bool in(const T&) const { return true; }
  };

  template <typename T>
  class variable_ucv;

  template <typename T>
  class fixed_ucv
  {
  public:
    typedef const boost::shared_ptr<T>* resource_iterator;

    class const_iterator: public std::iterator<std::forward_iterator_tag, T>
    {
      resource_iterator it;
    public:
      const_iterator()
      : it()
      {}
      explicit const_iterator(resource_iterator i)
      : it(i)
      {}
      resource_iterator impl() const
      {
        return it;
      }
      T* operator -> ()
      {
        return &**it;
      }
      T& operator * ()
      {
        return **it;
      }
      bool operator == (const_iterator that) const
      {
        return it == that.it;
      }
      bool operator != (const_iterator that) const
      {
        return !(*this == that);
      }
      const_iterator& operator++()
      {
        ++it;
        return *this;
      }
      friend const_iterator operator + (const_iterator lhs, size_t rhs)
      {
        lhs.it += rhs;
        return lhs;
      }
      friend const_iterator operator + (size_t lhs, const_iterator rhs)
      {
        rhs.it += lhs;
        return rhs;
      }
    };
  private:
    const_iterator begin_;
    const_iterator end_;

    fixed_ucv()
    : begin_()
    , end_()
    {}
  public:
    fixed_ucv(resource_iterator b, resource_iterator e)
    : begin_(b)
    , end_(e)
    {}
    fixed_ucv(const_iterator b, const_iterator e)
    : begin_(b)
    , end_(e)
    {}
    bool operator == (const fixed_ucv& that) const
    {
      return begin_ == that.begin_ && end_ == that.end_;
    }
    bool operator != (const fixed_ucv& that) const
    {
      return !(*this == that);
    }
    bool operator == (const null_ucv&) const
    {
      return empty();
    }
    bool operator != (const null_ucv&) const
    {
      return !empty();
    }
    size_t size() const
    {
      return end_.impl() - begin_.impl();
    }
    bool empty() const
    {
      return 0 == size();
    }
    fixed_ucv head() const
    {
      if(empty()) return fixed_ucv();
      return fixed_ucv(begin_, begin_ + 1);
    }
    fixed_ucv tail() const
    {
      if(empty()) return fixed_ucv();
      return fixed_ucv(begin_ + 1, end_);
    }
    fixed_ucv operator[](size_t i) const
    {
      --i;
      if(i >= size()) return fixed_ucv();
      return fixed_ucv(begin_ + i, begin_ + i + 1);
    }
    const_iterator begin() const
    {
      return begin_;
    }
    const_iterator end() const
    {
      return end_;
    }
    bool in(const null_ucv&) const { return false; }
    bool in(const variable_ucv<T>&) const;
  };

  template <typename T>
  class variable_ucv
  {
    typedef std::vector<fixed_ucv<T> > sequence_t;
    sequence_t seq;
    size_t sz;
  public:
    class const_iterator: public std::iterator<std::forward_iterator_tag, T>
    {
      const variable_ucv& seq;
      size_t seq_idx;
      size_t subseq_idx;
    public:
      const_iterator(const variable_ucv& s, size_t si, size_t ssi)
      : seq(s)
      , seq_idx(si)
      , subseq_idx(ssi)
      {}
      const_iterator(const variable_ucv& s)
      : seq(s)
      , seq_idx(seq.seq.size())
      , subseq_idx()
      {}
      T* operator -> ()
      {
        return &**(seq.seq[seq_idx].begin().impl() + subseq_idx);
      }
      T& operator * ()
      {
        return **(seq.seq[seq_idx].begin().impl() + subseq_idx);
      }
      bool operator == (const_iterator that) const
      {
        return seq_idx == that.seq_idx && subseq_idx == that.subseq_idx;
      }
      bool operator != (const_iterator that) const
      {
        return !(*this == that);
      }
      const_iterator& operator++()
      {
        if(++subseq_idx == seq.seq[seq_idx].size())
        {
          ++seq_idx;
          subseq_idx = 0;
        }
        return *this;
      }
    private:
      const_iterator& operator = (const const_iterator& other);
    };
    const_iterator begin() const
    {
      return const_iterator(*this, 0, 0);
    }
    const_iterator end() const
    { 
      return const_iterator(*this);
    }
    variable_ucv()
    : seq()
    , sz()
    {}
    variable_ucv(const fixed_ucv<T>& that)
    : seq(!that.empty(), that)
    , sz(that.size())
    {}
    variable_ucv& operator = (const null_ucv&)
    {
      seq.clear();
      sz = 0;
      return *this;
    }
    bool operator == (const null_ucv&) const
    {
      return empty();
    }
    bool operator != (const null_ucv&) const
    {
      return !empty();
    }
    bool operator == (const fixed_ucv<T>& that) const
    {
      if(size() != that.size()) return false;
      if(empty()) return true;

      const_iterator lhs = begin();
      typename fixed_ucv<T>::const_iterator rhs = that.begin();

      do
      {
        if(&*lhs != &*rhs)
        {
          return false;
        }
      }
      while(++lhs != end() && ++rhs != that.end());

      return true;
    }
    bool operator == (const variable_ucv& that) const
    {
      if(size() != that.size()) return false;
      if(empty()) return true;

      const_iterator lhs = begin();
      const_iterator rhs = that.begin();

      do
      {
        if(&*lhs != &*rhs)
        {
          return false;
        }
      }
      while(++lhs != end() && ++rhs != that.end());

      return true;

    }
    bool operator != (const fixed_ucv<T>& that) const
    {
      return !(*this == that);
    }
    bool operator != (const variable_ucv& that) const
    {
      return !(*this == that);
    }
    bool empty() const
    {
      return seq.empty();
    }
    size_t size() const
    {
      return sz;
    }
    variable_ucv operator[](size_t i) const
    {
      --i;
      for(typename sequence_t::const_iterator it = seq.begin(); it != seq.end(); ++it)
      {
        if(i < it->size())
        {
          fixed_ucv<T> tmp(it->begin() + i, it->begin() + i + 1);
          return variable_ucv(tmp);        
        }
        i -= it->size();
      }
      return variable_ucv();
    }
    variable_ucv head() const
    {
      variable_ucv tmp;
      if(!seq.empty())
      {
        tmp.seq.resize(1, seq[0].head());
        tmp.sz = 1;
      }
      return tmp;
    }
    variable_ucv tail() const
    {
      if(seq.empty() || (seq.size() == 1 && seq[0].size() == 1))
      {
        return variable_ucv();
      }
      if(seq[0].size() == 1)
      {
        std::vector<fixed_ucv<T> > v(seq.begin() + 1, seq.end());
        variable_ucv tmp;
        tmp.seq.swap(v);
        tmp.sz = sz - 1;
        return tmp;
      }
      variable_ucv tmp(*this);
      tmp.seq[0] = tmp.seq[0].tail();
      tmp.sz = sz - 1;
      return tmp;
    }
    bool in(const null_ucv&) const { return false; }
    bool in(const variable_ucv& that) const
    {
      for(typename sequence_t::const_iterator this_it = seq.begin(); this_it != seq.end(); ++this_it)
      {
        for(typename fixed_ucv<T>::const_iterator it = this_it->begin(); it != this_it->end(); ++it)
        {
          typename sequence_t::const_iterator that_it = that.seq.begin();
          while(that_it != that.seq.end())
          {
            if(std::find(that_it->begin().impl(), that_it->end().impl(), *it.impl()) != that_it->end().impl()) break;
            ++that_it;
          }
          if(that_it == that.seq.end()) return false;
        }
      }
      return true;
    }
  private:
    variable_ucv& operator += (const fixed_ucv<T>& that)
    {
      if(!that.seq.empty())
      {
        seq.push_back(that.seq);
        sz += that.seq.size();
      }
      return *this;
    }
    variable_ucv& operator += (const variable_ucv<T>& that)
    {
      seq.insert(seq.end(), that.seq.begin(), that.seq.end());
      sz += that.size();
      return *this;
    }
    friend variable_ucv operator + (const variable_ucv& lhs, const variable_ucv& rhs)
    {
      if(!lhs.empty() && !rhs.empty())
      {
        variable_ucv tmp(lhs);
        return tmp += rhs;
      }
      if(!lhs.empty())
      {
        return lhs;
      }
      return rhs;
    }
  };

  template <typename T>
  bool operator != (const null_ucv& lhs, const fixed_ucv<T>& rhs)
  {
    return rhs.operator != (lhs);
  }

  template <typename T>
  bool operator != (const null_ucv& lhs, const variable_ucv<T>& rhs)
  {
    return rhs.operator != (lhs);
  }

  template <typename T>
  bool operator != (const fixed_ucv<T>& lhs, const variable_ucv<T>& rhs)
  {
    return rhs.operator != (lhs);
  }

  template <typename T>
  bool operator == (const null_ucv& lhs, const fixed_ucv<T>& rhs)
  {
    return rhs.operator == (lhs);
  }

  template <typename T>
  bool operator == (const null_ucv& lhs, const variable_ucv<T>& rhs)
  {
    return rhs.operator == (lhs);
  }

  template <typename T>
  bool operator == (const fixed_ucv<T>& lhs, const variable_ucv<T>& rhs)
  {
    return rhs.operator == (lhs);
  }


  template <typename T>
  variable_ucv<T> operator + (const fixed_ucv<T>& lhs, const fixed_ucv<T>& rhs)
  {
    return variable_ucv<T>(lhs) + variable_ucv<T>(rhs);
  }
  template <typename T>
  variable_ucv<T> operator + (const variable_ucv<T>& lhs, const fixed_ucv<T>& rhs)
  {
    return lhs + variable_ucv<T>(rhs);
  }
  template <typename T>
  variable_ucv<T> operator + (const fixed_ucv<T>& lhs, const variable_ucv<T>& rhs)
  {
    return variable_ucv<T>(lhs) + rhs;
  }

  template <typename T>
  size_t length(const T& that)
  {
    return that.size();
  }
  
  template <typename T>
  T head(const T& that)
  {
    return that.head();
  }

  template <typename T>
  T tail(const T& that)
  {
    return that.tail();
  }

  template <typename T>
  bool fixed_ucv<T>::in(const variable_ucv<T>& that) const
  {
    return variable_ucv<T>(*this).in(that);
  }

  template <typename S, typename T>
  bool in(const S& lhs, const T& rhs)
  {
    return lhs.in(rhs);
  }
}

#endif
