# automatically generated by the FlatBuffers compiler, do not modify

# namespace: flatbuf

import flatbuffers

# /// ----------------------------------------------------------------------
# /// Data structures for describing a table row batch (a collection of
# /// equal-length Arrow arrays)
# /// Metadata about a field at some level of a nested type tree (but not
# /// its children).
# ///
# /// For example, a List<Int16> with values [[1, 2, 3], null, [4], [5, 6], null]
# /// would have {length: 5, null_count: 2} for its List node, and {length: 6,
# /// null_count: 0} for its Int16 node, as separate FieldNode structs
class FieldNode(object):
    __slots__ = ['_tab']

    # FieldNode
    def Init(self, buf, pos):
        self._tab = flatbuffers.table.Table(buf, pos)

# /// The number of value slots in the Arrow array at this level of a nested
# /// tree
    # FieldNode
    def Length(self): return self._tab.Get(flatbuffers.number_types.Int64Flags, self._tab.Pos + flatbuffers.number_types.UOffsetTFlags.py_type(0))
# /// The number of observed nulls. Fields with null_count == 0 may choose not
# /// to write their physical validity bitmap out as a materialized buffer,
# /// instead setting the length of the bitmap buffer to 0.
    # FieldNode
    def NullCount(self): return self._tab.Get(flatbuffers.number_types.Int64Flags, self._tab.Pos + flatbuffers.number_types.UOffsetTFlags.py_type(8))

def CreateFieldNode(builder, length, nullCount):
    builder.Prep(8, 16)
    builder.PrependInt64(nullCount)
    builder.PrependInt64(length)
    return builder.Offset()
