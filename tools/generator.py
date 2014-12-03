# -*- coding: utf-8 -*-
import files, api

items = api.Hierarchize(files.Load('items.dat'))
classes = files.Load('classes.dat')

api.CleanClassNames(classes)
[items, classes] = api.GenerateClassIDs(classes, items)

files.Write('../data.lua', 'Ludwig_Classes=' + classes + '\nLudwig_Items=[['+ api.Format(items, 0) + ']]')