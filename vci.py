#!/bin/python
# Author: Wesley Tanner
# 2014-5-28

from __future__ import print_function
from sklearn import svm
from scipy.io.wavfile import read
import os
import sys
import numpy
import getopt
import cPickle as pickle

def usage():
    """Print the usage information to stderr"""
    print('usage: train.py -t -i [file] -o [file] -p [file]', file=sys.stderr)

def preprocess(data):
    return data / numpy.max(data)

def save_classifier(clf, audio_len, cat_map, filename):
    save_dict = (clf, audio_len, cat_map)
    pickle.dump(save_dict, open(filename, "wb"))

def load_classifier(filename):
    clf, audio_len, cat_map = pickle.load(open(filename, "rb"))
    return clf, audio_len, cat_map

def get_wav_file_length(filename):
    """Return the length, in samples, of the input wav file."""
    try:
        _, data = read(filename)
    except IOError as err:
        print(str(err))
        exit(1)
    return(len(data))

def get_training_vector_info(path):
    """Recursively reads all files in path, and returns total number of files. All files should be the same length"""

    num_files = 0

    for _,_, files in os.walk(path):
        num_files += len(files)
    return num_files

def load_dataset(path, audio_len):
    """Reads in the output of the gen_training.m Octave script, and returns a triplet to feed the libsvm classifier."""
    num_vecs = get_training_vector_info(path)

    cat_map = {}
    cat_index = 0
    vec_index = 0
    x = numpy.zeros([num_vecs, audio_len])
    y = numpy.zeros(num_vecs)

    for root, dirs, files in os.walk(path):
        # initialize a numpy array
        for cat in dirs:
            cat_map[cat_index] = cat

            # category is encoded as the directory name
            for data_file in os.listdir(root + cat):
                try:
                    rate, data = read(root+cat+'/'+data_file)
                except IOError as err:
                    print(str(err))
                    exit(1)

                # scale the data between -1 and 1 and save
                x[vec_index,:] = preprocess(data)
                y[vec_index] = cat_index
                vec_index += 1

            cat_index += 1
    return x,y,cat_map

def main(argv):
    # default behavior is to predict
    save_classifier_flag = False
    train_flag = False
    predict_flag = False
    input_file_flag = False

    try:
        opts, args = getopt.getopt(argv, "ti:o:p:")
    except getopt.GetoptError as err:
        print(str(err))
        usage()
        sys.exit(1)

    for o, a in opts:
        if o == "-i":
            input_file_flag = True
            input_filename = a
        elif o == "-o":
            save_classifier_flag = True
            clf_filename = a
        elif o == "-t":
            train_flag = True
        elif o == "-p":
            predict_flag = True
            predict_filename = a
        else:
            assert False, "unhandled option"

    # check for sane argument combinations
    if train_flag and predict_flag:
        print('error: training mode and prediction mode both specified.', file=sys.stderr)
        usage()
        exit(1)
    elif train_flag and not input_file_flag:
        print('error: training mode specified without an input wav file.', file=sys.stderr)
        usage()
        exit(1)
    elif not input_file_flag:
        print('error: prediction mode specified without an input classifier file.', file=sys.stderr)
        usage()
        exit(1)
    elif save_classifier_flag and not train_flag:
        print('error: classifier output file specified without training mode enabled.', file=sys.stderr)
        usage()
        exit(1)

    if(train_flag):
        audio_len = get_wav_file_length(input_filename)

        # the datasets are in ./training/ and ./test/
        x_training, y_training, training_cats = load_dataset('./training/', audio_len)

        print('categories:', file=sys.stderr)
        for value in training_cats.values():
            print(value)

        print('\nstarting SVM model fit...')

        clf = svm.LinearSVC()
        clf.fit(x_training, y_training)

        # test the classifier
        x_test, y_test, test_cats = load_dataset('./test/', audio_len)
        print('\ntest dataset accuracy score: ' + str(clf.score(x_test, y_test))+'\n')

        if(save_classifier_flag):
            save_classifier(clf, audio_len, test_cats, clf_filename)
    elif(predict_flag):
        # we are in prediction mode. Use the classifier specified in the input file
        clf, audio_len, training_cats = load_classifier(input_filename)

        # check to make sure the input prediction file has the same number of samples as the classifier.
        _, data = read(predict_filename)
        if(audio_len != len(data)):
            print('error: prediction wav file must have the same length as the classifier.', file=sys.stderr)
            exit(1)
        else:
            data = preprocess(data)
            prediction = clf.predict(data)
            print(training_cats[prediction[0]])

if __name__ == "__main__":
    main(sys.argv[1:])
