#!/usr/bin/env python3.4

from __future__ import print_function
from notInFile import grep
import sys, traceback, re, urllib, argparse, time, threading
from colorama import init, Fore, Back, Style
from subprocess import call, Popen, PIPE
from urllib.request import urlopen
from urllib.request import urlretrieve
from urllib.parse import urlparse
from collections import deque

errorBeep = False
newItemBeep = False
allowW3 = False
errLog = None
errorURL = None
toScrape = None
scraped = open('scraped.txt','a+')
ctrlC = False
cachePath = None
opts = None
runtime = []
block = []
loadConfig = True


def indent(txt,indentText,numofindents):
	return (indentText * numofindents) + txt.replace('\n','\n' + (indentText * numofindents))

def sndError(url,description):
	global errLog
	err = traceback.format_exc(15)
	writerr =time.asctime() + ' ' + url + '\n' + indent(description,'	',1) + '\n' + indent(err,'	',1)
	errLog.write(writerr + '\n\n')
	errLog.flush()

def errsound():
	global errorBeep
	if errorBeep:
		print('\a',end='')
	return
	
def newItem(itemType):
	global newItemBeep
	if newItemBeep:
		if itemType == 'phone':
			file = 'Ding.wav' # ring (annoying and grainy) => 'phone.wav'
		else:
			file = 'email.wav'
		play = Popen(['play',file],stdout=PIPE,stderr=PIPE)
		del play

def validLink(url):
	global allowW3, block
	arr = ['mailto:' , 'javascript:']
	
	tmpBlock = block
	if not allowW3:
		tmpBlock.append('w3.org')
	for a in arr:
		if url.lower().startswith(a):
			return 0
	for a in tmpBlock:
		if a in url:
			return 0 
	return 1

def completeUrl(link,linkLoc):
	if '://' in link:
		parsed = urlparse(link)
		if parsed.scheme == 'http' or parsed.scheme == 'https':
			return link
	else:
		retrn = ''
		parsed = urlparse(linkLoc)
		if link[0] == '/':
			tmp = parsed.path[0:parsed.path.rfind('/')]
			retrn = parsed.scheme + '://' + parsed.netloc + tmp + link
		elif link[0:3] == '../':
			tmp = parsed.path[:parsed.path.rfind('/')]
			tmp = tmp[:tmp.rfind('/') + 1]
			retrn = parsed.scheme + '://' + parsed.netloc + tmp + link[3:]
		return retrn

def scrapeurl(logFile , url,cachePath,phoneLog):
	global ctrlC
	global toScrape
	
	log = open(logFile , 'a+')
	numLog = open(phoneLog, 'a+')
	try:
		cacheLog = urlretrieve(url, cachePath +'cache.txt')[0]
	
	except KeyboardInterrupt:
		raise
	except:
		errsound()
		sndError(url,'loading url into cache')
		print(Back.RED + 'unable to retrieve:' , url)
		return
	file = open(cacheLog, 'rU')
	i = 1
	print('links:')
	try:
		for line in file:
			
			matches = re.findall('[\w.-]+@[\w.-]+\.\w{2,3}',line)
			
			for match in matches:
				print(Back.RED + Style.BRIGHT + '?' , Back.BLUE + Style.BRIGHT + match , end='\r')
				if grep(match , logFile , 'a'):
					print(Back.BLUE + Style.BRIGHT + match, ' ')
					newItem('mail')
				else:
					print(Back.YELLOW + 'X ' + match)

				
			del matches

			links = re.findall('<a\\s+?.*?href=["\'](.+?)["\'].*?>',line)
			links.extend(re.findall('https?://[\\w.-]+?\\.\\w{2,3}/?[\\w/]+\\.?\\w*\\??[^"\'\\s]*?',line))

			for link in links:
				link = completeUrl(link,url)
				if link:
					try:
						if not link in toScrape:
							toScrape.append(link)
					except TypeError:
						print('')
					print(link , '--line ' , i)
			del links
			nums = re.findall(r'[(]*(\d\d\d)[)]*[ .-](\d\d\d)[ .-](\d\d\d\d)',line)
			for num in nums:
				completeNum = '(' + num[0] + ') ' + num[1] + '-' + num[2]
				print(Back.RED + Style.BRIGHT + '?' , Back.GREEN + Style.BRIGHT + completeNum , end='\r')
				if grep(completeNum , phoneLog , 'a'):
					print(Back.GREEN + Style.BRIGHT + completeNum, ' ')
					newItem('phone')
				else:
					print(Back.YELLOW + 'X ' + completeNum)
			del nums
			i+=1
	except SyntaxError:
		raise
	except (UnicodeDecodeError,UnicodeEncodeError):
		print(Back.RED + 'unknown character(s) in line ' , i)
		sndError(url,'unicode error in line ' + str(i))
		errsound()
		pass
	except KeyboardInterrupt:
		print('^C')
		ctrlC = True
		raise
	file.close()
	del file

def savequeue(queue,path):
	if queue and prmpt('\rwould you like to save the queue'):
		print('saving queue...')
		file = open(path + 'queue.txt','w+')
		for item in queue:
			try:
				file.write(item + '\n')
			except TypeError:
				pass
		return True
	return False

def loadqueue(path):
	file = open(path + 'queue.txt','r')
	queue = deque()
	for line in file:
		queue.append(line[:-1])
	return queue

def exit():
	global toScrape, runtime, cachePath
	runtime.append(time.asctime())
	print('start: ' + runtime[0] + '\nstop: ' + runtime[1])
	if savequeue(toScrape,cachePath):
		print('queue saved\nqueue dir: ' + cachePath)
	

def prmpt(message):
	for i in range(0,10):
		try:
			if input(message + ' [y/n]? ').lower() == 'y':
				return True
			return False
		except EOFError:
			print('try again, press Ctrl+C to force save')
			try:
				time.sleep(1)
			except KeyboardInterrupt:
				return True
	return True

def configLoaderFunc():
	global loadConfig
	
	loadConfig()
	while 1:
		time.sleep(60)
		p = Popen(['play','phone.wav'],stdout=PIPE,stderr=PIPE)
		del p
		loadConfig(noerrlog=True)

def loadConfig(noerrlog=False):
	global errorBeep, newItemBeep, allowW3, cachePath, block, errLog
	try:
		configFile = open(cachePath + 'config.ini')
		txt = configFile.read()
		configVars = re.findall(r'(\w+)=(.+)',txt)
	except IOError:
		print('config file ' + cachePath + 'config.ini does not exist')
		raise SystemExit
	for itm in configVars:
		if itm[0] == 'newItemBeep':
			if itm[1] == 'True':
				newItemBeep = True
			else:
				newItemBeep = False
		elif itm[0] == 'errorBeep':
			if itm[1] == 'True':
				errorBeep = True
			else:
				errorBeep = False
		elif itm[0] == 'allowW3':
			if itm[1] == 'True':
				allowW3 = True
			else:
				allowW3 = False
		elif itm[0] == 'block':
			complete = completeUrl(itm[1],'')
			if complete not in block:
				block.append(complete)
		elif itm[0] == 'truncateErrorLog':
			if not noerrlog:
				if itm[1] == 'True':
					errLog = open(cachePath + 'errorlog.log', 'w+')
				else:
					errLog = open(cachePath + 'errorlog.log', 'a+')

def _init_(): 
	global errorBeep, newItemBeep, allowW3, errLog, errorURL, toScrape, scraped, ctrlC, cachePath, runtime, opts, block
	runtime.append(time.asctime())
	print(runtime[0])
	
	#askForOptions = True

	#parse arcuments
	parser = argparse.ArgumentParser(description='crawl the web')
	parser.add_argument('-q', '--queue' , dest='queue'    , action='store_true',            help='if present, load queue from file'            )
	parser.add_argument('-c', '--config', dest='config'   , action='store_true',            help='if present, load config from file'           ) 
	parser.add_argument('-b', '--block' , dest='block'    , action='append'    ,            help='block url'                                   ) 
	parser.add_argument('-u', '--url'   , dest='url'      , action='append'    ,            help='urls to search'                              )
	parser.add_argument('-p', '--path'  , dest='cachePath', action='store'     ,            help='path to config.ini, queue.txt and cache.txt' )
	opts = parser.parse_args()

	#command line input --------V
	
	#load cache path
	cachePath = opts.cachePath
	if not (opts.cachePath[-1] == '/' or opts.cachePath[-1] == '\\'): cachePath += '/' 

	#load queue
	if not opts.queue:
		toScrape = deque()
		for i in opts.url:
			toScrape.append(i)
	else:
		print('loading queue...')
		toScrape = loadqueue(cachePath)
	
	#load config file
	if opts.config:
		#askForOptions = False
		loadConfig()
		#perform loadConfig every 120 seconds
		configLoader = threading.Thread(target=configLoaderFunc,name='configloader')
	else:
		#load urls to block
		if opts.block:
			block.extend(opts.block)
		
	#command line input --------^
	
	#user input ----------------V
		#ask to allow w3.org urls
		if prmpt('would you like w3.org urls'):
			block.append('w3.org')
			#allowW3 = True
		#ask to truncate the error
		if prmpt('would you like to truncate the error log'):
			errLog = open(cachePath + 'errorlog.log', 'w+')
		else:
			errLog = open(cachePath + 'errorlog.log', 'a+')
	
		errorBeep = prmpt('would you like sound at errors')
	
		newItemBeep = prmpt('would you like sound at new items')
	#user input ----------------^

def main():
	try:
		global errLog, ctrlC, toScrape, scraped, allowW3, cachePath
		
		logFile = 'pythonlog.log'
		phoneLog = 'phonelog.log'
		
	#	_init_()
		while 1:
			if ctrlC: break
			try:
				tmp = toScrape[0]
			except IndexError:
				break
			except TypeError:
				pass
			if tmp:
				print(Back.RED + '?' , Fore.GREEN + tmp[ tmp.find('//') + 2 : 30 ] + Fore.WHITE + '...', end=' ')
				used = grep(tmp , 'scraped.txt' , 'a')
				if used:
					print('\n' + Fore.GREEN + '-------------------- ' +  tmp + '\n')
					scrapeurl(logFile,tmp,cachePath,phoneLog)
				else:
					print(Back.RED + 'X')
				del toScrape[0]
		print('\nDone\n')
	except SyntaxError:
		raise
	except KeyboardInterrupt:
		print('exiting')
		return
	except:
		sndError('global','unknown error')
		raise

	finally:
		if errLog:
			errLog.close()
if __name__ == '__main__':
#	global cachePath, runtime
	init(autoreset=True)
	try:
		_init_()
		main()
	finally:
	#	runtime[1] = time.asctime()
	#	print('start: ' + runtime[0] + '\nstop: ' + runtime[1])
	#	if savequeue(toScrape,cachePath):
	#		print('queue saved')
	#		print('queue dir:' , cachePath)
		exit()
