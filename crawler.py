# -*- coding: utf-8 -*-
import time
from api import *

# Browse
Start = time.time()
TargetFile = 'new_data.lua'
Classes = GetClasses('http://static.wowhead.com/js/locale_enus.js?1241')
Items = Hierarchize(GetItems('http://www.wowhead.com/items?filter=cr=151:151;crs=4:1;crv=', range(0, 115001, 50)))

# Write the File
f = open(TargetFile, 'w')
f.write('Ludwig_Classes="' + GenerateClassIDs(Classes, Items) + '"\nLudwig_Items=[['+ Format(Items, 0) + ']]')
f.close()

took = time.time() - Start
hours = round(took / 3600)
minutes = round((took - hours) / 60)
seconds = took - hours - minutes

print('')
print('Done!')
print('Took ' + str(hours) + ' hours ' + str(minutes) + ' minutes ' + str(seconds) + ' seconds')