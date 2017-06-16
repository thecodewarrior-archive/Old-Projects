#!/usr/bin/env python3.2

from __future__ import print_function
from notInFile import grep
import sys, re, traceback, urllib
from colorama import init, Fore, Back, Style
from subprocess import call
from urllib.request import urlopen, urlretrieve
from urllib.parse import urlparse
from collections import deque

#error log file
errLog = None
#to Scrape queue
toScrape = None
#scraped urls file
scraped = open('scraped.txt','a+')

def writeError(excInfo , url , description):
	global errLog
	_type,_value,_traceback = excInfo
	error = repr(traceback.format_exception(_type,_value,_traceback))
	writerr = url + '\n' + description
	writerr += error.join('')
	errLog.write(writerr + '\n\n') 


#send error sound
def errsnd():
	#no sound for linux
	return

#make sure url does not contain javascript: or mailto:
def validLink(url):
	arr = ['mailto:' , 'javascript:']
	for a in arr:
		if a in url.lower():
			return 0
	return 1

#complete url as relatave etc.
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

#scrape url for emails and phone numbers
def scrapeurl(logFile , url,cachePath,phoneLog):
	#queue	
	global toScrape
	
	#email log
	log = open(logFile , 'a+')
	#phone number log
	numLog = open(phoneLog, 'a+')
	
	#try to retrieve url into cache
	try:
		cacheLog = urlretrieve(url, cachePath +'cache.txt')[0]
	except KeyboardInterrupt:
		raise
	except:
		errsnd()
		print(Back.RED + 'unable to retrieve:' , url)
		return
	#open cache	
	cache = open(cacheLog, 'rU')
	i = 1
	print('links:')
	try:
		for line in cache:
			#find all emails in line i			
			matches = re.findall('[\w.-]+@[\w.-]+\.\w{2,3}',line)
			
			#loop over emails			
			for match in matches:
				#print ? email@email.email
				print(Back.RED + Style.BRIGHT + '?' , Back.BLUE + Style.BRIGHT + match , end='\r')
				#check if email has alredy been logged
				if grep(match , logFile , 'a'):
					print(Back.BLUE + Style.BRIGHT + match + '\a')
				else:
					print(Back.RED + 'X')
			#delete emails var
			del matches
			
			#find all 'a' html tags and retrieve there href attributes 
			links = re.findall('<a\\s+?.*?href=["\'](.+?)["\'].*?>',line)
			#find all full valid urls
			links.extend(re.findall('https?://[\\w.-]+?\\.\\w{2,3}/?[\\w/]+\\.?\\w*\\??[^"\'\\s]*?',line))
			#loop over links
			for link in links:
				#complete relitave links
				link = completeUrl(link,url)
				#avoid empty links
				if link:
					#if link is not alredy in queue, add to queue
					try:
						if not link in toScrape:
							toScrape.append(link)
					except TypeError:
						print('')
					print(link , '--line ' , i)
			#delete links array
			del links
			#find all phone numbers
			nums = re.findall(r'[(]*\d\d\d[) .-]\d\d\d[ .-]\d\d\d\d',line)
			#loop over phone numbers
			for num in nums:
				#print ? 111-111-1111
				print(Back.RED + Style.BRIGHT + '?' , Back.GREEN + Style.BRIGHT + num,end='\r')
				#check if phone number has alredy been logged
				if grep(num , phoneLog , 'a'):
					print('\n' + Back.GREEN + Style.BRIGHT + num + '\a')
				else:
					print(Back.RED + 'X')
			#delete phone number array
			del nums
			i+=1
	except SyntaxError:
		raise
	except (UnicodeDecodeError,UnicodeEncodeError):
		print(Back.RED + 'unknown character(s) in line ' , i)
		errsnd()
		pass
	except KeyboardInterrupt:
		print('^C')
		raise

	cache.close()
	del cache

def savequeue(queue,path):
	#check if queue is empty	
	if queue:
		print('saving queue...')
		#open queue file
		file = open(path + 'queue.txt','w+')
		#loop over all items in queue
		for item in queue:
			try:
				file.write(item + '\n')
			except TypeError:
				pass

def loadqueue(path):
	
	file = open(path + 'queue.txt','r')
	queue = deque()
	for line in file:
		queue.append(line[:-1])
	return queue
	
def main():
	try:
		#path to the cache
		cachePath = sys.argv[2]
		global errLog
		global toScrape
		global scraped
		#check if 1st arg == 'q'
		if not sys.argv[1] == 'q':
			toScrape = deque([sys.argv[1]])
		else:
			print('loading queue...')
			toScrape = loadqueue(sys.argv[2])
		logFile = 'pythonlog.log'
		phoneLog = 'phonelog.log'
		errLog = open(cachePath + 'errorlog.log' , 'w+')
		while 1:
			
			try:
				tmp = toScrape[0]
			except IndexError:				
				print(1)
				break
			except TypeError:
				writeErr(sys.exc_info())
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
	except SyntaxError:
		raise
	except KeyboardInterrupt:
		print('exiting')
		return
if __name__ == '__main__':
	init(autoreset=True)

	try:
		main()
	finally:
		savequeue(toScrape,sys.argv[2])
		print('queue saved')
		print('queue dir:' , sys.argv[2])
