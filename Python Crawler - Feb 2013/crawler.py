#!/usr/bin/env python3.2

from __future__ import print_function
from notInFile import grep
import sys
import traceback
import re
import urllib
import argparse
import time
import threading
from colorama import init, Fore, Back, Style
from subprocess import call, Popen, PIPE
from urllib.request import urlopen
from urllib.request import urlretrieve
from urllib.parse import urlparse
from collections import deque
from smtplib import SMTP
import email.utils
import getpass


loaderrorsMax = 10
loaderrors = 0
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
verbose = True
newEmails = 0
newPhones = 0
emailSend = False
emailPassword = ''
quitErr = '---NO ERROR---'


def sendEmail(subject, message):
	global emailSend, emailPassword
	if emailSend:
		debuglevel = 0

		smtp = SMTP()
		smtp.set_debuglevel(debuglevel)
		smtp.connect('smtpout.secureserver.net', 80)
		smtp.login('pierce@plasticcow.com', emailPassword)

		from_addr = "Python Crawler <pyCrawl@nonexistant.com>"
		to_addr = "pierce@plasticcow.com"

		date = email.utils.formatdate()

		msg = "From: %s\nTo: %s\nSubject: %s\nDate: %s\n\n%s" % ( from_addr, to_addr, subject, date, message )

		smtp.sendmail(from_addr, to_addr, msg)
		smtp.quit()
	
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
	global newItemBeep, newEmails, newPhones
	if newItemBeep:
		if itemType == 'phone':
			file = 'Ding.wav' # ring (annoying and grainy) => 'phone.wav'
			newPhones += 1
		else:
			file = 'email.wav'
			newEmails += 1
		play = Popen(['play',file],stdout=PIPE,stderr=PIPE)
		del play

def checkRobotsTxt(url):
	global robotsTxtBlock, robotsTxtOk
	ok = open('robotsOk.txt','a')
	bad = open('robotsBad.txt','a')
	try:
		robotsTxt = urlopen(url).read()
	except:
		ok.write(url + '\n')
		robotsTxtOk.append(url)
		return 1
	try:
		z = re.search(r'(?<=User-agent: \*\s)(:?.+\s)+',robo).group(0)
	except AttributeError:
		ok.write(url + '\n')
		robotsTxtOk.append(url)
		return 1
	a = re.findall(r'(?<=Disallow: ).*',z)
	if not a[0]:
		ok.write(url + '\n')
		robotsTxtOk.append(url)
		return 1
	else:
		for i in a:
			urlPath = url + i
			bad.write(urlPath + '\n')
			robotsTxtBLock.append(urlPath)
	bad.close()
	ok.close()

def validateURL(url):
	global allowW3, block, robotsTxtBlock, robotsTxtOk
	
	parsed = urlparse(url)
	if parsed.scheme == 'http':
		url = url[7:]
	elif parsed.scheme == 'https':
		url = url[8:]
		
	if not allowW3:
		if 'w3.org' in url.lower():
			return 0

	if not grep(url , 'robotsBad.txt',wholeLine=0):
		return 0
	elif not grep(url, 'robotsOk.txt',whileLine=0):
		return 1


	#for i in robotsTxtBlock:
		#if url.lower().startswith(i):
			#return 0

	#for i in robotsTxtOk:
		#if url.lower().startswith(i):
			#return 1

	checkRobotsTxt(parsed.scheme + '://' + parsed.netloc)

def validLink(url):
	global allowW3, block, robotsTxtBlock
	arr = ['mailto:' , 'javascript:']
	
	tmpBlock = block
	arr = arr + robotsTxtBlock
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
	global loaderrors
	global verbose
	global newEmails, newPhones	

	vbose = verbose
	
	log = open(logFile , 'a+')
	numLog = open(phoneLog, 'a+')
	try:
		if vbose: print('loading ' + url + '...')
		cacheLog = urlretrieve(url, cachePath +'cache.txt')[0]
	except KeyboardInterrupt:
		raise
	except:
		errsound()
		sndError(url,'loading url into cache')
		if vbose:
			print('\n' + Back.RED + 'unable to retrieve:' , url)
		else:
			print(Back.RED + 'Load Error')
		loaderrors += 1
		return
	loaderrors = 0
	file = open(cacheLog, 'rU')
	i = 1
	if vbose: print('links:')
	if not vbose: print('\n')
	try:
		for line in file:
			
			try:
				matches = re.findall('[\w.-]+@[\w.-]+\.\w{2,3}',line)
				
				for match in matches:
					print(Back.RED + Style.BRIGHT + '?' , Back.BLUE + Style.BRIGHT + match , end='\r')
					if grep(match , logFile , 'a'):
						print(Back.BLUE + Style.BRIGHT + match, ' ')
						newItem('mail')
					else:
						print(Back.YELLOW + Fore.RED + 'X ' + Fore.BLUE + match)
			except KeyboardInterrupt:
				print('^C quitting after this web page...')
				ctrlC = True
				
				
			del matches
			
			try:
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
						except KeyboardInterrupt:
							print('^C quitting after this web page...')
							ctrlC = True
						if vbose: print(link , '--line ' , i)
			except KeyboardInterrupt:
				print('^C quitting after this web page...')
				ctrlC = True
				
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
	file.close()
	del file

def savequeue():
	global toScrape, cachePath
	if toScrape:
		if prompt('\rwould you like to save the queue'):
			print('saving queue...')
			file = open(cachePath + 'queue.txt','w+')
			for item in toScrape:
				try:
					file.write(item + '\n')
				except TypeError:
					pass
			return True
		else: 
			return True
	return False

def loadqueue(path):
	file = open(path + 'queue.txt','r')
	queue = deque()
	for line in file:
		queue.append(line[:-1])
	return queue

def exit():
	global toScrape, runtime, cachePath, newEmails, newPhones, quitErr
	runtime.append(time.asctime())
	print('start: ' + runtime[0] + '\nstop: ' + runtime[1])
	print('new emails collected this session: ' + str(newEmails))
	print('new phone numbers collected this session: ' + str(newPhones))
	quitmessage = 'crawler quit. \n' + 'start: ' + runtime[0] + '\nstop: ' + runtime[1] + '\n\n new emails collected this session: ' + str(newEmails) + '\nnew phone numbers collected this session: ' + str(newPhones) + '\n\n' + quitErr
	sendEmail('crawler quit', quitmessage )
	while True:
		saveresult = savequeue()
		if saveresult:
			print('queue saved\nqueue dir: ' + cachePath)
			break
		else:
			if not prompt('queue save was not successful would you like to retry?'):
				break

def prompt(message):
	for i in range(0,10):
		try:
			if input(message + ' [y/n]? ').lower() == 'y':
				return True
			return False
		except EOFError:
			print('try again, press Ctrl+C to force yes')
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


def loadConfig(noerrlog=False):
	global errorBeep, newItemBeep, allowW3, cachePath, block, errLog, verbose
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
		elif itm[0] == 'verbose':
			if itm[1] == 'False':
				verbose = False
			else:
				verbose = True
		elif itm[0] == 'email':
			if itm[1] == 'True':
				emailSend = True
			else:
				emailSend = False

def _init_(): 
	global errorBeep, newItemBeep, allowW3, errLog, errorURL, toScrape, scraped
	global ctrlC, cachePath, runtime, opts, block, verbose, emailSend, emailPassword
	runtime.append(time.asctime())
	print(runtime[0])
	
	#askForOptions = True

	#parse arcuments
	parser = argparse.ArgumentParser(description='crawl the web')
	parser.add_argument('-q', '--queue'  , dest='queue'     , action='store_true',            help='if present, load queue from file'                    )
	parser.add_argument('-c', '--config' , dest='config'    , action='store_true',            help='if present, load config from file'                   ) 
	parser.add_argument('-e', '--email'   , dest='email' , action='store_true'     ,            help='if present, send email notification for major events' )
	parser.add_argument('-b', '--block'  , dest='block'     , action='append'    ,            help='block url'                                           ) 
	parser.add_argument('-u', '--url'    , dest='url'       , action='append'    ,            help='urls to search'                                      )
	parser.add_argument('-p', '--path'   , dest='cachePath' , action='store'     ,            help='path to config.ini, queue.txt and cache.txt'         )
	parser.add_argument('-v', '--verbose', dest='verbose'   , action='store_true',            help='' )
	opts = parser.parse_args()

	#command line input --------V
	
	#load cache path
	cachePath = opts.cachePath
	if not (opts.cachePath[-1] == '/' or opts.cachePath[-1] == '\\'): cachePath += '/' 

	#set email vars
	emailSend = opts.email
	
	if emailSend: emailPassword = getpass.getpass('please type smtp password for pierce@plasticcow.com: ')
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
		if prompt('would you like to block w3.org urls'):
			block.append('w3.org')
			#allowW3 = True
		#ask to truncate the error
		if prompt('would you like to truncate the error log'):
			errLog = open(cachePath + 'errorlog.log', 'w+')
		else:
			errLog = open(cachePath + 'errorlog.log', 'a+')
	
		errorBeep = prompt('would you like sound at errors')
	
		newItemBeep = prompt('would you like sound at new items')
		
		verbose = prompt('would you like to run in verbose mode')
	#user input ----------------^

def main():
	try:
		global errLog, ctrlC, toScrape, scraped, allowW3, cachePath, loaderrors
		global verbose, runtime, quitErr
		
		sendEmail('started Crawling ' + toScrape[0][:45], 'started crawling the web begining at the url: \n    ' + toScrape[0] + '\n on: ' + runtime[0])
		
		logFile = 'pythonlog.log'
		phoneLog = 'phonelog.log'
		
	#	_init_()
		while 1:
			if ctrlC: break
			if loaderrors > loaderrorsMax: 
				try:
					print('to many load errors. Quitting if you press cntrl-C within 3 seconds')
					time.sleep(3)
					loaderrors = 0
				except KeyboardInterrupt:
					quitErr = 'Too many load errors'
					break
			if ctrlC:
				print('I told you i would quit after that web page so i will. >sigh< I was having so much fun too...')
				quitErr = 'manualy quit'
			try:
				url = toScrape[0]
			except IndexError:
				print('reached end of queue (I don\'t know how that happend without tripping to many load errors) ;. Quitting')
				break
			except TypeError:
				pass
			if url:
				print(Back.BLUE + '?' , Fore.GREEN + url[ url.find('//') + 2 : 30 ] + Fore.WHITE + '...', end=' ')
				used = grep(url , 'scraped.txt' , 'a')
				valid = validateURL(url)
				if used and valid:
					if verbose:
						print('\n' + Fore.GREEN + '-------------------- ' +  url + '\n')
					#else:
					#	print('\n')
					scrapeurl(logFile,url,cachePath,phoneLog)
				else:
					print(Back.RED + 'X')
				del toScrape[0]
		print('\nDone\n')
		#print(10/0)
	except SyntaxError:
		raise
	except KeyboardInterrupt:
		print('exiting')
		quitErr = 'manualy quit'
		return
	except:
		quitErr = ''.join(traceback.format_exception(sys.exc_info()[0], sys.exc_info()[1], sys.exc_info()[2])) 

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
