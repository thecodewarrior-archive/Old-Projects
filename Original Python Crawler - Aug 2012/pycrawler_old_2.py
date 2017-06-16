#!/usr/bin/env python3.2

from __future__ import print_function
from notInFile import grep
import sys, traceback
from colorama import init, Fore, Back, Style
from subprocess import call
import re
from urllib.request import urlopen
from urllib.request import urlretrieve
from urllib.parse import urlparse
import urllib
from collections import deque
##import winsound
#from colorama import init , Fore , Back , Style


errLog = None
errorURL = None
toScrape = None
scraped = open('scraped.txt','a+')
ctrlC = False

def errsnd():
	return
#	audio=file('/dev/audio', 'wb')
#
#	count=0
#
#	while count<250:
#
#		beep=chr(63)+chr(63)+chr(63)+chr(63)
#
#		audio.write(beep)
#
#		beep=chr(0)+chr(0)+chr(0)+chr(0)
#
#		audio.write(beep)
#
#		count=count+1
#
#	audio.close()
#	winsound.PlaySound('SystemQuestion',winsound.SND_ASYNC)
	
def validLink(url):
	arr = ['mailto:' , 'javascript:']
	for a in arr:
		if a in url.lower():
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
			#print(parsed.path , tmp)
			retrn = parsed.scheme + '://' + parsed.netloc + tmp + link
		elif link[0:3] == '../':
			tmp = parsed.path[:parsed.path.rfind('/')]
			tmp = tmp[:tmp.rfind('/') + 1]
			retrn = parsed.scheme + '://' + parsed.netloc + tmp + link[3:]
		return retrn

def scrapeurl(logFile , url,cachePath,phoneLog):
	global ctrlC
	global toScrape
	#if not urlValid(url):
	#	return
	#if url[-1:] != "/" and url.find('/') != url.rfind('/') -1:
		#url = url + "/"
	#done = []
	#logR = open(logFile , 'r')
	#for line in logR:
		#done.append(line.replace('\n',''))
	#logR.close()
	
	log = open(logFile , 'a+')
	numLog = open(phoneLog, 'a+')
	
	try:
		cacheLog = urlretrieve(url, cachePath +'cache.txt')[0]
	
	except KeyboardInterrupt:
		raise
	except: #(ValueError,WindowsError,IOError):
		errsnd()
		print(Back.RED + 'unable to retrieve:' , url)
		return
	file = open(cacheLog, 'rU')
	i = 1
	print('links:')
	try:
		for line in file:
			#print(line)
			#line = line
			
			matches = re.findall('[\w.-]+@[\w.-]+\.\w{2,3}',line)
			#print(matches)
			
			for match in matches:
				print(Back.RED + Style.BRIGHT + '?' , Back.BLUE + Style.BRIGHT + match , end='\r')
				if grep(match , logFile , 'a'):#notInFile.check(match,logFile,'a'): #not match in log.read():
					#done.append(match)
					#print(match)
					#log.write(match + ' \n')
#					log.write(match + '\n')
					print(Back.BLUE + Style.BRIGHT + match + '\a')
				else:
					print(Back.RED + 'X')
#					winsound.PlaySound('SystemExclamation',winsound.SND_ASYNC)
				
			del matches

			links = re.findall('<a\\s+?.*?href=["\'](.+?)["\'].*?>',line)
			links.extend(re.findall('https?://[\\w.-]+?\\.\\w{2,3}/?[\\w/]+\\.?\\w*\\??[^"\'\\s]*?',line))

			for link in links:
				link = completeUrl(link,url)
				if link:
					try:
						if not link in toScrape:# or link in scraped.read():#toScrape.read():
							toScrape.append(link)#.write(link + '\n')
					except TypeError:
						print('')
					print(link , '--line ' , i)
			del links
			nums = re.findall(r'[(]*\d\d\d[) .-]\d\d\d[ .-]\d\d\d\d',line)
			#links = [x.group(1) for x in links]
			#links.extend(re.findall('https?://[\\w.-]+?\\.\\w{2,3}/?[\\w/]+\\.?\\w*\\??[^"\'\\s]*?',line))
			#if len(links) or i == 109:
			#	print(len(links))
			for num in nums:
				#link = completeUrl(link,url)
				#if not link in toScrape or link in scraped:#toScrape.read():
				#	toScrape.append(link)#.write(link + '\n')
				#phoneLog.write(num + '\n')
				print(Back.RED + Style.BRIGHT + '?' , Back.GREEN + Style.BRIGHT + num,end=' ')
				if grep(num , phoneLog , 'a'):#notInFile.check(num,phoneLog,'a'):#not num in numLog.read():
#					numLog.write(num + ' \n')
					print('\n' + Back.GREEN + Style.BRIGHT + num + '\a')
				else:
					print(Back.RED + 'X')
#					winsound.PlaySound('SystemExclamation',winsound.SND_ASYNC)
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
		ctrlC = True
		raise
	#log.close()
	file.close()
	del file # , log

def savequeue(queue,path):
	if queue:
		print('saving queue...')
		file = open(path + 'queue.txt','w+')
		for item in queue:
			try:
				file.write(item + '\n')
			except TypeError:
				pass

def loadqueue(path):
	#print('loading queue...')
	file = open(path + 'queue.txt','r')
	queue = deque()
	for line in file:
		queue.append(line[:-1])
#	winsound.PlaySound('SystemHand' , winsound.SND_ASYNC)
	return queue
	
def main():
	try:
		cachePath = sys.argv[2]
		global errLog
		global ctrlC
		global toScrape
		global scraped
		if not sys.argv[1] == 'q':
			toScrape = deque([sys.argv[1]])
		else:
			print('loading queue...')
			toScrape = loadqueue(sys.argv[2])
		logFile = 'pythonlog.log'
		phoneLog = 'phonelog.log'
		errLog = open(cachePath + 'errorlog.log')
		#global toScrapeR
		#toScrape.append(sys.argv[1])#.write(sys.argv[1] + '\n')
		#for url in toScrape:
		#for tmp in toScrape:
		while 1:
			if ctrlC:
				break
			try:
				tmp = toScrape[0]#.popleft()
				#scraped.write(tmp + '\n')
			except IndexError:
				break
			except TypeError:
				pass
			if tmp:
				print(Back.RED + '?' , Fore.GREEN + tmp[ tmp.find('//') + 2 : 30 ] + Fore.WHITE + '...', end=' ')
				used = grep(tmp , 'scraped.txt' , 'a')
				#print(used)
				if used:#notInFile.check(tmp,'scraped.txt','a'):#
					print('\n' + Fore.GREEN + '-------------------- ' +  tmp + '\n')
					#try:
					#scraped.write(tmp + '\n')
					scrapeurl(logFile,tmp,cachePath,phoneLog)
				#	scraped.write(tmp + '\n')
	
					#except:
					#	print('---------unknown error----------')
					#	pass
				else:
					print(Back.RED + 'X')
				del toScrape[0]
		#logR = open(logFile,'r')
		print('\nDone\n')
		#for line in logR:
		#	print(line, end='')
		#logR.close()
	except SyntaxError:
		raise
	except KeyboardInterrupt:
		print('exiting')
#		winsound.PlaySound('SystemHand' , winsound.SND_ASYNC)
		return
if __name__ == '__main__':
	init(autoreset=True)

	try:
		main()
	finally:
		savequeue(toScrape,sys.argv[2])
		print('queue saved')
		print('queue dir:' , sys.argv[2])
#		winsound.PlaySound('SystemHand' , winsound.SND_ASYNC)
