import requests, re, json

# Web
def GetClasses(url):
    print('Browsing Item Classes...')
    source = GetWebPage(url)
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
        
def GetWebPage(url):
	while True:
		page = requests.get(url)
		
		try:
			text = page.text
			return text
		except:
			print('Error retrieving page, repeating')
			continue


# Caching
def SetTable(table, index):
    table[index] = table.get(index) or {}

def AddItem(table, quality, level, item):
    table[level] = table.get(level) or {}
    level = table[level]
    
    old = level.get(quality) or ''
    level[quality] = old + item


# Parsing
def GetValue(key, kind, text):
    match = re.search(key + '":' + kind, text)
    if match:
        return match.group(1)

def GetNumber(key, text):
    return GetValue(key, '(-*\d+)', text)