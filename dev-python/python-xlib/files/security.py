# Xlib.ext.security -- SECURITY extension module
# -*- coding: utf-8 -*-
#
#    Copyright (C) 2011 Mickaël Salaün <clipos@ssi.gouv.fr>
#
#    This program is free software; you can redistribute it and/or modify
#    it under the terms of the GNU General Public License as published by
#    the Free Software Foundation; either version 2 of the License, or
#    (at your option) any later version.
#
#    This program is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#    GNU General Public License for more details.
#
#    You should have received a copy of the GNU General Public License
#    along with this program; if not, write to the Free Software
#    Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA


from Xlib.protocol import rq

extname = 'SECURITY'

class QueryTrustLevel(rq.ReplyRequest):
    _request = rq.Struct(
            rq.Card8('opcode'),
            rq.Opcode(3),
            rq.RequestLength(),
            rq.Window('window')
            )
    _reply = rq.Struct(
            rq.ReplyCode(),
            rq.Pad(1),
            rq.Card16('sequence_number'),
            rq.ReplyLength(),
            rq.Window('window'),
            rq.Card32('trust_level'),
            rq.Pad(16)
            )

def query_trust_level(self):
    return QueryTrustLevel(
        display = self.display,
        opcode = self.display.get_extension_major(extname),
        window = self.id
        )

def init(disp, info):
    disp.extension_add_method('window', 'security_query_trust_level', query_trust_level)
