import cPickle as pickle
import requests

def Browse(url, *tags):
	url = url.format(*tags)
	numTries = 0
	
	if url.startswith('http'):
		print('Retrieving ' + url)
		while numTries < 5:
			numTries += 1
		
			try:
				page = requests.get(url)
				return page.text
			except:
				print('Error retrieving page', url)
				continue
				
			print('Gave up retrieving page', url)
			system.exit()		
	else:
		return Read(url)

def Read(filePath):
	source = open(filePath, 'r')
	text = source.read()
	source.close()
	return text

def Load(filePath):
	source = open(filePath, 'r')
	data = pickle.load(source)
	source.close()
	return data
	
def Write(filePath, text):
	target = open(filePath, 'w')
	target.write(text)
	target.close()
	
def Store(filePath, data):
	target = open(filePath, 'w')
	pickle.dump(data, target)
	target.close()