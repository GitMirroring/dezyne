// Gaiag --- Guile in Asd In Asd in Guile.
//
// This file is part of Gaiag.
//
// Copyright © 2014 Jan Nieuwenhuizen <janneke@gnu.org>
//
// Gaiag is free software: you can redistribute it and/or modify it
// under the terms of the GNU Affero General Public License as
// published by the Free Software Foundation, either version 3 of the
// License, or (at your option) any later version.
//
// Gaiag is distributed in the hope that it will be useful, but
// WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
// Affero General Public License for more details.
//
// You should have received a copy of the GNU Affero General Public
// License along with Gaiag.  If not, see <http://www.gnu.org/licenses/>.
//
// Commentary:
//
// Code:

component.interface_component_overload = function() {

  this.reply_interface_component_overload_R = nul;

  this.interface_component_overload = new interface.interface_component_overload();

  this.interface_component_overload.ins.e = function() {
    console.log('interface_component_overload.interface_component_overload_e');
    {
      this.reply_interface_component_overload_R = interface.interface_component_overload.R.V;
    }
    return self.reply_interface_component_overload_R;}.bind(this);


};
