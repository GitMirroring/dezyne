// Dezyne --- Dezyne command line tools
//
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

dezyne.Main = function(rt, meta) {
  rt.top = rt.top || this;
  rt.components = (rt.components || []).concat ([this]);
  this.rt = rt;
  this.meta = meta;
  this.adaptor = new dezyne.Adaptor(rt, {parent: this, name: 'adaptor'});
  this.choice = new dezyne.ChoiceSystem(rt, {parent: this, name: 'choice'});
  this.runner = this.adaptor.runner;
  this.children = [this.adaptor, this.choice];
  dezyne.connect(this.choice.c, this.adaptor.choice);

};
