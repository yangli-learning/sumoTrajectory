Trajectory generation using SUMO
================================


### Content ###

Directories
- `osm/`: open street map files 
- `networks/`: converted sumo network files
- `simple_networks/`: grid and spider networks and simulation files
- `beijing_random_trips/`: simulation data using random trips on beijing maps
- `junction_flows/`: simulation data using manually defiend flows on real maps

Files
- `run_interactive.sh`: interactive Bash script for trajectory generation 
- `csv2Route.py`: convert csv flow file to sumo flow xml file
- `visualize_route.py`: visualize SUMO generated routes 
- `settings.xml`: common setting file for all sumo simulation

----------
### Traffic flow csv format ###

Each line in a flow.csv file defines a flow. The columns are:

     [From name], [To name], [From edge/lane], [To edge/lane], [path]

Note:
- `[From name]` and `[To name]` are optional human readable tags that 
doesn't affect parsing
- `[path]` is an optional list of intermediate edges/lanes used to restrict the route. Edge or lane ids are separated by space.
- Should not contain column headers



