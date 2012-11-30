# -*- coding: utf-8 -*-
import requests, re, time

# Localizations
TargetFile = '/Users/Jaliborc/Applications/World of Warcraft/Release/Interface/AddOns/Ludwig_Data/new data.lua'
ItemSearchURL = 'http://www.wowhead.com/items?filter=cr=151:151;crs=4:1;crv='
ClassSearchURL = 'http://static.wowhead.com/js/locale_enus.js?1241'

# Values
Markers = {1:'{', 2:'}', 3:'$', 4:'€', 5:'£'}
NumQualities = 7
MaxItems = 95000
MinItems = 0
ItemBump = 50
Verbose = None

# Globals
Start = time.time()
Cache = {}
Dir = type(Cache)
String = type('')
items = '[['
classes = '[['


# Request Methods
def GetWebPage(url):
	while True:
		page = requests.get(url)
		
		try:
			text = page.text
			return text
		except:
			print('Error retrieving page, repeating')
			continue

# Cache Methods
def SetTable(table, index):
    table[index] = table.get(index) or {}

def AddItem(table, quality, level, item):
    table[level] = table.get(level) or {}
    level = table[level]
    
    old = level.get(quality) or ''
    level[quality] = old + item

# Item Matching Methods
def GetValue(key, kind, text):
    match = re.search(key + '":' + kind, text)
    if match:
        return match.group(1)

def GetNumber(key, text):
    return GetValue(key, '(-*\d+)', text)


# Browse Items
value = MinItems

while value < MaxItems:
    upper = str(value + ItemBump - 1)
    lower = str(value)

    if Verbose:
        print('')
        
    print('Searching from ' + lower + ' to ' + upper)
    source = GetWebPage(ItemSearchURL + upper + ':' + lower)
    
    for match in re.finditer('"classs".*?cost', source):
        full = match.group(0)

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


# Browse Categories
print('')
print('Browsing Category Names...')
source = GetWebPage(ClassSearchURL)
source = re.search('var mn_items=(.*?);\s+var', source, re.DOTALL).group(1)
ids = [None, 0, 0, 0]
level = 0

for match in re.finditer('\[([^\[]*)', source):
    section = match.group(1)
    level = level + 1

    if level < 7:
        classs = re.search('^(-*\d+),\s+"([^"]+)"', section)

        if classs:
            classID = classs.group(1)
            className = classs.group(2)
            classLevel = level / 2

            if Verbose:
                print(className, classID, classLevel)

            parentCache = Cache
            
            for i in range(1, classLevel):
                parentCache = parentCache.get(ids[i])

                if not parentCache:
                    break

            for i in range(classLevel + 1, 4):
                ids[i] = 0

            if parentCache and parentCache.get(classID):
                newID = ids[classLevel] + 1
                ids[classLevel] = newID
                
                classes = classes + Markers[classLevel] + className
                parentCache[newID] = parentCache[classID]
                parentCache[classID] = None

    level = level - len(re.findall('\]', section))


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
f.write('Ludwig_Classes=' + classes.encode("utf-8") + ']]\n\nLudwig_Items='+ items + ']]')
f.close()

took = time.time() - Start
hours = round(took / 3600)
minutes = round((took - hours) / 60)
seconds = took - hours - minutes

print('')
print('Done!')
print('Took ' + str(hours) + ' hours ' + str(minutes) + ' minutes ' + str(seconds) + ' seconds')
