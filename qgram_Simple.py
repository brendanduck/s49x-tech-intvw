"""
qgram_simple.
A simple name-matching implementation of a qgram string distance function.
Input: File containing two names on each row 
Ouput: The two names and a score out of 100. !00 = match
"""

import csv

qGramSize = 2
output_file = open('qgramOutput.csv','w')

def score_names(fname_a, gname_a, fname_b, gname_b):
    global qGramSize
    first_set = []
    second_set = []
    qgrams = []
    first_qgrams = []
    second_qgrams = []
    first_score = 0
    second_score = 0

    first_set.append(fname_a)
    first_set.append(gname_a)
    second_set.append(fname_b)
    second_set.append(gname_b)

    for x in first_set:
        st = [x[i:i+qGramSize] for i in xrange(0, len(x), 1)]
        qgrams = qgrams + st
        first_qgrams = first_qgrams + st

    for x in second_set:
        st = [x[i:i+qGramSize] for i in xrange(0, len(x), 1)]
        qgrams = qgrams + st
        second_qgrams = second_qgrams + st

    qgrams = list(set(qgrams))
    first_qgrams = list(set(first_qgrams))
    second_qgrams = list(set(second_qgrams))

    # compare first name
    first_score = len(set(qgrams).intersection(first_qgrams))
    # compare second name
    second_score = len(set(qgrams).intersection(second_qgrams))

    return ((first_score + second_score) / (len(qgrams) * 2.0)) * 100

with open('test_names.txt') as csvfile:
     name_reader = csv.reader(csvfile, delimiter='|')
     for row in name_reader:
        output_file.write(row[0] + ' ' + row[1] + ',' + row[2] + ' ' + row[3] + ',%1.2f\n' %(score_names(row[0],row[1],row[2],row[3])))
       
print('Results have been saved as qgramOutput.csv')


