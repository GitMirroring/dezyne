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

interface IDevice {
    enum result_t {
        OK,
        NOK
    };
    
    in result_t initialize;
    in result_t calibrate;
    in result_t perform_action1;
    in result_t perform_action2;
    
    behaviour {
        enum State {
            Uninitialized,
            Initialized,
            Calibrated
        };
        State s = State.Uninitialized;
        
        [s.Uninitialized] {
            on initialize: {  
                [true] {
                    reply(result_t.OK);
                    s = State.Initialized;
                }
                [true] {
                    reply(result_t.NOK);
                    s = State.Uninitialized;
                }
            }
            on calibrate,
               perform_action1,  
               perform_action2:
                    illegal;
        }
        [s.Initialized] {
            on calibrate: {
                [true] {
                    reply(result_t.OK);
                    s = State.Calibrated;
                }
                [true] {
                    reply(result_t.NOK);
                    s = State.Initialized;
                }
            }
            on initialize:
                    reply(result_t.OK);
            on perform_action1,  
               perform_action2:      
                    illegal;
        }
        [s.Calibrated] {
            on perform_action1,
               perform_action2: {
                [true] {
                    reply(result_t.OK);
                    s = State.Calibrated;
                }
                [true] {
                    reply(result_t.NOK);
                    s = State.Initialized;
                }
            }
            on calibrate:
                    reply(result_t.OK);
            on initialize:
                    illegal;
        }
        
    }
}

interface IComp {
    enum result_t {
        OK,
        NOK
    };

    in result_t initialize;
    in result_t recover;
    in result_t perform_actions;

    behaviour {
        enum State { 
            Uninitialized,
            Initialized,
            Error
        };
        State s = State.Uninitialized;

        [s.Uninitialized] {
            on initialize: {
                [true] {
                    reply(result_t.OK);
                    s = State.Initialized;
                }
                [true] {
                    reply(result_t.NOK);
                    s = State.Uninitialized;
                }
            }
            on recover,
               perform_actions:
                 illegal; 
        }   
        [s.Initialized] {
            on perform_actions: {
                [true] {
                    reply(result_t.OK);
                }
                [true] {
                    reply(result_t.NOK);
                    s = State.Error;
                }
            }
            on initialize,
               recover:
                 illegal; 
        }   
        [s.Error] {
            on recover: {
                [true] {
                    reply(result_t.OK);
                    s = State.Initialized;
                }
                [true] {
                    reply(result_t.NOK);
                }
            }
            on initialize,
               perform_actions:
                 illegal; 
        }   
    }
}


component Comp {
    provides IComp client;
    requires IDevice device_A;
    
    behaviour {
        enum State {
            Uninitialized,
            Initialized,
            Error
        };
        State s = State.Uninitialized;
        
        [s.Uninitialized] {
            on client.initialize: {
                IDevice.result_t res = device_A.initialize;
                if (res.OK) {
                    res = device_A.calibrate;
                }
                
                if (res.OK) {
                    s = State.Initialized;
                    reply(IDevice.result_t.OK);
                } else {
                    s = State.Uninitialized;
                    reply(IDevice.result_t.NOK);
                }
            }
            on client.recover,
               client.perform_actions:
                 illegal; 
        }   
        [s.Initialized] {
            on client.perform_actions: {
                IDevice.result_t res = device_A.perform_action1;
                if (res.OK) {
                    res = device_A.perform_action2;
                }
                
                if (res.OK) {
                    s = State.Initialized;
                    reply(IDevice.result_t.OK);
                } else {
                    s = State.Error;
                    reply(IDevice.result_t.NOK);
                }
            }
            on client.initialize,
               client.recover:
                    illegal; 
        }   
        [s.Error] {
            on client.recover: {
                IDevice.result_t res = device_A.calibrate;
                if (res.OK) {
                    s = State.Initialized;
                    reply(IDevice.result_t.OK);
                } else {
                    s = State.Error;
                    reply(IDevice.result_t.NOK);
                }
            }
            on client.initialize,
               client.perform_actions:
                    illegal; 
        }   
    }
}
