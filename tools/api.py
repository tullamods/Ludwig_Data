# -*- coding: utf-8 -*-
import requests, re, files

Markers = {1:'¤', 2:'¢', 3:'€', 4:'£', 5:'฿'}
Alphabet = [chr(i) for i in xrange(0, 127) if i < 91 or i > 95]
NumQualities = 7

# Web
def GetItems(url, pages):
    items = []

    for i, page in enumerate(pages[:-1]):
        source = files.Browse(url + str(pages[i+1] - 1) + ':' + str(page))
        matches = re.findall('"classs".*?cost', source)
        print('Found ' + str(len(matches)) + ' items')

        for match in matches:
            items += [{
                'id': GetNumber('"id', match),
                'class': GetNumber('classs', match),
                'subclass': GetNumber('subclass', match),
                'slot': GetNumber('slot', match),

                'name': re.sub('\\\\', '', GetValue('name', '"\d(.+?[^\\\])"', match)),
                'quality': NumQualities - int(GetValue('name', '["\'](\d)', match)),
                'level': int(GetNumber('reqlevel', match))
            }]

    return items

def GetClasses(url):
    source = files.Browse(url)
    data = re.search('var mn_items=(.*?);\s*var', source, re.DOTALL).group(1)
    classes = []
    level = 0
   
    for match in re.finditer('\[([^\[]*)', data):
        section = match.group(1)
        level = level + 1
    
        if level < 7:
            classs = re.search('^(-*\d+),\s*"([^"]+)"', section)
            if classs:
                classes += [{
                    'id': classs.group(1),
                    'name': classs.group(2),
                    'level': level / 2
                }]
                
        level = level - len(re.findall('\]', section))
    
    print('Found ' + str(len(classes)) + ' item classes')
    return classes

def GetNumber(key, text):
    return GetValue(key, '(-*\d+)', text) or 0

def GetValue(key, kind, text):
    match = re.search(key + '":' + kind, text)
    if match:
        return match.group(1)


# Hierarchization
def Hierarchize(items):
    table = {}
    
    for item in items:   
        SetTable(table, item['class'])
        SetTable(table[item['class']], item['subclass'])
        SetTable(table[item['class']][item['subclass']], item['slot'])
        SetTable(table[item['class']][item['subclass']][item['slot']], item['level'])
        AddItem(table[item['class']][item['subclass']][item['slot']][item['level']], item['quality'], CompressInt(item['id'], 3) + item['name'])
        
    return table

def SetTable(table, index):
    table[index] = table.get(index) or {}

def AddItem(table, quality, item):
    table.setdefault(quality, '')
    table[quality] += '_' + item
    
    
# Class IDs
def GenerateClassIDs(classes, items):
    ids = [None, 0, 0, 0]
    record = ''

    for c in classes:
        table = items

        for i in xrange(1, c['level']):
            table = table.get(ids[i])
            if not table:
                break
    
        for i in xrange(c['level'] + 1, 4):
            ids[i] = 0
    
        if table and table.get(c['id']):
            record += Markers[c['level']] + c['name']
            ids[c['level']] += 1            
            
            table[ids[c['level']]] = table[c['id']]
            del table[c['id']]
            
    return record
  
  
# Formatting
def Format(table, level):
    keys = set(range(len(Alphabet)) + table.keys())
    level += 1
    items = ''

    for i in keys:
        value = table.get(i)        
        if value:
            items += isinstance(i, int) and i > 0 and (Alphabet[i] + Markers[level]) or ''
            items += FormatValue(value, level)
        
    return items
    
def FormatValue(value, level):
    if isinstance(value, dict):
        return Format(value, level)
    elif isinstance(value, basestring):
        return value + '^'

def CompressInt(v, size = 1):
    v = int(v)
    result = ''
 
    while v != 0:
        v, i = divmod(v, len(Alphabet))
        result = Alphabet[i] + result
        
    return Alphabet[0] * (size - len(result)) + result