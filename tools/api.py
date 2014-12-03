# -*- coding: utf-8 -*-
import re, json, joblib, multiprocessing
from joblib import Parallel, delayed  
import files

Markers = {1:'¤', 2:'¢', 3:'€', 4:'£', 5:'฿'}
Alphabet = [chr(i) for i in xrange(0, 127) if i < 91 or i > 95]
NumQualities = 7

# Web
def GetItems(url, low, high, step):
    items = []

    while low < high:
        source = files.Browse(url + str(low) + ':' + str(low + step - 1))
        matches = GetJson('listviewitems = ([^;]+);', source) or []
        items += matches
        low += step
        
        print('Found ' + str(len(matches)) + ' items')
    
    print('Found a total of ' + str(len(items)) + ' items')
    return items

def GetClasses(url, low, high):
    classes = {}

    if url.find('|') !=- 1:
        [url, rest] = url.split('|', 1)
    else:
        rest = None
    
    for i in xrange(low, high):
        page = url.format(str(i))
        text = files.Browse(page)
        title = GetTitle(text)     
        if title:
            print(title)
            classes[i] = {
                "name": title,
                "subs": rest and GetClasses(page + rest, low, high) or {}
            }
    
    return classes
    
    
# Parsing
def GetJson(pattern, text):
	match = re.search(pattern, text)
	if match:
         data = "".join(c for c in match.group(1) if ord(c) < 256)
         data = re.sub('([{,])\s*(\w+)\s*:', FixJsonKeys, data)
         data = re.sub('undefined', 'null', data)
         data = re.sub(r'\\[^"]', FixBackslashes, data)
         return json.loads(data)

def FixJsonKeys(match):
	return '{0}"{1}":'.format(match.group(1), match.group(2))
 
def FixBackslashes(match):
     return r'\\\\' + match.group(0)[-1:]
     
def GetTitle(text):
    match = re.search('<h1 class="heading-size-1">(.+?)</h1>', text)
    title = match.group(1).replace('&#039;', "'")
    return title != "Page Not Found" and title


# Hierarchization
def Hierarchize(items):
    table = {}
                    
    for item in items:  
        sections = re.match('(\d)(.+)', item['name'])
        quality = int(sections.group(1))
        name = sections.group(2)         
            
        AddItem(SetTable(SetTable(SetTable(SetTable(table,
            item['classs']),
                item['subclass']),
                    item['slot']),
                        item.get('reqlevel', 0)),
                            NumQualities - quality,
                                CompressInt(item['id'], 3) + name)
        
    return table

def SetTable(table, index):
    index = index or 'None'
    table.setdefault(index, {})
    return table[index]

def AddItem(table, quality, item):
    table.setdefault(quality, '')
    table[quality] += '_' + item
    
    
# Class List  
def CleanClassNames(classes, toRemove = 'Items'):
    for classs in classes.itervalues():
        classs['name'] = re.sub('\s+', ' ' ,
                         re.sub('[(\s]?' + toRemove + '[)\s]?', '', classs['name']))
                         
        CleanClassNames(classs['subs'], toRemove)
        CleanClassNames(classs['subs'], classs['name'])
        
def GenerateClassIDs(classes, items):
    record = ''
    struct = {}
    index = 0
    
    for i, classs in classes.iteritems():
        if items.get(i) and classs['name'] != '':
            record += '{"' + classs['name'] + '"'
            [content, subs] = GenerateClassIDs(classs['subs'], items[i])
            
            if subs != '':
                record += "," + subs + "},"
            else:
                record += "},"
                      
            index += 1
            struct[index] = content
    
    if record != '':
        return struct, '{' + record[:-1] + '}'
    else:
        return items, record
  
  
# Formatting
def Format(table, level):
    keys = set(['None'] + range(len(Alphabet)) + table.keys())
    level += 1
    items = ''

    for i in keys:
        value = table.get(i)        
        if value:
            items += isinstance(i, int) and i >= 0 and (Alphabet[i] + Markers[level]) or ''
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