# -*- coding: utf-8 -*-
import files, api

items = api.Hierarchize(files.Load('items.dat'))
classes = api.GenerateClassIDs(files.Load('classes.dat'), items)

files.Write('../data.lua', 'Ludwig_Classes=' + classes + '\nLudwig_Items=[['+ api.Format(items, 0) + ']]')