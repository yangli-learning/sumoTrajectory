from lxml import etree as ET 
import numpy as np
import matplotlib.pyplot as plt
import pandas as pd
import sys
import os.path


def usage():
    print "Usage: python csv2Route.py <csv_file> \n"

def cvt(x):
    return (x[:x.rfind("_")] if x.rfind("_")!=-1 else x).strip()

def parsePathData(x):
    if (x==x):
        x = x.split()
        return [ cvt(r) for r in x]
    else:
        return []

def main():    
    if (len(sys.argv) >1):
        csv_fname = sys.argv[1]
        print "read csv file", csv_fname
        basename =  os.path.splitext(csv_fname)[0]
        flow_fname = "%s.xml" % basename 
    else:
        usage()
        exit(0)


    data = pd.read_csv(csv_fname, header=None )
    data[2] = data[2].apply(lambda x: (x[:x.rfind("_")] if \
                                   x.rfind("_")!=-1 else x).strip())
    data[3] = data[3].apply(lambda x: (x[:x.rfind("_")] if \
                                   x.rfind("_")!=-1 else x).strip())
    data[4] = data[4].apply(parsePathData)


    # write to xml flow file
    flows = ET.Element("flows")

    iter = data.iterrows()
    last = iter.next()

    for i,row in iter:
        flow =ET.SubElement(flows, "flow" , id=str(i),\
                            begin="0", end="3600", number="50")
        flow.set('from',row[2])
        flow.set('to',row[3])
        if (len(row[4])>0):       
            flow.set('via'," ".join(row[4]))
    tree = ET.ElementTree(flows)
    tree.write(flow_fname, pretty_print=True )

    print "completed wroting flows to ", flow_fname

if __name__=="__main__":
    main()

