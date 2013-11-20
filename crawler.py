# -*- coding: utf-8 -*-
import re, time
from api import *

# Localizations
TargetFile = 'new_data.lua'
ItemSearchURL = 'http://www.wowhead.com/items?filter=cr=151:151;crs=4:1;crv='
ClassSearchURL = 'http://static.wowhead.com/js/locale_enus.js?1241'

# Values
Markers = {1:'{', 2:'}', 3:'$', 4:'€', 5:'£'}
NumQualities = 7
MaxItems = 115000
MinItems = 0
ItemBump = 50
Verbose = None

# Globals
Start = time.time()
Cache = {}
Dir = type(Cache)
String = type('')

# Browse Items
value = MinItems
numItems = 0
items = ''

while value < MaxItems:
    upper = str(value + ItemBump - 1)
    lower = str(value)

    if Verbose:
        print('')
        
    print('Searching from ' + lower + ' to ' + upper)
    source = GetWebPage(ItemSearchURL + upper + ':' + lower)
    newItems = 0
    
    for match in re.finditer('"classs".*?cost', source):
        full = match.group(0)
        newItems += 1

        itemID = GetNumber('"id', full)
        name = re.sub('\\\\', '', GetValue('name', '"\d(.+?[^\\\])"', full))
        itemData = itemID + ';' + name + ';'

        itemClass = GetNumber('classs', full) or 'None'
        subClass = GetNumber('subclass', full) or 'None'
        slot = GetNumber('slot', full) or 'None'

        quality = NumQualities - int(GetValue('name', '["\'](\d)', full))
        level = GetNumber('reqlevel', full)
        level = level and int(level) or 'None'

        if Verbose:
            print(itemData, level)
            
        SetTable(Cache, itemClass)
        SetTable(Cache[itemClass], subClass)
        SetTable(Cache[itemClass][subClass], slot)
        AddItem(Cache[itemClass][subClass][slot], quality, level, itemData)

    value += ItemBump
    numItems += newItems
    print('Found ' + str(newItems) + ' items (' + str(numItems) + ' total)')


# Browse Categories
print('')
ids = [None, 0, 0, 0]
classes = ''

for c in GetClasses(ClassSearchURL):
    parentCache = Cache

    for i in range(1, c['level']):
        parentCache = parentCache.get(ids[i])

        if not parentCache:
            break

    for i in range(c['level'] + 1, 4):
        ids[i] = 0

    if parentCache and parentCache.get(c['id']):
        newID = ids[c['level']] + 1
        ids[c['level']] = newID
        
        classes = classes + Markers[c['level']] + c['name']
        parentCache[newID] = parentCache[c['id']]
        parentCache[c['id']] = None


# Extract Cache
def ExtractValue(table, level, marker, i):
    global items
    value = table.get(i)
    
    if value and not value == None:
        if not type(i) == String:
            items += str(i) + marker

        if type(value) == Dir:
            Extract(value, level)
        else:
            items += value.encode("utf-8")

def Extract(table, level):
    marker = Markers[level]
    level = level + 1
    done = {}
    i = 1

    while table.get(i):
        ExtractValue(table, level, marker, i)
        done[i] = True
        i = i + 1
        
    for i, value in table.items():
        if not done.get(i):
            ExtractValue(table, level, marker, i)

print('')
print('Extracting Cache...')
Extract(Cache, 1)


# Write the File
f = open(TargetFile, 'w')
f.write('Ludwig_Classes="' + classes.encode("utf-8") + '"\nLudwig_Items=[['+ items + ']]')
f.close()

took = time.time() - Start
hours = round(took / 3600)
minutes = round((took - hours) / 60)
seconds = took - hours - minutes

print('')
print('Done!')
print('Took ' + str(hours) + ' hours ' + str(minutes) + ' minutes ' + str(seconds) + ' seconds')
