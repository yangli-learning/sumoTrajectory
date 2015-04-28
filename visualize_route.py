from lxml import etree as ET 
import numpy as np
import matplotlib.pyplot as plt
import pandas as pd
import sys
import os.path

def usage():
    print "Usage: python visualize_route.py <net_file> <flow_file>\n"

def readSumoNetwork(fname):

    roads = {}
    tree = ET.parse(fname)

    for elem in tree.iter(tag='edge'):
        id = elem.attrib['id']
        firstlane = elem.find("lane")
        shape = firstlane.attrib['shape'].split(" ")
        coors =[  x.split(",") for x in shape]
        xcoor = [float(x) for (x,y) in coors]
        ycoor = [float(y) for (x,y) in coors]
        roads[id] =  (xcoor,ycoor)            
    return roads

def readRouteFile(fname):
    routes={}
    tree = ET.parse(fname)
    for elem in tree.iter(tag='vehicle'):
        id = elem.attrib['id']
        (route,repno) = id.split(".")
        if (route not in  routes  ):
            routes[route] = elem.find("route").attrib['edges'].split()
            
    return routes

def plotRoutes(roads, routes):
    plt.figure(1)
    for r,edgeids in routes.iteritems():
        
        xs = sum([ roads[e][0] for e in edgeids],[])
        ys  = sum([ roads[e][1] for e in edgeids],[])

        plt.plot(xs, ys)
    plt.show()

def plotRoutesGrid(roads, routes):
    plt.figure(2)
    n = len(routes)
    h = np.sqrt(n)
    w = np.ceil(n/h)
    i=0
    ax = plt.subplot(h, w, 0, aspect='equal')
    for r,edgeids in routes.iteritems():
        if (i!= 0) : 
            a = plt.subplot(h, w, i)
            a.set_title("Route %s\n%s,%s" % (r,edgeids[0], edgeids[-1]))
            plt.setp(a.get_xticklabels() , visible=False)
            plt.setp(a.get_yticklabels() , visible=False)
        else:
            ax.set_title("Route %s\n%s,%s" % (r,edgeids[0], edgeids[-1]))
            plt.setp(ax.get_xticklabels() , visible=False)
            plt.setp(ax.get_yticklabels() , visible=False)

        xs = sum([ roads[e][0] for e in edgeids],[])
        ys  = sum([ roads[e][1] for e in edgeids],[])
        plt.plot(xs, ys)
        if (i !=0):
            plt.ylim( ax.get_ylim() )        # set y-limit to match first axis

        i+=1
    plt.show()
def main():
    if (len(sys.argv) >2):
        net_fname = sys.argv[1]
        route_fname = sys.argv[2]
    else:
        usage()
        exit(0)

    routes = readRouteFile(route_fname)
    roads = readSumoNetwork(net_fname)
    #print roads[:5]
    plotRoutes(roads,routes)
    plotRoutesGrid(roads,routes)

if __name__ == "__main__":
        main()
