# Dezyne --- Dezyne command line tools
#
# Copyright © 2021 Jan (janneke) Nieuwenhuizen <janneke@gnu.org>
#
# This file is part of Dezyne.
#
# Dezyne is free software: you can redistribute it and/or modify it
# under the terms of the GNU Affero General Public License as
# published by the Free Software Foundation, either version 3 of the
# License, or (at your option) any later version.
#
# Dezyne is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
# Affero General Public License for more details.
#
# You should have received a copy of the GNU Affero General Public
# License along with Dezyne.  If not, see <http://www.gnu.org/licenses/>.
#
# Commentary:
#
# Code:

EXTRA_DIST += %D%/README

DEZYNE_EXAMPLES =				\
 %D%/ca.dzn					\
 %D%/compliance-multiple-provides-fork.dzn	\
 %D%/component-if-illegal.dzn			\
 %D%/decompose2-proxy.dzn			\
 %D%/decompose2.dzn				\
 %D%/function-call-status.dzn			\
 %D%/icode.dzn					\
 %D%/iconsole.dzn				\
 %D%/imessage-handler.dzn			\
 %D%/imotion1.dzn				\
 %D%/imotion2.dzn				\
 %D%/imotion3.dzn				\
 %D%/imotion4.dzn				\
 %D%/imotion5.dzn				\
 %D%/imperative-action.dzn			\
 %D%/inner-space.dzn				\
 %D%/iprocess-safety1.dzn			\
 %D%/iprocess-safety2.dzn			\
 %D%/iprotocol-stack.dzn			\
 %D%/iprotocol-stack1.dzn			\
 %D%/isensor.dzn				\
 %D%/isimple-protocol.dzn			\
 %D%/isiren.dzn					\
 %D%/isiren1.dzn				\
 %D%/isiren2.dzn				\
 %D%/itimer.dzn					\
 %D%/itimer2.dzn				\
 %D%/message-handler.dzn

EXTRA_DIST += $(DEZYNE_EXAMPLES)

TUTORIAL_EXAMPLES =				\
 %D%/ArmourIBVIRR.dzn				\
 %D%/ArmourIBVIRRError.dzn			\
 %D%/ArmourIIPRB.dzn				\
 %D%/ArmourIIPRBError.dzn			\
 %D%/ArmourIIPRE.dzn				\
 %D%/ArmourIIPREError.dzn			\
 %D%/ArmourIIPRV.dzn				\
 %D%/ArmourIIPRVError.dzn			\
 %D%/ArmourISOE.dzn				\
 %D%/ArmourISOEError.dzn			\
 %D%/ArmourMAOE.dzn				\
 %D%/ArmourMAOEError.dzn			\
 %D%/ArmourMSOE.dzn				\
 %D%/ArmourMSOEError.dzn			\
 %D%/ArmourOENABP.dzn				\
 %D%/ArmourOENABPError.dzn			\
 %D%/ArmourREIR.dzn				\
 %D%/ArmourREIRError.dzn			\
 %D%/Logger.dzn

EXTRA_DIST += $(TUTORIAL_EXAMPLES)
