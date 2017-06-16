#!/usr/bin/env python
# call with :
#	notInFile.py search/insert_text searchFileName add/noAdd(a|na)
import sys
#from collections import Counter
from subprocess import Popen , PIPE

def grep(needle, filename ,add):
	tmp = Popen(['grep','-x',needle,filename],stdout=PIPE).communicate()
	#print(tmp , str(tmp[0]))
	if not tmp[0]:
		if add == 'a':
			file = open(filename , 'a')
			file.write(needle + '\n')
			file.close()
	#		print(1)
	#	elif add == 'na':
	#		add = add
	#		print(1)
	#	sys.exit(1)
		return True
	else:
	#	print(0)
	#	sys.exit(0)
		return False


#def check3(haystack, needle):
 #
  #  if needle  in haystack:
   #     return 1

    #words = haystack.lower().split()

    #if needle in words:
    #    return 10

    #for word in words:
    #    if word.startswith(needle):
    #        return 10 ** (len(needle) / len(word))



#def check2(searchText,fileName,addNoAdd):
#	file = open(fileName)
#	lines = (l[:-1] for l in file)
#	if searchText in lines:#Counter(lines)[searchText]:
#		print(0)
#		sys.exit(0)
#	else:
#		if addNoAdd == 'a':
#			file.write(sys.argv[1] + '\n')
#			file.close()
#			print(1)
#		elif addNoAdd == 'na':
#			file.close()
#			print(1)
#		sys.exit(1)
#	file.close()

#def check(searchText,fileName,addNoAdd):
#	file = open(fileName,'a')
#	rFile = open(fileName,'r')
#
#	for line in rFile:
#		# print('-')
#		if searchText in line:
#			print(0)
#			sys.exit(0)
#
#	if addNoAdd == 'a':
#		file.write(sys.argv[1] + '\n')
#		file.close()
#		print(1)
#		sys.exit(1)
#	elif addNoAdd == 'na':
#		file.close()
#		print(1)
#		sys.exit(1)
#	file.close()
#	rfile.close()
#	
#def search(needle,haystackFileName,add):
	#text = needle.lower()
#	file = open(haystackFileName)
#	lines = [1 for x in file if needle in x]
#	if lines[0]:
#		if add == 'a':
#			file.write(sys.argv[1] + '\n')
#			file.close()
#			print(1)
#		elif add == 'na':
#			file.close()
#			print(1)
#		sys.exit(1)
#	else:
#		print(0)
#		sys.exit(0)
	#return bool(lines)[x[1] for x in sorted(lines, reverse = True)[:15]]
	
	
if __name__ == '__main__':
	#check(sys.argv[1],sys.argv[2],sys.argv[3])
	#check2(sys.argv[1],sys.argv[2],sys.argv[3])
	#search(sys.argv[1],sys.argv[2],sys.argv[3])
	grep(sys.argv[1],sys.argv[2],sys.argv[3])	
